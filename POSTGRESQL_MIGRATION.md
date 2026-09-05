# Banana Ganrajya — PostgreSQL & CockroachDB Database Migration Blueprint

This document serves as the operational guide and technical record for the complete migration of **Banana Ganrajya**'s relational database from local SQLite (`banana.db`) to a production-grade remote PostgreSQL-compatible CockroachDB cluster (`tpdb`).

---

## 🏛️ System Architecture Layout (Migrated)

```
                 +----------------------------------------+
                 |            Auth0 Tenant                |
                 |  (dev-3pc3mxrpo2gnszza.us.auth0.com)   |
                 +--------------------+-------------------+
                                      ^
         1. Native Web Auth           |  2. Token Verification
         & Custom Scheme Callback     |  (JWKS Signatures)
                                      v
+------------------------+      HTTP Requests      +-----------------------+
|     Flutter Client     |------------------------>|    FastAPI Backend    |
|   (com.cyto.banana)  |<------------------------|   (banana-api:8000) |
+------------------------+      JSON Response      +-----------+-----------+
                                                               |
                                                               | 3. Relational Queries
                                                               | (SQLAlchemy + Cockroach Dialect)
                                                               v
                                                   +-----------------------+
                                                   |  Remote CockroachDB   |
                                                   |      ("tpdb" on       |
                                                   |    Cockroach Cloud)   |
                                                   +-----------------------+
```

---

## 🏗️ Technical Implementation Summary

### 1. Database Driver & Dialect Support
To support high-reliability communication with a secure CockroachDB Cloud cluster while remaining fully compatible with the standard PostgreSQL wire-protocol, we integrated:
*   **`psycopg2-binary`**: The standard PostgreSQL adapter for Python.
*   **`sqlalchemy-cockroachdb`**: The official SQLAlchemy dialect for CockroachDB. This dialect natively handles CockroachDB's custom version parsing formats (preventing connection assertions on server startup or during migrations), resolves transactional retry logic, and manages CockroachDB-specific DDL syntax perfectly.

### 2. Zero-Config Dialect Normalization (`app/core/config.py`)
To prevent configuration mismatches and allow seamless switching of standard PostgreSQL database connections, the backend automatically normalizes the prefix protocol:
```python
# Automatically rewrite postgresql:// to cockroachdb:// if connecting to CockroachDB to use the correct SQLAlchemy dialect
if settings.DATABASE_URL.startswith("postgresql://"):
    settings.DATABASE_URL = settings.DATABASE_URL.replace("postgresql://", "cockroachdb://", 1)
elif settings.DATABASE_URL.startswith("postgresql+psycopg2://"):
    settings.DATABASE_URL = settings.DATABASE_URL.replace("postgresql+psycopg2://", "cockroachdb://", 1)
```
This elegant post-instantiation normalizer interceptor transforms incoming `DATABASE_URL` values on-the-fly, so any backend module or Alembic migration using `settings.DATABASE_URL` connects with the optimal CockroachDB engine.

---

## 🛠️ Relational Migration Playbook

### Step 1: Initialize Database Schema on Remote Cluster
By running the Alembic migration suite inside the backend environment, SQLAlchemy and Alembic automatically map your declarative schemas to the remote CockroachDB cluster:
```bash
cd backend
.venv\Scripts\alembic upgrade head
```
*Output Confirmation:*
```text
INFO  [alembic.runtime.migration] Context impl CockroachDBImpl.
INFO  [alembic.runtime.migration] Will assume non-transactional DDL.
INFO  [alembic.runtime.migration] Running upgrade  -> 99eaa03f8ee6, Initial schema setup
INFO  [alembic.runtime.migration] Running upgrade 99eaa03f8ee6 -> 6f46fdb3823d, Add audio_s3_key to Article
INFO  [alembic.runtime.migration] Running upgrade 6f46fdb3823d -> 56a7a8ec18f7, Add UploadedAsset table
```

### Step 2: Extract & Sync SQLite Data to Remote Cluster
Because manual database dumps can break due to differences between SQLite types and PostgreSQL types (e.g., SQLite datetime formats versus Postgres TIMESTAMPTZ), we engineered an automated, type-safe data migration utility: **`migrate_sqlite_to_remote.py`**.

This Python utility reads raw SQLite data, instantiates clean SQLAlchemy model instances, and commits them to the remote database session while respecting strict relational constraints:
1.  **Independent Nodes first:** Migrates `tags`, `authors`, `users`, and `uploaded_assets`.
2.  **Child Nodes next:** Migrates `articles` (linking to `authors.id`).
3.  **Associations and Extensions:** Migrates `article_tags` joins and standard `bookmarks`, `transactions`, and `analytics_reads` schemas.
4.  **Hierarchical Resolution (Hierarchical Comments):** Employs a **two-pass insertion** for comment trees—Pass 1 writes top-level parent comments (`parent_id IS NULL`), and Pass 2 writes child comment responses (`parent_id IS NOT NULL`), perfectly resolving self-referential foreign key constraints.

Execute this data migration using:
```bash
cd backend
.venv\Scripts\python.exe migrate_sqlite_to_remote.py
```

---

## 🔬 Database Diagnostics and Audits
To inspect and confirm your database integrity, two standalone audit utilities have been included in the backend repository:

### 1. SQLite Local Diagnostic Audit
Displays the structure, columns, types, and primary keys for local SQLite tables:
```bash
cd backend
.venv\Scripts\python.exe diagnose_sqlite.py
```

### 2. Remote PostgreSQL/CockroachDB Diagnostic Audit
Displays connection stats, structures, and precise row counts for your remote production schema:
```bash
cd backend
.venv\Scripts\python.exe diagnose_remote.py
```

*Expected Verification Output:*
```text
=== Remote Database Diagnostic Report ===
Connecting to: pav-bhaji-19060.jxf.gcp-asia-south1.cockroachlabs.cloud:26257/tpdb?sslmode=verify-full (sensitive details hidden)

Found 11 tables:

Table: alembic_version
  Row Count: 1
  Columns: version_num VARCHAR(32)
--------------------------------------------------
Table: authors
  Row Count: 10
  Columns: id VARCHAR(100), name VARCHAR(255), title VARCHAR(100), bio VARCHAR, avatar_s3_key VARCHAR, created_at TIMESTAMP, updated_at TIMESTAMP
--------------------------------------------------
Table: tags
  Row Count: 9
  Columns: id INTEGER, name VARCHAR(50)
--------------------------------------------------
Table: users
  Row Count: 2
  Columns: id VARCHAR(128), email VARCHAR(255), name VARCHAR(255), tier VARCHAR(50), subscription_expires_at TIMESTAMP, created_at TIMESTAMP, updated_at TIMESTAMP
...
```

---

## 🔄 Future Database Upgrades (Development Flow)
If you add new fields, columns, or tables to `backend/app/db/models.py` in the future:
1.  Generate an auto-migration script locally:
    ```bash
    cd backend
    .venv\Scripts\alembic revision --autogenerate -m "Add descriptive name here"
    ```
2.  Apply the changes to your production PostgreSQL/CockroachDB server:
    ```bash
    .venv\Scripts\alembic upgrade head
    ```
