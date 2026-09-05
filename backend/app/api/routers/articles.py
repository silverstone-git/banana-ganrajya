import uuid
from datetime import datetime
from fastapi import APIRouter, Depends, HTTPException, Query, status, BackgroundTasks, UploadFile, File
from sqlalchemy.orm import Session
from typing import List, Optional

from app.db.database import get_db
from app.db.models import Article, Author, Comment, Bookmark, User, Transaction, AnalyticsRead, Tag, article_tags, UploadedAsset
from app.schemas.article import (
    ArticleSchema, AuthorSchema, HomeFeedResponse, FineprintFeedResponse, OpinionFeedResponse,
    ColumnistGalleryItem, CommentResponseSchema, CommentCreateSchema,
    BookmarkToggleResponse, SearchResultsResponse, UserSyncSchema, UserMeResponse,
    PaymentInitiateRequest, PaymentInitiateResponse, PaymentVerifyRequest, ReadTelemetryRequest,
    ArticleCreateSchema, AppConfigResponse, AdminConfigResponse
)
from app.core.auth import auth0
from app.core.config import settings

router = APIRouter(prefix="/api", tags=["articles"])

# --- AUTHENTICATION DEPENDENCY ---

# Dependency to validate and retrieve the dynamic Auth0 User ID from the JWT sub claim.
# This validates the token signature, expiration, issuer, and audience against the JWKS endpoint.
def get_current_user_id(claims: dict = Depends(auth0.require_auth())) -> str:
    return claims["sub"]


# --- FEEDS (Replacing Mock Data) ---

@router.get("/feed/home", response_model=HomeFeedResponse)
def get_home_feed(db: Session = Depends(get_db)):
    hero = db.query(Article).filter(Article.id == "hero-1").first()
    if not hero:
        raise HTTPException(status_code=404, detail="Hero story not found. Please run seeder.")
    
    secondary = db.query(Article).filter(Article.id.like("sec-%")).all()
    ground = db.query(Article).filter(Article.id.like("gr-%")).all()
    
    return HomeFeedResponse(
        heroStory=ArticleSchema.from_orm_model(hero),
        secondaryStories=[ArticleSchema.from_orm_model(a) for a in secondary],
        groundReports=[ArticleSchema.from_orm_model(a) for a in ground]
    )

@router.get("/feed/fineprint", response_model=FineprintFeedResponse)
def get_fineprint_feed(db: Session = Depends(get_db)):
    featured = db.query(Article).filter(Article.id == "fp-featured").first()
    if not featured:
        raise HTTPException(status_code=404, detail="Featured Fineprint story not found. Please run seeder.")
    
    list_articles = db.query(Article).filter(Article.id.like("fp-%"), Article.id != "fp-featured").all()
    
    return FineprintFeedResponse(
        featured=ArticleSchema.from_orm_model(featured),
        list=[ArticleSchema.from_orm_model(a) for a in list_articles]
    )

@router.get("/feed/opinion", response_model=OpinionFeedResponse)
def get_opinion_feed(db: Session = Depends(get_db)):
    featured = db.query(Article).filter(Article.id == "op-featured").first()
    if not featured:
        raise HTTPException(status_code=404, detail="Featured Opinion story not found. Please run seeder.")
    
    rows = db.query(Article).filter(Article.id.like("op-%"), Article.id != "op-featured").all()
    
    # Exclude general desk team from columnists gallery
    authors = db.query(Author).filter(Author.id != "banana_team").all()
    columnists_gallery = [
        ColumnistGalleryItem(name=a.name, avatar_url=a.avatar_s3_key, title=a.title)
        for a in authors
    ]
    
    return OpinionFeedResponse(
        featured=ArticleSchema.from_orm_model(featured),
        rows=[ArticleSchema.from_orm_model(a) for a in rows],
        columnists=columnists_gallery
    )


# --- GENERAL ARTICLES ---

@router.get("/articles", response_model=List[ArticleSchema])
def list_articles(
    category: Optional[str] = None,
    is_premium: Optional[bool] = None,
    skip: int = 0,
    limit: int = 10,
    db: Session = Depends(get_db)
):
    query = db.query(Article)
    if category:
        query = query.filter(Article.category.ilike(category))
    if is_premium is not None:
        query = query.filter(Article.is_premium == is_premium)
    
    articles = query.offset(skip).limit(limit).all()
    return [ArticleSchema.from_orm_model(a) for a in articles]

@router.get("/articles/{article_id}", response_model=ArticleSchema)
def get_article(article_id: str, db: Session = Depends(get_db)):
    article = db.query(Article).filter(Article.id == article_id).first()
    if not article:
        raise HTTPException(status_code=404, detail="Article not found")
    return ArticleSchema.from_orm_model(article)

from fastapi.responses import HTMLResponse
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from app.core.config import settings

security = HTTPBearer()

def validate_admin_privilege(credentials: HTTPAuthorizationCredentials = Depends(security)) -> str:
    if not credentials:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Missing Authorization Header."
        )
    if credentials.credentials != settings.ADMIN_API_KEY:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Forbidden: Invalid Admin API Key."
        )
    return credentials.credentials

