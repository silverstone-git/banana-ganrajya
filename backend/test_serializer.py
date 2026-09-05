import sys
import os

# Ensure the backend directory is in the Python path
sys.path.insert(0, os.path.abspath(os.path.dirname(__file__)))

from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from app.core.config import settings
from app.db.models import Article
from app.schemas.article import ArticleSchema

def test_serializer():
    db_url = settings.DATABASE_URL
    engine = create_engine(db_url)
    Session = sessionmaker(bind=engine)
    db = Session()
    
    article = db.query(Article).filter(Article.id == "hero-1").first()
    schema = ArticleSchema.from_orm_model(article)
    print("\nSerialized JSON Dump:")
    print(schema.model_dump())
    
    db.close()

if __name__ == "__main__":
    test_serializer()
