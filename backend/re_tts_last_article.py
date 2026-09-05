import sys
import os
import re
import uuid
from datetime import datetime

# Ensure the backend directory is in the Python path
sys.path.insert(0, os.path.abspath(os.path.dirname(__file__)))

from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from app.core.config import settings
from app.db.models import Article, UploadedAsset

def re_tts_last_article():
    db_url = settings.DATABASE_URL
    print("=== Re-TTS Dynamic Processing Magic ===")
    print(f"Connecting to remote database...")
    
    engine = create_engine(db_url)
    Session = sessionmaker(bind=engine)
    db = Session()
    
    try:
        # 1. Fetch the most recently created article
        last_article = db.query(Article).order_by(Article.created_at.desc()).first()
        if not last_article:
            print("[Error] No articles found in the remote database to re-process.")
            return
            
        print(f"\n[Found Target] ID: {last_article.id}")
        print(f"  Title: {last_article.title}")
        print(f"  Old Audio S3 Key/URL: {last_article.audio_s3_key}")
        
        # 2. Extract and sanitize text for TTS
        raw_body = last_article.body
        print("\n[Cleaning Text] Stripping HTML tags, links, and formatting...")
        clean_text = re.sub(r'https?://\S+|www\.\S+', '', raw_body)  # Remove links/URLs
        clean_text = re.sub(r'<[^>]+>', '', clean_text)              # Remove HTML tags
        clean_text = re.sub(r'\s+', ' ', clean_text).strip()          # Consolidate whitespace
        
        trimmed_text = clean_text[:3000]
        print(f"  Sanitized Text (First 150 chars): {trimmed_text[:150]}...")
        
        # 3. Google Cloud Text-To-Speech Synthesis (Synchronous)
        print("\n[GCP TTS] Triggering Synchronous Speech Synthesis...")
        from google.cloud import texttospeech_v1 as texttospeech
        tts_client = texttospeech.TextToSpeechClient()
        
        synthesis_input = texttospeech.SynthesisInput(text=trimmed_text)
        voice = texttospeech.VoiceSelectionParams(
            language_code="en-US",
            name="en-US-Neural2-F",
            ssml_gender=texttospeech.SsmlVoiceGender.FEMALE,
        )
        audio_config = texttospeech.AudioConfig(
            audio_encoding=texttospeech.AudioEncoding.MP3
        )
        
        response = tts_client.synthesize_speech(
            input=synthesis_input, 
            voice=voice, 
            audio_config=audio_config
        )
        audio_bytes = response.audio_content
        print(f"  Successfully synthesized {len(audio_bytes)} MP3 audio bytes.")
        
        # 4. Handle Cloudflare R2 Upload & Deletion
        import boto3
        from botocore.config import Config
        
        s3_key = f"audio/{last_article.id}.mp3"
        
        if not settings.CLOUDFLARE_ACCESS_KEY_ID or not settings.R2_ENDPOINT:
            # Fallback Mock logic
            print("\n[R2 Configuration Empty] Performing local DB update with Mock S3 URL...")
            mock_url = f"https://mock-audio-endpoint.com/{s3_key}"
            last_article.audio_s3_key = mock_url
            db.commit()
            print(f"  Successfully saved mock audio url: {mock_url}")
            return
            
        # Instantiate boto3 R2 client
        s3_client = boto3.client(
            "s3",
            aws_access_key_id=settings.CLOUDFLARE_ACCESS_KEY_ID,
            aws_secret_access_key=settings.CLOUDFLARE_SECRET_ACCESS_KEY,
            region_name=settings.R2_REGION,
            endpoint_url=settings.R2_ENDPOINT,
            config=Config(signature_version="s3v4")
        )
        
        # A. Delete old R2 object if exists
        print(f"\n[Cloudflare R2] Deleting old audio object at key: {s3_key}")
        try:
            s3_client.delete_object(
                Bucket=settings.R2_BUCKET_NAME,
                Key=s3_key
            )
            print("  Old object deleted.")
        except Exception as delete_error:
            print(f"  Old object deletion warning: {delete_error} (may not exist, skipping)")
            
        # B. Upload new MP3 bytes to R2
        print(f"[Cloudflare R2] Uploading newly synthesized MP3 bytes...")
        s3_client.put_object(
            Bucket=settings.R2_BUCKET_NAME,
            Key=s3_key,
            Body=audio_bytes,
            ContentType="audio/mpeg"
        )
        print("  New object uploaded successfully.")
        
        # C. Update UploadedAsset row in the database
        print("\n[Database] Updating asset tracking table...")
        asset = db.query(UploadedAsset).filter(UploadedAsset.key == s3_key).first()
        if asset:
            asset.size_bytes = len(audio_bytes)
            asset.created_at = datetime.utcnow()
            print("  Existing asset tracking row updated with new size.")
        else:
            asset = UploadedAsset(
                id=str(uuid.uuid4()),
                key=s3_key,
                mimetype="audio/mpeg",
                category="article_audio",
                size_bytes=len(audio_bytes),
                created_at=datetime.utcnow()
            )
            db.add(asset)
            print("  New asset tracking row created.")
            
        # D. Generate secure pre-signed URL (7 days expiry)
        print("[Cloudflare R2] Generating new pre-signed S3 URL...")
        signed_url = s3_client.generate_presigned_url(
            ClientMethod="get_object",
            Params={
                "Bucket": settings.R2_BUCKET_NAME,
                "Key": s3_key,
            },
            ExpiresIn=604800  # 7 days
        )
        
        # E. Link pre-signed URL directly to article row
        last_article.audio_s3_key = signed_url
        db.commit()
        print(f"\n[Success] Article row linked to the fresh sanitized pre-signed audio URL!")
        print(f"  New Signed URL: {signed_url}")
        
    except Exception as e:
        db.rollback()
        print(f"\n[Error] Scripting magic failed: {e}")
        raise e
    finally:
        db.close()

if __name__ == "__main__":
    re_tts_last_article()
