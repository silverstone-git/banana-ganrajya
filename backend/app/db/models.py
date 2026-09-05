import uuid
from datetime import datetime
from sqlalchemy import Column, String, Integer, Boolean, Float, DateTime, ForeignKey, Table, Enum
from sqlalchemy.orm import relationship
from app.db.database import Base

# Association table for Article Tags (Interactive Global Search journey)
article_tags = Table(
    "article_tags",
    Base.metadata,
    Column("article_id", String(100), ForeignKey("articles.id", ondelete="CASCADE"), primary_key=True),
    Column("tag_id", Integer, ForeignKey("tags.id", ondelete="CASCADE"), primary_key=True),
)

class Tag(Base):
    __tablename__ = "tags"
    
    id = Column(Integer, primary_key=True, autoincrement=True)
    name = Column(String(50), unique=True, nullable=False, index=True)

class User(Base):
    __tablename__ = "users"
    
    id = Column(String(128), primary_key=True)  # Maps to Auth0 'sub'
    email = Column(String(255), unique=True, nullable=False, index=True)
    name = Column(String(255), nullable=True)
    tier = Column(String(50), default="FREE")  # FREE, DIGITAL, PATRON
    subscription_expires_at = Column(DateTime, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    bookmarks = relationship("Bookmark", back_populates="user", cascade="all, delete-orphan")
    comments = relationship("Comment", back_populates="user", cascade="all, delete-orphan")
    transactions = relationship("Transaction", back_populates="user", cascade="all, delete-orphan")

class Author(Base):
    __tablename__ = "authors"
    
    id = Column(String(100), primary_key=True, default=lambda: str(uuid.uuid4()))
    name = Column(String(255), nullable=False, index=True)
    title = Column(String(100), nullable=False)
    bio = Column(String, nullable=True)
    avatar_s3_key = Column(String, nullable=False)  # Stored as URL/S3 key
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    articles = relationship("Article", back_populates="author")

class Article(Base):
    __tablename__ = "articles"
    
    id = Column(String(100), primary_key=True)  # 'hero-1', 'gr-1'
    category = Column(String(100), nullable=False, index=True)
    title = Column(String(500), nullable=False)
    excerpt = Column(String, nullable=True)
    body = Column(String, nullable=False)
    cover_image_s3_key = Column(String, nullable=False)
    video_s3_key = Column(String, nullable=True)
    audio_s3_key = Column(String, nullable=True)  # Provision for auto-generated audio S3 key
    author_id = Column(String(100), ForeignKey("authors.id", ondelete="RESTRICT"), nullable=False, index=True)
    read_time_minutes = Column(Integer, default=5)
    time_ago = Column(String(100), nullable=True)  # "2 hours ago", "Yesterday"
    is_premium = Column(Boolean, default=False, index=True)
    is_locked = Column(Boolean, default=False, index=True)
    published_at = Column(DateTime, default=datetime.utcnow, index=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    author = relationship("Author", back_populates="articles")
    bookmarks = relationship("Bookmark", back_populates="article", cascade="all, delete-orphan")
    comments = relationship("Comment", back_populates="article", cascade="all, delete-orphan")
    tags = relationship("Tag", secondary=article_tags, backref="articles")

class Bookmark(Base):
    __tablename__ = "bookmarks"
    
    user_id = Column(String(128), ForeignKey("users.id", ondelete="CASCADE"), primary_key=True)
    article_id = Column(String(100), ForeignKey("articles.id", ondelete="CASCADE"), primary_key=True)
    created_at = Column(DateTime, default=datetime.utcnow)

    user = relationship("User", back_populates="bookmarks")
    article = relationship("Article", back_populates="bookmarks")

class Comment(Base):
    __tablename__ = "comments"
    
    id = Column(String(100), primary_key=True, default=lambda: str(uuid.uuid4()))
    article_id = Column(String(100), ForeignKey("articles.id", ondelete="CASCADE"), nullable=False, index=True)
    user_id = Column(String(128), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    parent_id = Column(String(100), ForeignKey("comments.id", ondelete="CASCADE"), nullable=True, index=True)
    body = Column(String, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    user = relationship("User", back_populates="comments")
    article = relationship("Article", back_populates="comments")
    # Self-referential relationship for threaded comments (replies)
    parent = relationship("Comment", remote_side=[id], back_populates="replies")
    replies = relationship("Comment", back_populates="parent", cascade="all, delete-orphan")

class Transaction(Base):
    __tablename__ = "transactions"
    
    order_id = Column(String(100), primary_key=True)
    user_id = Column(String(128), ForeignKey("users.id", ondelete="RESTRICT"), nullable=False, index=True)
    amount = Column(Float, nullable=False)
    currency = Column(String(3), default="INR")
    tier_purchased = Column(String(50), nullable=False)  # DIGITAL, PATRON
    status = Column(String(50), default="PENDING", index=True)  # PENDING, SUCCESS, FAILED, REFUNDED
    paytm_transaction_id = Column(String(255), nullable=True)
    paytm_response_msg = Column(String, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    user = relationship("User", back_populates="transactions")

class AnalyticsRead(Base):
    __tablename__ = "analytics_reads"
    
    id = Column(String(100), primary_key=True, default=lambda: str(uuid.uuid4()))
    article_id = Column(String(100), ForeignKey("articles.id", ondelete="CASCADE"), nullable=False, index=True)
    user_id = Column(String(128), ForeignKey("users.id", ondelete="SET NULL"), nullable=True)
    time_spent_seconds = Column(Integer, default=0)
    max_scroll_percentage = Column(Integer, default=0)
    is_completed = Column(Boolean, default=False, index=True)
    created_at = Column(DateTime, default=datetime.utcnow)

class UploadedAsset(Base):
    __tablename__ = "uploaded_assets"

    id = Column(String(100), primary_key=True, default=lambda: str(uuid.uuid4()))
    key = Column(String(255), nullable=False, unique=True, index=True)
    mimetype = Column(String(100), nullable=False)
    category = Column(String(100), nullable=False, index=True)  # 'article_audio', 'cover_image', 'video'
    size_bytes = Column(Integer, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow, index=True)