@router.post("/admin/upload-image")
def upload_image(
    file: UploadFile = File(...),
    admin_key: str = Depends(validate_admin_privilege),
    db: Session = Depends(get_db)
):
    import boto3
    from botocore.config import Config
    
    # Verify it is an image
    if not file.content_type.startswith("image/"):
        raise HTTPException(status_code=400, detail="Only image uploads are permitted.")
        
    # Read image bytes
    try:
        image_bytes = file.file.read()
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to read image bytes: {e}")
        
    s3_key = f"images/{uuid.uuid4().hex}_{file.filename}"
    
    # If R2 config is empty, fallback to a beautiful random news image mock/placeholder URL
    if not settings.CLOUDFLARE_ACCESS_KEY_ID or not settings.R2_ENDPOINT:
        mock_url = f"https://images.unsplash.com/photo-1495020689067-958852a6565d?auto=format&fit=crop&w=800&q=80"
        print(f"[R2 Mock Upload] Mock upload successful, returning: {mock_url}")
        return {"url": mock_url, "key": s3_key}
        
    try:
        s3_client = boto3.client(
            "s3",
            aws_access_key_id=settings.CLOUDFLARE_ACCESS_KEY_ID,
            aws_secret_access_key=settings.CLOUDFLARE_SECRET_ACCESS_KEY,
            region_name=settings.R2_REGION,
            endpoint_url=settings.R2_ENDPOINT,
            config=Config(signature_version="s3v4")
        )
        
        # Upload object to R2
        s3_client.put_object(
            Bucket=settings.R2_BUCKET_NAME,
            Key=s3_key,
            Body=image_bytes,
            ContentType=file.content_type
        )
        
        # Log metadata into UploadedAsset table
        new_asset = UploadedAsset(
            id=str(uuid.uuid4()),
            key=s3_key,
            mimetype=file.content_type,
            category="article_image",
            size_bytes=len(image_bytes),
            created_at=datetime.utcnow()
        )
        db.add(new_asset)
        db.commit()
        
        # Generate pre-signed GET URL (7 days expiration)
        signed_url = s3_client.generate_presigned_url(
            ClientMethod="get_object",
            Params={
                "Bucket": settings.R2_BUCKET_NAME,
                "Key": s3_key,
            },
            ExpiresIn=604800 # 7 days
        )
        return {"url": signed_url, "key": s3_key}
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to upload image to Cloudflare R2: {e}")

