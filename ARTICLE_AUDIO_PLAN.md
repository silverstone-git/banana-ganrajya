# Banana Ganrajya — Article Audio Synthesis & Text-To-Speech (TTS) Integration Plan

This plan outlines the end-to-end architecture, database updates, S3 credentials, API routes, and Flutter-side fallbacks to implement the **Article Listening Capability**.

---

## 🏛️ System Architecture Overview

```
[Flutter Client] 
     │
     ├──► 1. Check if Article has "audioUrl" (S3 Stream)? 
     │         Yes ──► Stream MP3 using `just_audio` / `audioplayers`
     │         No  ──► Check if on-device TTS (flutter_tts) is supported?
     │                  Yes ──► Synthesize and play body text on-device
     │                  No  ──► Completely hide the [LISTEN] button from UI
```

---

## 🗄️ 1. Database & Schema Provision (Backend)

We will add a nullable column `audio_s3_key` to store the reference to the synthesised audio object on AWS S3.

### Model Update (`backend/app/db/models.py`)
```python
class Article(Base):
    __tablename__ = "articles"
    # ... existing columns ...
    audio_s3_key = Column(String, nullable=True)  # S3 location/key for synthesised MP3
```

### Schema Update (`backend/app/schemas/article.py`)
```python
class ArticleSchema(BaseModel):
    # ... existing fields ...
    audioUrl: Optional[str] = None  # Transformed full S3 URL or presigned URL
    
    @classmethod
    def from_orm_model(cls, obj):
        # Resolve full S3 audio URL
        audio_url = None
        if obj.audio_s3_key:
            # If stored as key, combine with bucket URL or presigned URL
            # For simplicity, we can generate a static S3 bucket URL or a presigned URL
            audio_url = f"https://{S3_BUCKET_NAME}.s3.{AWS_REGION}.amazonaws.com/{obj.audio_s3_key}"
            
        return cls(
            # ... other fields ...
            audioUrl=audio_url
        )
```

---

## 🔑 2. S3 & AWS Credentials for `.env`

To enable the backend to synthesise text with AWS Polly and store files in AWS S3, add the following variables to your **`backend/.env`**:

```env
# AWS Polly & S3 Configuration
AWS_ACCESS_KEY_ID=your_aws_access_key_id_here
AWS_SECRET_ACCESS_KEY=your_aws_secret_access_key_here
AWS_DEFAULT_REGION=us-east-1

# S3 Audio Storage Bucket
AWS_S3_AUDIO_BUCKET=banana-article-audio-bucket

# AWS Polly Voice Configurations
AWS_POLLY_VOICE_ID=Joanna
AWS_POLLY_ENGINE=neural
```

---

## 📡 3. Backend Endpoint: Adding Articles with Auto-Synthesis

We will introduce a `POST /api/articles` endpoint. Upon creating a new article, the server will trigger an **Amazon Polly Speech Synthesis Task** asynchronously (as recommended by AWS for texts longer than 3,000 characters) and save the generated audio directly to your S3 bucket.

