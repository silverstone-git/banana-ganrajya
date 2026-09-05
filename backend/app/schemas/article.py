from pydantic import BaseModel
from typing import Optional, List, Dict
from datetime import datetime

class AuthorSchema(BaseModel):
    id: str
    name: str
    title: str
    bio: Optional[str] = None
    avatar_url: str

    class Config:
        from_attributes = True

    @classmethod
    def from_orm_model(cls, obj):
        return cls(
            id=obj.id,
            name=obj.name,
            title=obj.title,
            bio=obj.bio,
            avatar_url=obj.avatar_s3_key
        )

class ArticleSchema(BaseModel):
    id: str
    category: str
    title: str
    excerpt: Optional[str] = None
    body: str
    imageUrl: str
    author: str
    authorId: str  # Add authorId directly to the schema
    readTime: Optional[str] = None
    timeAgo: Optional[str] = None
    isPremium: bool
    isLocked: bool
    published_at: datetime
    audioUrl: Optional[str] = None
    authorAvatarUrl: Optional[str] = None

    class Config:
        from_attributes = True

    @classmethod
    def from_orm_model(cls, obj):
        # Resolve read time string
        read_time_str = None
        if obj.read_time_minutes:
            read_time_str = f"{obj.read_time_minutes} mins read" if obj.read_time_minutes > 1 else "1 min read"

        # Resolve author display string
        author_name = obj.author.name if obj.author else "Banana Ganrajya Team"
        if author_name not in ["Banana Ganrajya Team"] and not author_name.startswith("By "):
            author_str = f"By {author_name}"
        else:
            author_str = author_name

        # Resolve full S3 audio URL with dynamic, on-the-fly secure pre-signing
        audio_url = None
        s3_key = getattr(obj, "audio_s3_key", None)
        if s3_key:
            import re
            # If it's a full URL containing pre-signed query args, extract just the clean key
            if "audio/" in s3_key:
                match = re.search(r'(audio/[^?]+)', s3_key)
                if match:
                    s3_key = match.group(1)
            
            if s3_key.startswith("audio/"):
                from app.core.config import settings
                import boto3
                from botocore.config import Config
                
                if settings.CLOUDFLARE_ACCESS_KEY_ID and settings.R2_ENDPOINT:
                    try:
                        s3_client = boto3.client(
                            "s3",
                            aws_access_key_id=settings.CLOUDFLARE_ACCESS_KEY_ID,
                            aws_secret_access_key=settings.CLOUDFLARE_SECRET_ACCESS_KEY,
                            region_name=settings.R2_REGION,
                            endpoint_url=settings.R2_ENDPOINT,
                            config=Config(signature_version="s3v4")
                        )
                        # Generate a fresh pre-signed GET URL valid for 2 hours (7200 seconds)
                        audio_url = s3_client.generate_presigned_url(
                            ClientMethod="get_object",
                            Params={
                                "Bucket": settings.R2_BUCKET_NAME,
                                "Key": s3_key,
                            },
                            ExpiresIn=7200
                        )
                    except Exception as e:
                        print(f"[On-the-Fly Signing Failed]: {e}")
                        audio_url = f"https://mock-audio-endpoint.com/{s3_key}"
                else:
                    audio_url = f"https://mock-audio-endpoint.com/{s3_key}"
            else:
                # If it's some other format or public URL, return as is
                audio_url = s3_key

        return cls(
            id=obj.id,
            category=obj.category,
            title=obj.title,
            excerpt=obj.excerpt,
            body=obj.body,
            imageUrl=obj.cover_image_s3_key,
            author=author_str,
            authorId=obj.author_id,  # Map author_id from the SQLAlchemy model
            readTime=read_time_str,
            timeAgo=obj.time_ago,
            isPremium=obj.is_premium,
            isLocked=obj.is_locked,
            published_at=obj.published_at,
            audioUrl=audio_url,
            authorAvatarUrl=obj.author.avatar_s3_key if (obj.author and obj.author.avatar_s3_key) else None
        )

# Feed responses matching Flutter feature integrations
class HomeFeedResponse(BaseModel):
    heroStory: ArticleSchema
    secondaryStories: List[ArticleSchema]
    groundReports: List[ArticleSchema]

class FineprintFeedResponse(BaseModel):
    featured: ArticleSchema
    list: List[ArticleSchema]

class ColumnistGalleryItem(BaseModel):
    name: str
    avatar_url: str
    title: str

class OpinionFeedResponse(BaseModel):
    featured: ArticleSchema
    rows: List[ArticleSchema]
    columnists: List[ColumnistGalleryItem]

# Request schemas for supporting future roadmap steps (Auth, Bookmarks, Comments, etc.)
class CommentResponseSchema(BaseModel):
    id: str
    article_id: str
    user_name: str
    user_avatar: Optional[str] = None
    body: str
    created_at: datetime
    replies: List['CommentResponseSchema'] = []

    class Config:
        from_attributes = True

class CommentCreateSchema(BaseModel):
    body: str
    parent_id: Optional[str] = None

class BookmarkToggleResponse(BaseModel):
    article_id: str
    bookmarked: bool

class SearchResultsResponse(BaseModel):
    articles: List[ArticleSchema]
    authors: List[AuthorSchema]
    tags: List[str]

class UserSyncSchema(BaseModel):
    email: str
    name: Optional[str] = None

class UserMeResponse(BaseModel):
    id: str
    email: str
    name: Optional[str] = None
    tier: str
    subscription_expires_at: Optional[datetime] = None

class PaymentInitiateRequest(BaseModel):
    tier: str  # DIGITAL, PATRON

class PaymentInitiateResponse(BaseModel):
    orderId: str
    txnToken: str
    amount: float
    currency: str

class PaymentVerifyRequest(BaseModel):
    orderId: str
    paytmTxnId: str
    status: str

class ReadTelemetryRequest(BaseModel):
    article_id: str
    time_spent_seconds: int
    max_scroll_percentage: int

class ArticleCreateSchema(BaseModel):
    category: str
    title: str
    excerpt: Optional[str] = None
    body: str
    cover_image_s3_key: str
    author_id: str
    is_premium: Optional[bool] = False

class AppConfigResponse(BaseModel):
    admin_email: str

class AdminConfigResponse(BaseModel):
    admin_api_key: str