@router.get("/admin/publish", response_class=HTMLResponse)
def get_publish_form(db: Session = Depends(get_db)):
    authors = db.query(Author).order_by(Author.name).all()
    author_options = "".join([
        f'<option value="{a.id}">{a.name} — {a.title}</option>'
        for a in authors
    ])
    
    html_content = f"""<!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Banana Ganrajya — Editorial Desk</title>
        <link href="https://fonts.googleapis.com/css2?family=Source+Serif+4:ital,opsz,wght@0,8..60,200..900;1,8..60,200..900&family=Work+Sans:wght@300;400;500;600;700&display=swap" rel="stylesheet">
        <link href="https://cdn.jsdelivr.net/npm/quill@2.0.2/dist/quill.snow.css" rel="stylesheet">
        <style>
            :root {{
                --primary: #AC2E05;
                --background: #FCFCFA;
                --text: #1B1B1B;
                --surface: #FFFFFF;
                --outline: #D6D6D6;
                --secondary: #5F5F5F;
            }}
            body {{
                font-family: 'Work Sans', sans-serif;
                background-color: var(--background);
                color: var(--text);
                margin: 0;
                padding: 40px 20px;
                display: flex;
                justify-content: center;
            }}
            .container {{
                max-width: 760px;
                width: 100%;
                background: var(--surface);
                padding: 40px;
                border: 1px solid var(--outline);
                box-shadow: 0 4px 20px rgba(0, 0, 0, 0.03);
            }}
            .header {{
                text-align: center;
                margin-bottom: 40px;
            }}
            .header h1 {{
                font-family: 'Source Serif 4', serif;
                font-size: 38px;
                font-weight: 800;
                margin: 0 0 10px 0;
                letter-spacing: -0.5px;
            }}
            .header p {{
                font-size: 14px;
                color: var(--secondary);
                text-transform: uppercase;
                letter-spacing: 2px;
                margin: 0;
            }}
            .divider {{
                border-top: 3px solid var(--text);
                border-bottom: 1px solid var(--text);
                height: 2px;
                margin: 16px 0;
            }}
            .form-group {{
                margin-bottom: 24px;
            }}
            .form-group label {{
                display: block;
                font-size: 12px;
                font-weight: 700;
                text-transform: uppercase;
                letter-spacing: 1px;
                margin-bottom: 8px;
                color: var(--text);
            }}
            .form-control {{
                width: 100%;
                box-sizing: border-box;
                padding: 12px 16px;
                font-size: 15px;
                font-family: 'Work Sans', sans-serif;
                border: 1px solid var(--outline);
                border-radius: 4px;
                background-color: var(--surface);
                color: var(--text);
                transition: border-color 0.2s;
            }}
            .form-control:focus {{
                outline: none;
                border-color: var(--primary);
            }}
            #editor {{
                min-height: 350px;
                font-family: 'Source Serif 4', serif;
                font-size: 16px;
                background-color: var(--surface);
                border-bottom-left-radius: 4px;
                border-bottom-right-radius: 4px;
            }}
            .ql-toolbar {{
                background-color: #f7f7f7;
                border-top-left-radius: 4px;
                border-top-right-radius: 4px;
                border-color: var(--outline) !important;
            }}
            .ql-container {{
                border-color: var(--outline) !important;
            }}
            .btn {{
                display: block;
                width: 100%;
                padding: 14px;
                font-size: 14px;
                font-weight: 700;
                text-transform: uppercase;
                letter-spacing: 1.5px;
                background-color: var(--text);
                color: white;
                border: none;
                border-radius: 4px;
                cursor: pointer;
                transition: background-color 0.2s;
            }}
            .btn:hover {{
                background-color: var(--primary);
            }}
            .status-card {{
                display: none;
                padding: 16px;
                border-radius: 4px;
                margin-top: 24px;
                font-size: 14px;
                line-height: 1.5;
            }}
            .status-success {{
                background-color: #E6F4EA;
                color: #137333;
                border: 1px solid #C4EED0;
            }}
            .status-error {{
                background-color: #FCE8E6;
                color: #C5221F;
                border: 1px solid #FAD2CF;
            }}
            .upload-zone {{
                border: 2px dashed var(--outline);
                padding: 24px;
                text-align: center;
                border-radius: 4px;
                background: #fafafa;
                transition: border-color 0.2s, background-color 0.2s;
                cursor: pointer;
                margin-bottom: 12px;
            }}
            .upload-zone:hover {{
                border-color: var(--primary);
                background: #fffdfb;
            }}
        </style>
        <script src="https://cdn.jsdelivr.net/npm/quill@2.0.2/dist/quill.js"></script>
    </head>
    <body>
        <div class="container">
            <div class="header">
                <h1>Banana Ganrajya</h1>
                <p>Editorial Publishing Desk</p>
                <div class="divider"></div>
            </div>
            
            <form id="publishForm">
                <div class="form-group">
                    <label for="apiKey">Admin API Key</label>
                    <input type="password" id="apiKey" name="apiKey" required class="form-control" placeholder="Paste your Admin API Key here">
                </div>
                
                <div class="form-group">
                    <label for="title">Article Title</label>
                    <input type="text" id="title" name="title" required class="form-control" placeholder="Enter headline title">
                </div>
                
                <div class="form-group" style="display: flex; gap: 16px;">
                    <div style="flex: 1;">
                        <label for="category">Category</label>
                        <select id="category" name="category" required class="form-control">
                            <option value="politics">Politics</option>
                            <option value="opinion">Opinion</option>
                            <option value="ground-reports">Ground Reports</option>
                            <option value="economy">Economy</option>
                            <option value="national">National</option>
                        </select>
                    </div>
                    <div style="flex: 1;">
                        <label for="authorId">Author</label>
                        <select id="authorId" name="authorId" required class="form-control">
                            {author_options}
                        </select>
                    </div>
                </div>
                
                <div class="form-group">
                    <label for="coverImage">Cover Image S3 Key / URL</label>
                    <div style="display: flex; gap: 12px; margin-bottom: 8px;">
                        <input type="text" id="coverImage" name="coverImage" required class="form-control" value="https://images.unsplash.com/photo-1504711434969-e33886168f5c?auto=format&fit=crop&w=800&q=80">
                        <button type="button" class="btn" style="width: auto; white-space: nowrap; padding: 0 16px; background: var(--secondary);" onclick="document.getElementById('coverImageFile').click()">Upload File</button>
                    </div>
                    <input type="file" id="coverImageFile" accept="image/*" style="display: none;">
                    <div id="coverUploadStatus" style="font-weight: 600; font-size: 13px; margin-bottom: 8px;"></div>
                    <div id="coverPreviewContainer" style="display: none; border: 1px solid var(--outline); padding: 8px; border-radius: 4px; max-width: 200px; background-color: #fafafa;">
                        <p style="font-size: 10px; text-transform: uppercase; font-weight: bold; margin: 0 0 6px 0; color: var(--secondary);">Cover Preview</p>
                        <img id="coverPreview" src="" style="width: 100%; height: auto; border-radius: 2px;">
                    </div>
                </div>
                
                <div class="form-group">
                    <label for="excerpt">Excerpt</label>
                    <input type="text" id="excerpt" name="excerpt" required class="form-control" placeholder="Brief summary of the article">
                </div>

                <!-- Beautiful Inline S3 Image Insertion Widget -->
                <div class="form-group">
                    <label>Inline Image S3 Upload & Insertion Tool</label>
                    <div class="upload-zone" id="uploadZone" onclick="document.getElementById('inlineImageFile').click()">
                        <input type="file" id="inlineImageFile" accept="image/*" style="display: none;">
                        <svg style="width: 32px; height: 32px; fill: var(--secondary); margin-bottom: 8px;" viewBox="0 0 24 24">
                            <path d="M19.35 10.04C18.67 6.59 15.64 4 12 4 9.11 4 6.6 5.64 5.35 8.04 2.34 8.36 0 10.91 0 14c0 3.31 2.69 6 6 6h13c2.76 0 5-2.24 5-5 0-2.64-2.05-4.78-4.65-4.96zM14 13v4h-4v-4H7l5-5 5 5h-3z"/>
                        </svg>
                        <p style="font-size: 14px; font-weight: bold; margin: 0 0 4px 0;">Select or drag-and-drop an image file</p>
                        <p style="font-size: 12px; margin: 0; color: var(--secondary);">Uploads instantly to S3/R2 and inserts right where your cursor is!</p>
                    </div>
                    <div id="uploadStatus" style="font-weight: 600; font-size: 13px; text-align: center;"></div>
                </div>
                
                <div class="form-group">
                    <label>Article Body (Editorial Content - Rich Text)</label>
                    <div id="editor"></div>
                    <input type="hidden" id="body" name="body">
                </div>
                
                <div class="form-group" style="display: flex; gap: 16px;">
                    <div style="display: flex; align-items: center;">
                        <input type="checkbox" id="isPremium" name="isPremium" style="width: 18px; height: 18px; cursor: pointer;">
                        <label for="isPremium" style="margin: 0 0 0 8px; cursor: pointer; text-transform: none; letter-spacing: 0;">Is Premium Article?</label>
                    </div>
                </div>
                
                <button type="submit" id="submitBtn" class="btn">Publish Editorial</button>
            </form>
            
            <div id="statusCard" class="status-card"></div>
        </div>

        <script>
            // Initialize Quill.js Rich Text Editor
            const quill = new Quill('#editor', {{
                theme: 'snow',
                placeholder: 'Compose your news article with full headings, bold text, and inline images...',
                modules: {{
                    toolbar: [
                        [{{ 'header': [1, 2, 3, false] }}],
                        ['bold', 'italic', 'underline', 'strike'],
                        ['blockquote', 'link', 'image'],
                        [{{ 'list': 'ordered'}}, {{ 'list': 'bullet' }}],
                        ['clean']
                    ]
                }}
            }});

            // Intercept standard Quill image button to upload to S3/R2 dynamically
            const selectLocalImageToolbar = () => {{
                const input = document.createElement('input');
                input.setAttribute('type', 'file');
                input.setAttribute('accept', 'image/*');
                input.click();

                input.onchange = async () => {{
                    const file = input.files[0];
                    const apiKey = document.getElementById('apiKey').value.trim();
                    
                    if (!apiKey) {{
                        alert('Please paste your Admin API Key first before uploading images!');
                        return;
                    }}

                    const formData = new FormData();
                    formData.append('file', file);

                    try {{
                        const response = await fetch('/api/admin/upload-image', {{
                            method: 'POST',
                            headers: {{
                                'Authorization': `Bearer ${{apiKey}}`
                            }},
                            body: formData
                        }});

                        if (!response.ok) {{
                            const errData = await response.json();
                            alert(`Upload failed: ${{errData.detail || 'Server error.'}}`);
                            return;
                        }}

                        const data = await response.json();
                        const range = quill.getSelection(true);
                        quill.insertEmbed(range.index, 'image', data.url);
                        quill.setSelection(range.index + 1);
                    }} catch (err) {{
                        alert(`Network error: ${{err.message}}`);
                    }}
                }};
            }};
            quill.getModule('toolbar').addHandler('image', selectLocalImageToolbar);

            // Cover Image Upload Handler
            document.getElementById('coverImageFile').addEventListener('change', async function() {{
                const file = this.files[0];
                if (!file) return;

                const apiKey = document.getElementById('apiKey').value.trim();
                if (!apiKey) {{
                    alert('Please paste your Admin API Key first before uploading!');
                    this.value = '';
                    return;
                }}

                const coverUploadStatus = document.getElementById('coverUploadStatus');
                coverUploadStatus.style.color = 'var(--primary)';
                coverUploadStatus.innerText = '⏳ Uploading cover image to S3/R2...';

                const formData = new FormData();
                formData.append('file', file);

                try {{
                    const response = await fetch('/api/admin/upload-image', {{
                        method: 'POST',
                        headers: {{
                            'Authorization': `Bearer ${{apiKey}}`
                        }},
                        body: formData
                    }});

                    const data = await response.json();

                    if (response.ok) {{
                        coverUploadStatus.style.color = '#137333';
                        coverUploadStatus.innerText = '✅ Cover image uploaded successfully!';
                        
                        // Set the input value to the uploaded S3 URL
                        document.getElementById('coverImage').value = data.url;
                        
                        // Show Cover Image Preview
                        document.getElementById('coverPreview').src = data.url;
                        document.getElementById('coverPreviewContainer').style.display = 'block';
                    }} else {{
                        coverUploadStatus.style.color = '#C5221F';
                        coverUploadStatus.innerText = `❌ Upload failed: ${{data.detail || 'Server error.'}}`;
                    }}
                }} catch (err) {{
                    coverUploadStatus.style.color = '#C5221F';
                    coverUploadStatus.innerText = `❌ Connection error: ${{err.message}}`;
                }} finally {{
                    this.value = ''; // Reset file input
                }}
            }});

            // Large Drag & Drop Inline Upload Card handler
            document.getElementById('inlineImageFile').addEventListener('change', async function() {{
                const file = this.files[0];
                if (!file) return;

                const apiKey = document.getElementById('apiKey').value.trim();
                if (!apiKey) {{
                    alert('Please paste your Admin API Key first before uploading!');
                    this.value = '';
                    return;
                }}

                const uploadStatus = document.getElementById('uploadStatus');
                uploadStatus.style.color = 'var(--primary)';
                uploadStatus.innerText = '⏳ Uploading image to S3/R2 bucket...';

                const formData = new FormData();
                formData.append('file', file);

                try {{
                    const response = await fetch('/api/admin/upload-image', {{
                        method: 'POST',
                        headers: {{
                            'Authorization': `Bearer ${{apiKey}}`
                        }},
                        body: formData
                    }});

                    const data = await response.json();

                    if (response.ok) {{
                        uploadStatus.style.color = '#137333';
                        uploadStatus.innerText = '✅ Upload successful! Embedded inline.';
                        
                        // Insert image inline into Quill editor at current selection
                        const range = quill.getSelection(true);
                        quill.insertEmbed(range.index, 'image', data.url);
                        quill.setSelection(range.index + 1);
                    }} else {{
                        uploadStatus.style.color = '#C5221F';
                        uploadStatus.innerText = `❌ Upload failed: ${{data.detail || 'Server error.'}}`;
                    }}
                }} catch (err) {{
                    uploadStatus.style.color = '#C5221F';
                    uploadStatus.innerText = `❌ Connection error: ${{err.message}}`;
                }} finally {{
                    this.value = ''; // Reset file input
                }}
            }});

            // Form submission mapping Quill semantic HTML to body payload
            document.getElementById('publishForm').addEventListener('submit', async function(e) {{
                e.preventDefault();
                
                const submitBtn = document.getElementById('submitBtn');
                const statusCard = document.getElementById('statusCard');
                
                submitBtn.disabled = true;
                submitBtn.innerText = 'Publishing...';
                statusCard.style.display = 'none';
                
                const apiKey = document.getElementById('apiKey').value.trim();
                
                // Retrieve Quill semantically structured HTML including embedded <p> and <img> tags
                const bodyHTML = quill.getSemanticHTML();
                
                const payload = {{
                    title: document.getElementById('title').value.trim(),
                    category: document.getElementById('category').value.trim(),
                    author_id: document.getElementById('authorId').value.trim(),
                    cover_image_s3_key: document.getElementById('coverImage').value.trim(),
                    excerpt: document.getElementById('excerpt').value.trim(),
                    body: bodyHTML,
                    is_premium: document.getElementById('isPremium').checked
                }};
                
                try {{
                    const response = await fetch('/api/articles', {{
                        method: 'POST',
                        headers: {{
                            'Content-Type': 'application/json',
                            'Authorization': `Bearer ${{apiKey}}`
                        }},
                        body: JSON.stringify(payload)
                    }});
                    
                    const data = await response.json();
                    
                    if (response.ok) {{
                        statusCard.className = 'status-card status-success';
                        statusCard.innerHTML = `<strong>Success!</strong> Rich text editorial published successfully.<br><strong>Article ID:</strong> ${{data.id}}<br><strong>Category:</strong> ${{data.category}}<br><strong>Synthesis Status:</strong> Google Cloud TTS and Cloudflare R2 audio upload queued.`;
                        statusCard.style.display = 'block';
                        
                        // Clear fields except API Key
                        document.getElementById('title').value = '';
                        document.getElementById('excerpt').value = '';
                        quill.setText(''); // Wipe editor contents
                        document.getElementById('coverPreviewContainer').style.display = 'none';
                        document.getElementById('coverUploadStatus').innerText = '';
                    }} else {{
                        statusCard.className = 'status-card status-error';
                        statusCard.innerHTML = `<strong>Failed to Publish:</strong> ${{data.detail || 'Server returned error.'}} (Status: ${{response.status}})`;
                        statusCard.style.display = 'block';
                    }}
                }} catch (err) {{
                    statusCard.className = 'status-card status-error';
                    statusCard.innerHTML = `<strong>Network Connection Error:</strong> ${{err.message}}`;
                    statusCard.style.display = 'block';
                }} finally {{
                    submitBtn.disabled = false;
                    submitBtn.innerText = 'Publish Editorial';
                }}
            }});
        </script>
    </body>
    </html>
    """
    return HTMLResponse(content=html_content)