### Endpoint Implementation Outline (`backend/app/api/routers/articles.py`)
```python
import boto3
from fastapi import APIRouter, Depends, HTTPException, BackgroundTasks

@router.post("/articles", response_model=ArticleSchema, status_code=201)
def create_article(
    payload: ArticleCreateSchema,
    background_tasks: BackgroundTasks,
    db: Session = Depends(get_db)
):
    # 1. Save Article in Database
    new_article = Article(
        id=f"art-{uuid.uuid4().hex[:8]}",
        category=payload.category,
        title=payload.title,
        excerpt=payload.excerpt,
        body=payload.body,
        cover_image_s3_key=payload.cover_image_s3_key,
        author_id=payload.author_id,
        is_premium=payload.is_premium,
        published_at=datetime.utcnow()
    )
    db.add(new_article)
    db.commit()
    db.refresh(new_article)
    
    # 2. Trigger AWS Polly in background
    background_tasks.add_task(
        synthesize_article_audio, 
        article_id=new_article.id, 
        text=new_article.body, 
        db=db
    )
    
    return ArticleSchema.from_orm_model(new_article)

# Background worker
def synthesize_article_audio(article_id: str, text: str, db: Session):
    try:
        polly = boto3.client(
            "polly",
            aws_access_key_id=settings.AWS_ACCESS_KEY_ID,
            aws_secret_access_key=settings.AWS_SECRET_ACCESS_KEY,
            region_name=settings.AWS_DEFAULT_REGION
        )
        
        # Start synthesis directly to S3 (handles long texts up to 100k chars)
        response = polly.start_speech_synthesis_task(
            Engine=settings.AWS_POLLY_ENGINE,      # 'neural' (high quality)
            OutputFormat='mp3',
            OutputS3BucketName=settings.AWS_S3_AUDIO_BUCKET,
            OutputS3KeyPrefix=f"audio/{article_id}",
            Text=text[:20000],                     # Truncated safely
            VoiceId=settings.AWS_POLLY_VOICE_ID    # e.g., 'Joanna' or 'Matthew'
        )
        
        task_id = response['SynthesisTask']['TaskId']
        s3_url_key = f"audio/{article_id}.{task_id}.mp3"
        
        # Update database with S3 Key
        article = db.query(Article).filter(Article.id == article_id).first()
        if article:
            article.audio_s3_key = s3_url_key
            db.commit()
            
    except Exception as e:
        print(f"[AWS Polly Synthesis Failed]: {e}")
```

---

## 📱 4. Client-Side Smart Fallback Strategy (Flutter)

To give readers a flawless, high-contrast playback experience, we implement an intelligent multi-layer client-side lookup:

### Step 1: Query S3 Stream URL (Layer 1)
If the backend `Article` object contains a non-null `audioUrl`:
* Use standard **`just_audio`** or **`audioplayers`** packages.
* Stream and buffer the high-quality, neural AWS Polly MP3 file.
* This delivers a beautiful, natural narrator voice without CPU overhead.

### Step 2: On-Device TTS Fallback (Layer 2)
If `audioUrl` is `null` (e.g., offline, synthesis failed, or local/seeded custom articles):
* Initialize **`flutter_tts`**.
* Check language support (Android, iOS, Web).
* Speak the article's body text natively using local device engines.

### Step 3: Progressive Degradation & Native Safety (Layer 3)
If the device doesn't support Text-to-Speech (or doesn't have an English engine installed):
* **Completely hide the `[LISTEN]` Button** from the UI. 
* Prevents silent dead taps and enhances UI predictability.

---

## ⚙️ 5. Flutter Configuration & manifest permissions

To ensure on-device checks execute reliably across iOS and Android (specifically targeting Android 11+), the following platform permissions must be applied:

### Android Support (Android 11+ / SDK 30+)
Add the `<queries>` element inside the `<manifest>` block of `android/app/src/main/AndroidManifest.xml`:

```xml
<queries>
    <!-- Explicit intent check for Text-To-Speech services on Android 11+ -->
    <intent>
        <action android:name="android.intent.action.TTS_SERVICE" />
    </intent>
</queries>
```

---

## 🛠️ Flutter Listening Component Blueprint

```dart
class _ListenButton extends StatefulWidget {
  const _ListenButton({required this.article});
  final Article article;

  @override
  State<_ListenButton> createState() => _ListenButtonState();
}

class _ListenButtonState extends State<_ListenButton> {
  final FlutterTts _flutterTts = FlutterTts();
  bool _isTtsSupported = false;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _verifyTtsCapability();
  }

  Future<void> _verifyTtsCapability() async {
    // If article already has S3 audioUrl, we don't need on-device checks
    if (widget.article.audioUrl != null && widget.article.audioUrl!.isNotEmpty) {
      setState(() => _isTtsSupported = true);
      return;
    }
    
    // Fallback: Check if English TTS is supported by the device OS
    try {
      bool isLanguageSupported = await _flutterTts.isLanguageAvailable("en-US");
      setState(() {
        _isTtsSupported = isLanguageSupported;
      });
    } catch (_) {
      setState(() => _isTtsSupported = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Progressive degradation: Hide button completely if neither S3 nor on-device TTS is available
    if (!_isTtsSupported) return const SizedBox.shrink();

    return GestureDetector(
      onTap: _toggleAudioPlayback,
      child: Container(
        // Styled beautifully as fixed earlier...
      ),
    );
  }
}
```
