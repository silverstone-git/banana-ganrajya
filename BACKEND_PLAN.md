# Banana Ganrajya — Backend Architecture Plan (FastAPI)

This document defines the architecture, tools, and endpoints for building a robust, scalable backend using Python and **FastAPI**.

---

## 🌟 Milestone 1 Implementation Status: COMPLETE

As of Checkpoint 1, the core architecture plan has been **successfully fully implemented** and verified locally and inside Docker containerization:

*   **FastAPI REST Engine**: Complete with modular routers, Pydantic settings loading from dual directory contexts (`.env` and `../.env`), and automatic OpenAPI docs.
*   **SQLAlchemy 2.0 ORM & SQLite Schema**: Implemented the complete normalized schema in `backend/app/db/models.py` including Users, Authors, Articles, Comments, Bookmarks, and Transactions.
*   **Production PostgreSQL & CockroachDB Migration**: Successfully transitioned the relational storage engine from a local SQLite setup to a high-availability remote PostgreSQL/CockroachDB cloud database (`tpdb`).
*   **Zero-Config Dialect Normalization**: Integrated dynamic database URL normalization on FastAPI configuration boot, automatically mapping `postgresql://` inputs to optimized CockroachDB dialects (`cockroachdb://` via `sqlalchemy-cockroachdb`).
*   **Constraint-Safe Data Migration**: Engineered an automated data migration pipeline (`migrate_sqlite_to_remote.py`) to safely replicate local records directly to the cloud instance, completely preserving foreign keys and self-referential nested comment reply scopes.
*   **Alembic Migrations**: Fully initialized and applied schemas successfully to create database structures across both SQLite and remote CockroachDB/PostgreSQL environments.
*   **High-Fidelity Database Seeding**: Pre-loaded the active databases with actual news, categories, tags, columnists, and threaded discussion records matching original Stitch mockup expectations, including a dedicated `breaking-1` breaking news ticker click-through.
*   **Auth0 JWT Validator Protection**: Custom integrated the official `auth0-fastapi-api` (`fastapi_plugin`) SDK to secure all write-based and user-profile endpoints against your live tenant, dynamically parsing the token signature, expiration, and OIDC `sub` claims.
*   **Explicit CORS Security**: Configured secure Allowed Origins whitelists preventing wildcard preflight blockages on browser engines.
*   **Docker Containerization**: Delivered a multi-stage Dockerfile and docker-compose volume mounts. Fixed hidden Unix LF line endings (`start.sh`) for flawless Linux runtime compilation.

---

## 1. Core Architecture Stack
* **Framework:** FastAPI (High performance, async-native, automatic OpenAPI documentation).
* **Database ORM:** SQLAlchemy 2.0 (supports both sync and async modes) or SQLModel.
* **Database Driver:** `psycopg2-binary` (via `sqlalchemy-cockroachdb` dynamic protocol mapping to support CockroachDB & PostgreSQL).
* **Data Validation:** Pydantic V2.
* **Authentication:** JWT Bearer Token validation (verifying Auth0 signatures).
* **Cloud Storage:** AWS S3 (via `boto3` for generating presigned URLs).
* **Caching Layer:** Redis (used to cache hot endpoints like feeds, author articles, and comments).

## 2. Project Structure
A scalable, modular directory structure:
```text
backend/
├── app/
│   ├── api/
│   │   ├── dependencies.py    # Auth, DB sessions, Redis connection
│   │   ├── routers/           # Endpoint definitions (articles, users, payments, comments, analytics, authors, search)
│   ├── core/
│   │   ├── config.py          # Pydantic BaseSettings (Env vars)
│   │   ├── security.py        # Auth0 token verification logic
│   ├── db/
│   │   ├── database.py        # Engine and session maker
│   │   ├── models.py          # SQLAlchemy ORM models
│   ├── schemas/               # Pydantic models (Requests/Responses)
│   ├── services/              # Business logic (S3 URL generation, Paytm logic, Analytics parser, Redis service)
│   └── main.py                # FastAPI application instance
├── requirements.txt
└── Dockerfile
```

## 3. Core Modules & Endpoints

### A. Authentication & Users
* **Middleware:** An Auth0 JWT validator dependency that intercepts requests, validates the signature against Auth0's JWKS, and extracts the `sub` (User ID).
* **Endpoints:**
  * `GET /users/me` - Fetch profile info and subscription status.
  * `POST /users/sync` - Called after Auth0 login to ensure the user exists in the local database.