async def synthesize_article_audio_task(article_id: str, text: str):
    from app.db.database import SessionLocal
    from app.core.config import settings
    import boto3
    from botocore.config import Config
    from google.cloud import texttospeech_v1 as texttospeech
    
    # 1. Google Cloud Text-To-Speech Synthesis (Async)
    try:
        # GCP client handles credentials automatically via ADC (Local files or Cloud Run identity)
        tts_client = texttospeech.TextToSpeechAsyncClient()
        
        # Strip HTML tags and links/URLs before submitting to GCP TTS
        import re
        clean_text = re.sub(r'https?://\S+|www\.\S+', '', text)  # Remove links/URLs
        clean_text = re.sub(r'<[^>]+>', '', clean_text)           # Remove HTML tags
        clean_text = re.sub(r'\s+', ' ', clean_text).strip()       # Clean up whitespace
        
        synthesis_input = texttospeech.SynthesisInput(text=clean_text[:3000]) # Safe content truncation
        
        voice = texttospeech.VoiceSelectionParams(
            language_code="en-US",
            name="en-US-Neural2-F",
            ssml_gender=texttospeech.SsmlVoiceGender.FEMALE,
        )
        
        audio_config = texttospeech.AudioConfig(
            audio_encoding=texttospeech.AudioEncoding.MP3
        )
        
        print(f"[GCP TTS] Asynchronously synthesizing speech for article: {article_id}")
        response = await tts_client.synthesize_speech(
            input=synthesis_input, 
            voice=voice, 
            audio_config=audio_config
        )
        audio_bytes = response.audio_content
    except Exception as e:
        print(f"[GCP TTS Synthesis Failed]: {e}")
        _save_fallback_mock_audio_url(article_id)
        return

    # 2. Upload MP3 bytes to Cloudflare R2 (S3-Compatible API)
    db = SessionLocal()
    try:
        s3_key = f"audio/{article_id}.mp3"
        
        # If R2 config is unpopulated in .env, fallback to mock server URL directly
        if not settings.CLOUDFLARE_ACCESS_KEY_ID or not settings.R2_ENDPOINT:
            print("[Cloudflare R2] Empty credentials, fallback to mock audio URL.")
            article = db.query(Article).filter(Article.id == article_id).first()
            if article:
                article.audio_s3_key = f"https://mock-audio-endpoint.com/{s3_key}"
                db.commit()
            return

        s3_client = boto3.client(
            "s3",
            aws_access_key_id=settings.CLOUDFLARE_ACCESS_KEY_ID,
            aws_secret_access_key=settings.CLOUDFLARE_SECRET_ACCESS_KEY,
            region_name=settings.R2_REGION,
            endpoint_url=settings.R2_ENDPOINT,
            config=Config(signature_version="s3v4") # Cloudflare R2 mandates S3v4 signing
        )
        
        print(f"[Cloudflare R2] Uploading synthesised MP3 to key: {s3_key}")
        s3_client.put_object(
            Bucket=settings.R2_BUCKET_NAME,
            Key=s3_key,
            Body=audio_bytes,
            ContentType="audio/mpeg"
        )
        
        # 3. Log R2 Asset metadata into UploadedAsset tracking table
        audio_size_bytes = len(audio_bytes)
        new_asset = UploadedAsset(
            id=str(uuid.uuid4()),
            key=s3_key,
            mimetype="audio/mpeg",
            category="article_audio",
            size_bytes=audio_size_bytes,
            created_at=datetime.utcnow()
        )
        db.add(new_asset)
        
        # 4. Generate a Signed / Pre-signed S3 URL for secure download (Max 7 days expiry)
        print(f"[Cloudflare R2] Generating pre-signed GET URL for: {s3_key}")
        signed_url = s3_client.generate_presigned_url(
            ClientMethod="get_object",
            Params={
                "Bucket": settings.R2_BUCKET_NAME,
                "Key": s3_key,
            },
            ExpiresIn=604800  # 7 days expiration
        )
        
        # 5. Save the clean S3 key directly into the database column `audio_s3_key`
        article = db.query(Article).filter(Article.id == article_id).first()
        if article:
            article.audio_s3_key = s3_key
            db.commit()
            print(f"[Cloudflare R2] Stored clean S3 Key inside database: {s3_key}")
            
    except Exception as e:
        print(f"[Cloudflare R2 Upload/Sign Failed]: {e}")
        mock_key = f"https://mock-audio-endpoint.com/audio/{article_id}.mp3"
        article = db.query(Article).filter(Article.id == article_id).first()
        if article:
            article.audio_s3_key = mock_key
            db.commit()
    finally:
        db.close()

