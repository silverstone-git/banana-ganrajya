import sys
import os
import re

# Ensure the backend directory is in the Python path
sys.path.insert(0, os.path.abspath(os.path.dirname(__file__)))

from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from app.core.config import settings
from app.db.models import Article

def migrate_to_clean_s3_keys():
    db_url = settings.DATABASE_URL
    print("=== Database S3 Key Normalization Migration ===")
    print(f"Connecting to remote database...")
    
    engine = create_engine(db_url)
    Session = sessionmaker(bind=engine)
    db = Session()
    
    try:
        articles = db.query(Article).all()
        converted_count = 0
        skipped_count = 0
        
        print(f"\nScanning {len(articles)} articles...")
        for art in articles:
            s3_key = art.audio_s3_key
            if not s3_key:
                skipped_count += 1
                continue
                
            # If it is a full HTTP presigned URL, extract only the clean S3 key
            if "audio/" in s3_key and (s3_key.startswith("http://") or s3_key.startswith("https://")):
                match = re.search(r'(audio/[^?]+)', s3_key)
                if match:
                    clean_key = match.group(1)
                    print(f"  [CONVERTING] Article ID: {art.id}")
                    print(f"    From: {s3_key[:100]}...")
                    print(f"    To:   {clean_key}")
                    art.audio_s3_key = clean_key
                    converted_count += 1
                else:
                    skipped_count += 1
            else:
                skipped_count += 1
                
        if converted_count > 0:
            db.commit()
            print(f"\n[Success] Migration completed! Cleaned and normalized {converted_count} S3 keys in the database.")
        else:
            print("\n[Skip] All database rows are already fully normalized to clean S3 keys. Zero mutations required.")
            
        print(f"Summary: {converted_count} rows converted, {skipped_count} rows skipped.")
        
    except Exception as e:
        db.rollback()
        print(f"\n[Error] Migration failed: {e}")
        raise e
    finally:
        db.close()

if __name__ == "__main__":
    migrate_to_clean_s3_keys()
