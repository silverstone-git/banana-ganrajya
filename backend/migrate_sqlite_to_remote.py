import sys
import os
from sqlalchemy import create_engine, select, text
from sqlalchemy.orm import sessionmaker

# Add backend directory to Python path
sys.path.insert(0, os.path.abspath(os.path.dirname(__file__)))

from app.core.config import settings
from app.db.database import Base
from app.db import models

def migrate():
    sqlite_url = "sqlite:///banana.db"
    remote_url = settings.DATABASE_URL
    
    print("=== Data Migration Process Started ===")
    print(f"Source SQLite: {sqlite_url}")
    print(f"Target Remote: {remote_url.split('@')[-1] if '@' in remote_url else remote_url} (credentials hidden)\n")
    
    sqlite_engine = create_engine(sqlite_url)
    remote_engine = create_engine(remote_url)
    
    SqliteSession = sessionmaker(bind=sqlite_engine)
    RemoteSession = sessionmaker(bind=remote_engine)
    
    sqlite_session = SqliteSession()
    remote_session = RemoteSession()
    
    try:
        # 1. Migrate Tags
        print("Migrating Table: tags...")
        tags = sqlite_session.query(models.Tag).all()
        for t in tags:
            # Check if tag already exists in remote
            existing = remote_session.query(models.Tag).filter_by(id=t.id).first()
            if not existing:
                new_t = models.Tag(id=t.id, name=t.name)
                remote_session.add(new_t)
        remote_session.commit()
        print(f"  Successfully migrated {len(tags)} tags.")
        
        # 2. Migrate Authors
        print("Migrating Table: authors...")
        authors = sqlite_session.query(models.Author).all()
        for a in authors:
            existing = remote_session.query(models.Author).filter_by(id=a.id).first()
            if not existing:
                new_a = models.Author(
                    id=a.id,
                    name=a.name,
                    title=a.title,
                    bio=a.bio,
                    avatar_s3_key=a.avatar_s3_key,
                    created_at=a.created_at,
                    updated_at=a.updated_at
                )
                remote_session.add(new_a)
        remote_session.commit()
        print(f"  Successfully migrated {len(authors)} authors.")
        
        # 3. Migrate Users
        print("Migrating Table: users...")
        users = sqlite_session.query(models.User).all()
        for u in users:
            existing = remote_session.query(models.User).filter_by(id=u.id).first()
            if not existing:
                new_u = models.User(
                    id=u.id,
                    email=u.email,
                    name=u.name,
                    tier=u.tier,
                    subscription_expires_at=u.subscription_expires_at,
                    created_at=u.created_at,
                    updated_at=u.updated_at
                )
                remote_session.add(new_u)
        remote_session.commit()
        print(f"  Successfully migrated {len(users)} users.")
        
        # 4. Migrate UploadedAssets
        print("Migrating Table: uploaded_assets...")
        assets = sqlite_session.query(models.UploadedAsset).all()
        for ast in assets:
            existing = remote_session.query(models.UploadedAsset).filter_by(id=ast.id).first()
            if not existing:
                new_ast = models.UploadedAsset(
                    id=ast.id,
                    key=ast.key,
                    mimetype=ast.mimetype,
                    category=ast.category,
                    size_bytes=ast.size_bytes,
                    created_at=ast.created_at
                )
                remote_session.add(new_ast)
        remote_session.commit()
        print(f"  Successfully migrated {len(assets)} uploaded assets.")
        
        # 5. Migrate Articles
        print("Migrating Table: articles...")
        articles = sqlite_session.query(models.Article).all()
        for art in articles:
            existing = remote_session.query(models.Article).filter_by(id=art.id).first()
            if not existing:
                new_art = models.Article(
                    id=art.id,
                    category=art.category,
                    title=art.title,
                    excerpt=art.excerpt,
                    body=art.body,
                    cover_image_s3_key=art.cover_image_s3_key,
                    video_s3_key=art.video_s3_key,
                    audio_s3_key=art.audio_s3_key,
                    author_id=art.author_id,
                    read_time_minutes=art.read_time_minutes,
                    time_ago=art.time_ago,
                    is_premium=art.is_premium,
                    is_locked=art.is_locked,
                    published_at=art.published_at,
                    created_at=art.created_at,
                    updated_at=art.updated_at
                )
                remote_session.add(new_art)
        remote_session.commit()
        print(f"  Successfully migrated {len(articles)} articles.")
        
        # 6. Migrate ArticleTags association table
        print("Migrating Table: article_tags...")
        # Since article_tags is a Table object, we select and insert using core SQL expression/statements
        # SQLite raw select
        sqlite_article_tags = sqlite_session.execute(text("SELECT article_id, tag_id FROM article_tags")).fetchall()
        migrated_article_tags_count = 0
        for at in sqlite_article_tags:
            # Check if exists in remote
            existing = remote_session.execute(
                text("SELECT 1 FROM article_tags WHERE article_id = :article_id AND tag_id = :tag_id"),
                {"article_id": at.article_id, "tag_id": at.tag_id}
            ).fetchone()
            if not existing:
                remote_session.execute(
                    text("INSERT INTO article_tags (article_id, tag_id) VALUES (:article_id, :tag_id)"),
                    {"article_id": at.article_id, "tag_id": at.tag_id}
                )
                migrated_article_tags_count += 1
        remote_session.commit()
        print(f"  Successfully migrated {migrated_article_tags_count} article tag associations.")
        
        # 7. Migrate Bookmarks
        print("Migrating Table: bookmarks...")
        bookmarks = sqlite_session.query(models.Bookmark).all()
        for b in bookmarks:
            existing = remote_session.query(models.Bookmark).filter_by(user_id=b.user_id, article_id=b.article_id).first()
            if not existing:
                new_b = models.Bookmark(
                    user_id=b.user_id,
                    article_id=b.article_id,
                    created_at=b.created_at
                )
                remote_session.add(new_b)
        remote_session.commit()
        print(f"  Successfully migrated {len(bookmarks)} bookmarks.")
        
        # 8. Migrate Transactions
        print("Migrating Table: transactions...")
        txs = sqlite_session.query(models.Transaction).all()
        for tx in txs:
            existing = remote_session.query(models.Transaction).filter_by(order_id=tx.order_id).first()
            if not existing:
                new_tx = models.Transaction(
                    order_id=tx.order_id,
                    user_id=tx.user_id,
                    amount=tx.amount,
                    currency=tx.currency,
                    tier_purchased=tx.tier_purchased,
                    status=tx.status,
                    paytm_transaction_id=tx.paytm_transaction_id,
                    paytm_response_msg=tx.paytm_response_msg,
                    created_at=tx.created_at,
                    updated_at=tx.updated_at
                )
                remote_session.add(new_tx)
        remote_session.commit()
        print(f"  Successfully migrated {len(txs)} transactions.")
        
        # 9. Migrate AnalyticsReads
        print("Migrating Table: analytics_reads...")
        reads = sqlite_session.query(models.AnalyticsRead).all()
        for r in reads:
            existing = remote_session.query(models.AnalyticsRead).filter_by(id=r.id).first()
            if not existing:
                new_r = models.AnalyticsRead(
                    id=r.id,
                    article_id=r.article_id,
                    user_id=r.user_id,
                    time_spent_seconds=r.time_spent_seconds,
                    max_scroll_percentage=r.max_scroll_percentage,
                    is_completed=r.is_completed,
                    created_at=r.created_at
                )
                remote_session.add(new_r)
        remote_session.commit()
        print(f"  Successfully migrated {len(reads)} analytics reads.")
        
        # 10. Migrate Comments
        print("Migrating Table: comments...")
        # We migrate comments in two passes to satisfy self-referential parent_id constraints
        comments = sqlite_session.query(models.Comment).all()
        
        # Pass 1: Comments with parent_id as None
        pass1_count = 0
        for c in comments:
            if c.parent_id is None:
                existing = remote_session.query(models.Comment).filter_by(id=c.id).first()
                if not existing:
                    new_c = models.Comment(
                        id=c.id,
                        article_id=c.article_id,
                        user_id=c.user_id,
                        parent_id=None,
                        body=c.body,
                        created_at=c.created_at,
                        updated_at=c.updated_at
                    )
                    remote_session.add(new_c)
                    pass1_count += 1
        remote_session.commit()
        
        # Pass 2: Comments with parent_id NOT None
        pass2_count = 0
        for c in comments:
            if c.parent_id is not None:
                existing = remote_session.query(models.Comment).filter_by(id=c.id).first()
                if not existing:
                    new_c = models.Comment(
                        id=c.id,
                        article_id=c.article_id,
                        user_id=c.user_id,
                        parent_id=c.parent_id,
                        body=c.body,
                        created_at=c.created_at,
                        updated_at=c.updated_at
                    )
                    remote_session.add(new_c)
                    pass2_count += 1
        remote_session.commit()
        
        print(f"  Successfully migrated {len(comments)} comments (Pass 1: {pass1_count}, Pass 2: {pass2_count}).")
        
        print("\n=== Data Migration Completed Successfully! ===")
        
    except Exception as e:
        print(f"\n[ERROR] Migration failed: {e}")
        remote_session.rollback()
        raise e
    finally:
        sqlite_session.close()
        remote_session.close()

if __name__ == "__main__":
    migrate()