def _save_fallback_mock_audio_url(article_id: str):
    from app.db.database import SessionLocal
    db = SessionLocal()
    try:
        mock_key = f"https://mock-audio-endpoint.com/audio/{article_id}.mp3"
        article = db.query(Article).filter(Article.id == article_id).first()
        if article:
            article.audio_s3_key = mock_key
            db.commit()
            print(f"[GCP TTS Fallback] Successfully set local fallback URL: {mock_key}")
    except Exception as e:
        print(f"[GCP TTS Fallback DB Update Failed]: {e}")
    finally:
        db.close()

@router.post("/articles", response_model=ArticleSchema, status_code=status.HTTP_201_CREATED)
def create_article(
    payload: ArticleCreateSchema,
    background_tasks: BackgroundTasks,
    admin_key: str = Depends(validate_admin_privilege),
    db: Session = Depends(get_db)
):
    # Verify author exists
    author = db.query(Author).filter(Author.id == payload.author_id).first()
    if not author:
        raise HTTPException(status_code=404, detail="Author profile not found")
        
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
    
    # Delegate synthesis to a background task
    background_tasks.add_task(synthesize_article_audio_task, article_id=new_article.id, text=new_article.body)
    
    return ArticleSchema.from_orm_model(new_article)


# --- AUTHENTICATION & USERS (Auth0 Sync journey) ---

