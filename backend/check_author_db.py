import sys
import os

# Ensure the backend directory is in the Python path
sys.path.insert(0, os.path.abspath(os.path.dirname(__file__)))

from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from app.core.config import settings
from app.db.models import Author, Article

def check_db():
    db_url = settings.DATABASE_URL
    print(f"Connecting to: {db_url.split('@')[-1] if '@' in db_url else db_url}")
    
    engine = create_engine(db_url)
    Session = sessionmaker(bind=engine)
    db = Session()
    
    print("\n=== AUTHORS ===")
    authors = db.query(Author).all()
    for a in authors:
        print(f"ID: {a.id} | Name: {a.name} | Avatar Key: {a.avatar_s3_key}")
        
    print("\n=== ARTICLES & AUTHORS ===")
    articles = db.query(Article).all()
    for art in articles:
        print(f"Article ID: {art.id} | Title: {art.title[:30]} | Author ID: {art.author_id} | Author Name in Db: {art.author.name if art.author else 'None'}")
        
    db.close()

if __name__ == "__main__":
    check_db()