### B. Articles & Media (S3)
* **Service:** An S3 service that takes raw S3 object keys from the database and uses `boto3.client('s3').generate_presigned_url()` to return temporary, secure access URLs.
* **Endpoints (Paginated & Cached):**
  * `GET /articles/feed` - Returns a paginated list of articles (images resolved to presigned URLs). **Cached in Redis** with a 5-minute TTL.
  * `GET /articles/{id}` - Returns full article details (images and video keys resolved to presigned URLs). **Cached in Redis** (invalidated on update).

### C. Bookmarks
* **Endpoints:**
  * `GET /bookmarks` - Fetch all bookmarked articles for the authenticated user.
  * `POST /bookmarks/{article_id}` - Add a bookmark (Upsert).
  * `DELETE /bookmarks/{article_id}` - Remove a bookmark.

### D. Payments (Paytm)
* **Flow & Endpoints:**
  * `POST /payments/initiate` - Takes the desired subscription tier. Creates a `Transaction` in the DB with status `PENDING`. Calls Paytm's API to generate a `txnToken`. Returns `orderId` and `txnToken` to Flutter.
  * `POST /payments/webhook` (or Callback) - Receives the server-to-server webhook from Paytm confirming payment success or failure. Updates the DB `Transaction` status and elevates the User's `subscription_tier` accordingly.
  * `POST /payments/verify` - A fallback endpoint for the Flutter app to proactively ask the backend to verify the transaction status with Paytm directly if the webhook is delayed.

### E. Engagement & Discussions (Comments)
* **Endpoints (Paginated & Cached):**
  * `GET /articles/{id}/comments` - Public access retrieval of comments, returning threaded nesting. **Paginated** to limit depth, **Cached in Redis** (invalidated when a new comment is posted).
  * `POST /articles/{id}/comments` - Submit a new comment or nested reply (requires Auth0 token). Invalidates comments cache in Redis.
  * `DELETE /comments/{id}` - Allow authors of comments or administrators to delete a comment. Invalidates comments cache.

### F. Read Telemetry & Analytics
* **Endpoints:**
  * `POST /analytics/reads` - Tracks user read statistics (scroll-milestones, active time duration). Receives event payload and calculates if the user read the full piece. Handles anonymous readers gracefully (User ID is optional).

### G. Authors Profile & Work
* **Endpoints (Paginated & Cached):**
  * `GET /authors/{id}` - Public access metadata endpoint returning name, title, bio, and presigned avatar S3 URLs. **Cached in Redis**.
  * `GET /authors/{id}/articles` - Fetch a **paginated** feed of all articles authored by the journalist, sorted by date. **Cached in Redis** (10-minute TTL, invalidated on new article publication).

### H. Global Search API (New!)
* **Endpoints (Paginated & Cached):**
  * `GET /search` - Ingests a text query string `q` and page offset limits.
  * **Processing:** Uses PostgreSQL's **Full-Text Search** features (such as `tsvector` and `tsquery` over indexes) or Elasticsearch to quickly search and match articles (title, excerpt, body), author names, and tags.
  * **Result payload:** Returns a paginated JSON response splitting matches into categorized lists of Articles, Columnists/Authors, and Topics/Tags.
  * **Caching:** Results for common search queries are cached in Redis with a 2-minute TTL.

## 4. Scalability & Robustness Considerations
* **Pagination Design:** All list endpoints (Feeds, Comments, Author Articles, Search Results) strictly enforce limit-offset or cursor-based pagination parameters to guarantee constant-time database processing regardless of growth scale.
* **Caching Strategy (Redis):** Standardizes Redis caching for high-load list endpoints. Caches are stored as JSON payloads and automatically invalidated upon write triggers (e.g., new article publish, new comment post) to maintain absolute freshness while bypassing unnecessary DB hits.
* **Async Everything:** Ensure all DB queries, external API calls (Paytm), and S3 client calls are fully asynchronous to prevent blocking the event loop.
* **Database Migrations:** Use **Alembic** to manage database schema changes over time securely across SQLite, PostgreSQL, and CockroachDB backends.
* **Environment Configuration:** Strict enforcement of `.env` variables via `pydantic-settings` (Paytm Merchant Keys, Auth0 Domain, AWS Credentials, DB URI).
* **Error Handling:** Implement global exception handlers for standardized JSON error responses.