@router.post("/users/sync", response_model=UserMeResponse)
def sync_user(
    payload: UserSyncSchema, 
    current_user_id: str = Depends(get_current_user_id), 
    db: Session = Depends(get_db)
):
    user = db.query(User).filter(User.id == current_user_id).first()
    if not user:
        user = User(
            id=current_user_id,
            email=payload.email,
            name=payload.name or "John Doe",
            tier="FREE"
        )
        db.add(user)
        db.commit()
        db.refresh(user)
    else:
        if payload.name:
            user.name = payload.name
        if payload.email:
            user.email = payload.email
        db.commit()
        db.refresh(user)
    return user

@router.get("/users/me", response_model=UserMeResponse)
def get_me(current_user_id: str = Depends(get_current_user_id), db: Session = Depends(get_db)):
    user = db.query(User).filter(User.id == current_user_id).first()
    if not user:
        # Auto-create profile shell if user has logged in but hasn't synced yet
        user = User(
            id=current_user_id,
            email="user@example.com",  # Placeholder, will be synced properly
            name="Auth0 Reader",
            tier="FREE"
        )
        db.add(user)
        db.commit()
        db.refresh(user)
    return user


# --- DYNAMIC CONFIGURATION ---

@router.get("/config", response_model=AppConfigResponse)
def get_app_config():
    return AppConfigResponse(admin_email=settings.ADMIN_EMAIL)

