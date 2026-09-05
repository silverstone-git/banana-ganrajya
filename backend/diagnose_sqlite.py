import sqlite3

def diagnose():
    db_path = "banana.db"
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    
    # Get all tables
    cursor.execute("SELECT name FROM sqlite_master WHERE type='table';")
    tables = [row[0] for row in cursor.fetchall()]
    
    print("=== SQLite Diagnostic Report ===")
    print(f"Database: {db_path}")
    print(f"Found {len(tables)} tables:\n")
    
    for table in tables:
        if table.startswith("sqlite_"):
            continue
            
        # Get count
        cursor.execute(f"SELECT COUNT(*) FROM [{table}];")
        count = cursor.fetchone()[0]
        
        # Get schema details
        cursor.execute(f"PRAGMA table_info([{table}]);")
        columns = cursor.fetchall()
        col_desc = []
        for col in columns:
            col_id, col_name, col_type, notnull, dflt_value, pk = col
            pk_str = " (PK)" if pk else ""
            col_desc.append(f"{col_name} {col_type}{pk_str}")
            
        print(f"Table: {table}")
        print(f"  Row Count: {count}")
        print(f"  Columns: {', '.join(col_desc)}")
        print("-" * 50)
        
    conn.close()

if __name__ == "__main__":
    diagnose()
