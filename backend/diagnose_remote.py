import sys
import os

# Ensure the backend directory is in the Python path
sys.path.insert(0, os.path.abspath(os.path.dirname(__file__)))

from sqlalchemy import create_engine, inspect, text
from app.core.config import settings

def diagnose_remote():
    url = settings.DATABASE_URL
    print("=== Remote Database Diagnostic Report ===")
    print(f"Connecting to: {url.split('@')[-1] if '@' in url else url} (sensitive details hidden)\n")
    
    engine = create_engine(url)
    inspector = inspect(engine)
    
    tables = inspector.get_table_names()
    print(f"Found {len(tables)} tables:\n")
    
    with engine.connect() as conn:
        for table in tables:
            # Get count of rows
            try:
                res = conn.execute(text(f"SELECT COUNT(*) FROM \"{table}\";"))
                count = res.scalar()
            except Exception as e:
                count = f"ERROR: {e}"
                
            # Get columns
            columns = inspector.get_columns(table)
            col_desc = []
            for col in columns:
                col_name = col['name']
                col_type = col['type']
                pk = 1 if col.get('primary_key') else 0
                pk_str = " (PK)" if pk else ""
                col_desc.append(f"{col_name} {col_type}{pk_str}")
                
            print(f"Table: {table}")
            print(f"  Row Count: {count}")
            print(f"  Columns: {', '.join(col_desc)}")
            print("-" * 50)

if __name__ == "__main__":
    diagnose_remote()