@router.get("/admin/config", response_model=AdminConfigResponse)
def get_admin_config(current_user_id: str = Depends(get_current_user_id), db: Session = Depends(get_db)):
    user = db.query(User).filter(User.id == current_user_id).first()
    if not user or user.email != settings.ADMIN_EMAIL:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Forbidden: You are not authorized as the administrator."
        )
    return AdminConfigResponse(admin_api_key=settings.ADMIN_API_KEY)


# --- BOOKMARKS (Saved Articles journey) ---

@router.get("/bookmarks", response_model=List[ArticleSchema])
def get_bookmarks(current_user_id: str = Depends(get_current_user_id), db: Session = Depends(get_db)):
    # Find all articles bookmarked by the active Auth0 user
    bookmarks = db.query(Bookmark).filter(Bookmark.user_id == current_user_id).all()
    article_ids = [b.article_id for b in bookmarks]
    articles = db.query(Article).filter(Article.id.in_(article_ids)).all() if article_ids else []
    return [ArticleSchema.from_orm_model(a) for a in articles]

@router.post("/bookmarks/{article_id}", response_model=BookmarkToggleResponse)
def add_bookmark(
    article_id: str, 
    current_user_id: str = Depends(get_current_user_id), 
    db: Session = Depends(get_db)
):
    # Verify article exists
    article = db.query(Article).filter(Article.id == article_id).first()
    if not article:
        raise HTTPException(status_code=404, detail="Article not found")
    
    bookmark = db.query(Bookmark).filter(
        Bookmark.user_id == current_user_id,
        Bookmark.article_id == article_id
    ).first()
    
    if not bookmark:
        bookmark = Bookmark(user_id=current_user_id, article_id=article_id)
        db.add(bookmark)
        db.commit()
    
    return BookmarkToggleResponse(article_id=article_id, bookmarked=True)

@router.delete("/bookmarks/{article_id}", response_model=BookmarkToggleResponse)
def remove_bookmark(
    article_id: str, 
    current_user_id: str = Depends(get_current_user_id), 
    db: Session = Depends(get_db)
):
    bookmark = db.query(Bookmark).filter(
        Bookmark.user_id == current_user_id,
        Bookmark.article_id == article_id
    ).first()
    
    if bookmark:
        db.delete(bookmark)
        db.commit()
    
    return BookmarkToggleResponse(article_id=article_id, bookmarked=False)


# --- COMMENTS (Discussions & Social journey) ---

def format_comment_tree(comment, db_comments_map):
    replies = [format_comment_tree(child, db_comments_map) for child in db_comments_map.get(comment.id, [])]
    return CommentResponseSchema(
        id=comment.id,
        article_id=comment.article_id,
        user_name=comment.user.name or "Anonymous Reader",
        user_avatar=None,
        body=comment.body,
        created_at=comment.created_at,
        replies=replies
    )

@router.get("/articles/{article_id}/comments", response_model=List[CommentResponseSchema])
def get_comments(article_id: str, db: Session = Depends(get_db)):
    all_comments = db.query(Comment).filter(Comment.article_id == article_id).all()
    
    # Build a map of parent_id -> list of child comments for fast lookups
    db_comments_map = {}
    roots = []
    for c in all_comments:
        if c.parent_id is None:
            roots.append(c)
        else:
            if c.parent_id not in db_comments_map:
                db_comments_map[c.parent_id] = []
            db_comments_map[c.parent_id].append(c)
            
    # Format recursive threads
    comment_tree = [format_comment_tree(root, db_comments_map) for root in roots]
    return comment_tree

@router.post("/articles/{article_id}/comments", response_model=CommentResponseSchema)
def create_comment(
    article_id: str, 
    payload: CommentCreateSchema, 
    claims: dict = Depends(auth0.require_auth()), 
    db: Session = Depends(get_db)
):
    current_user_id = claims["sub"]
    
    # Verify article exists
    article = db.query(Article).filter(Article.id == article_id).first()
    if not article:
        raise HTTPException(status_code=404, detail="Article not found")
        
    # Auto-create user profile if it doesn't exist in the database yet
    user = db.query(User).filter(User.id == current_user_id).first()
    if not user:
        user = User(
            id=current_user_id,
            email=claims.get("email", "user@example.com"),
            name=claims.get("name") or claims.get("nickname") or "Anonymous Reader",
            tier="FREE"
        )
        db.add(user)
        db.commit()
        db.refresh(user)
        
    comment = Comment(
        id=str(uuid.uuid4()),
        article_id=article_id,
        user_id=current_user_id,
        parent_id=payload.parent_id,
        body=payload.body
    )
    db.add(comment)
    db.commit()
    db.refresh(comment)
    
    return CommentResponseSchema(
        id=comment.id,
        article_id=comment.article_id,
        user_name=user.name or "Anonymous Reader",
        body=comment.body,
        created_at=comment.created_at,
        replies=[]
    )


# --- PAYMENTS (Paytm Integration journey) ---

@router.post("/payments/initiate", response_model=PaymentInitiateResponse)
def initiate_payment(
    payload: PaymentInitiateRequest, 
    current_user_id: str = Depends(get_current_user_id), 
    db: Session = Depends(get_db)
):
    order_id = f"ORDER_{int(datetime.utcnow().timestamp())}"
    amount = 199.0 if payload.tier == "DIGITAL" else 499.0
    
    # Store Transaction in PENDING state
    txn = Transaction(
        order_id=order_id,
        user_id=current_user_id,
        amount=amount,
        tier_purchased=payload.tier,
        status="PENDING"
    )
    db.add(txn)
    db.commit()
    
    # Return mock order information and Paytm transaction token
    return PaymentInitiateResponse(
        orderId=order_id,
        txnToken=f"TXN_TOKEN_{str(uuid.uuid4())[:18].upper()}",
        amount=amount,
        currency="INR"
    )

@router.post("/payments/verify", response_model=UserMeResponse)
def verify_payment(
    payload: PaymentVerifyRequest, 
    current_user_id: str = Depends(get_current_user_id), 
    db: Session = Depends(get_db)
):
    txn = db.query(Transaction).filter(Transaction.order_id == payload.orderId).first()
    if not txn:
        raise HTTPException(status_code=404, detail="Transaction order not found")
        
    user = db.query(User).filter(User.id == current_user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User associated with order not found")
        
    if payload.status == "SUCCESS":
        txn.status = "SUCCESS"
        txn.paytm_transaction_id = payload.paytmTxnId
        user.tier = txn.tier_purchased
        db.commit()
        db.refresh(user)
    else:
        txn.status = "FAILED"
        db.commit()
        
    return user


# --- ANALYTICS (Telemetry journey) ---

@router.post("/analytics/reads", status_code=201)
def track_read_telemetry(
    payload: ReadTelemetryRequest, 
    current_user_id: str = Depends(get_current_user_id), 
    db: Session = Depends(get_db)
):
    is_completed = payload.max_scroll_percentage >= 90 and payload.time_spent_seconds >= 60
    
    analytics = AnalyticsRead(
        id=str(uuid.uuid4()),
        article_id=payload.article_id,
        user_id=current_user_id,
        time_spent_seconds=payload.time_spent_seconds,
        max_scroll_percentage=payload.max_scroll_percentage,
        is_completed=is_completed
    )
    db.add(analytics)
    db.commit()
    return {"status": "success", "is_completed": is_completed}


# --- INTERACTIVE SEARCH & AUTHORS ---

@router.get("/search", response_model=SearchResultsResponse)
def global_search(q: str = Query(..., min_length=1), db: Session = Depends(get_db)):
    # 1. Search Articles (matching title, category, or body content)
    matched_articles = db.query(Article).filter(
        Article.title.ilike(f"%{q}%") | 
        Article.category.ilike(f"%{q}%") | 
        Article.body.ilike(f"%{q}%")
    ).all()
    
    # 2. Search Authors
    matched_authors = db.query(Author).filter(
        Author.name.ilike(f"%{q}%") | 
        Author.title.ilike(f"%{q}%")
    ).all()
    
    # 3. Search Tags
    matched_tags = db.query(Tag).filter(
        Tag.name.ilike(f"%{q}%")
    ).all()
    
    return SearchResultsResponse(
        articles=[ArticleSchema.from_orm_model(a) for a in matched_articles],
        authors=[AuthorSchema.from_orm_model(a) for a in matched_authors],
        tags=[t.name for t in matched_tags]
    )

@router.get("/authors/{author_id}", response_model=AuthorSchema)
def get_author(author_id: str, db: Session = Depends(get_db)):
    author = db.query(Author).filter(Author.id == author_id).first()
    if not author:
        raise HTTPException(status_code=404, detail="Author profile not found")
    return AuthorSchema.from_orm_model(author)

@router.get("/authors/{author_id}/articles", response_model=List[ArticleSchema])
def get_author_articles(
    author_id: str,
    skip: int = 0,
    limit: int = 10,
    db: Session = Depends(get_db)
):
    articles = db.query(Article).filter(Article.author_id == author_id)\
        .order_by(Article.published_at.desc())\
        .offset(skip).limit(limit).all()
    return [ArticleSchema.from_orm_model(a) for a in articles]
