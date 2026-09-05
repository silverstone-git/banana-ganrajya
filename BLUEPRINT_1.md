# Banana Ganrajya — Checkpoint 1: Backend Architecture & Auth0 Identity Integration Blueprint

This document serves as the architectural blueprint and retrospective for **Checkpoint 1** of Banana Ganrajya news application. It chronicles the transition from a static Flutter mock prototype to a fully dynamic, relational, and authenticated news platform powered by a FastAPI backend, an SQLite database (configured for PostgreSQL), and Auth0 Identity services.

---

## 🏛️ System Architecture Layout

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
                                                               | (SQLAlchemy ORM)
                                                               v
                                                   +-----------------------+
                                                   |  Remote CockroachDB/  |
                                                   |      PostgreSQL       |
                                                   |    ("tpdb" Cloud)     |
                                                   +-----------------------+
```

---

## 🏗️ What We Set Up (Infrastructure)

1. **FastAPI REST API Server (`backend/app/`)**:
   * Engineered a robust Python-based API server structured around Modular Routers, Pydantic validation schemas, and database session injections.
   * Installed a dynamic `pydantic-settings` configuration loader capable of traversing folder directories to parse `.env` credentials in both local runtimes and container contexts.

2. **SQLAlchemy 2.0, PostgreSQL & CockroachDB Data Repository**:
   * Architected a fully normalized database schema mapping the domain requirements outlined in `DATABASE_SQL_ENTITIES_PLAN.md` to production-grade declarative ORM models.
   * Transitioned relational storage seamlessly from a local SQLite setup to a remote PostgreSQL-compatible CockroachDB cloud database.
   * Integrated `psycopg2-binary` and `sqlalchemy-cockroachdb` dialects with a dynamic connection scheme normalizer, mapping `postgresql://` strings automatically to `cockroachdb://` protocols for error-free connection handling on app-boot.
   * Created a constraints-aware data migration script (`migrate_sqlite_to_remote.py`) that successfully syncs tables, bookmarks, assets, and self-referencing comment trees from SQLite to the cloud with full type safety.
   * Established migrations management with **Alembic**, generating and executing database schemas dynamically across local and production targets.
   * Created a database seeding script (`backend/app/seed.py`) containing the transcribed high-fidelity mock data from original Stitch mockups.

3. **Docker Containerization Layer**:
   * Built a **multi-stage, lightweight Dockerfile** separating compiler builds from the runtime stage (reducing the final deployment image size).
   * Scripted an automated production entrypoint (`start.sh`) that safely applies Alembic migrations, runs database checks, seeds records, and launches Uvicorn on container boot.
   * Delivered `docker-compose.yml` defining volume mounts for SQLite data persistence and root `.env` variable ingestion.

---

## 💡 What We Improvised & Adapted

1. **Instant Mobile Redirect Interception (Custom Schemes over HTTPS App Links)**:
   * *The Problem*: Configuring standard HTTPS callback redirects requires hosting a cryptographically verified `assetlinks.json` (Android) or `apple-app-site-association` (iOS) file on your Auth0 domain. Without it, redirects fail, throwing a web-browser 404 "Not Found."
   * *The Improvisation*: We adapted Android and iOS platforms to utilize custom URL protocols (`com.cyto.banana://`). Android registers `com.cyto.banana` inside its manifest redirect Activity, enabling **immediate, secure browser-to-app redirects locally on the device** without requiring any external domain verifications.

2. **Programmatic ngrok Bypass Header (`ngrok-skip-browser-warning`)**:
   * *The Problem*: ngrok's free tier intercepts raw HTTP calls with a browser warning landing page, which blocks programmatic JSON parsers like `Dio` from resolving payloads.
   * *The Improvisation*: Configured a global request interceptor in Dio to automatically attach the `'ngrok-skip-browser-warning': 'true'` header, instantly bypassing the interstitial page and allowing smooth API communication.

3. **FastAPI-to-Dart camelCase Serialization Alignment**:
   * *The Problem*: FastAPI's Pydantic model serialization defaults to utilizing snake_case/aliased database fields (`cover_image_s3_key`, `is_premium`) during REST outputs, causing a `TypeError: Null is not a subtype of String` in Dart's strict parser.
   * *The Improvisation*: Standardized the backend schema responses directly to camelCase fields (`imageUrl`, `isPremium`, `isLocked`), eliminating alias discrepancies and aligning payloads with Dart's `Article.fromJson` constructors.

4. **Self-Referential Relational Comment Trees**:
   * *The Problem*: Threaded article comments require infinite nested reply capability, which can cause recursive cascade delete loops in standard relational configurations.
   * *The Improvisation*: Configured a highly clean self-referential relationship utilizing SQLAlchemy's modern `back_populates` and explicit `remote_side` bounds, allowing clean, threaded response payloads.

---

## 🔄 What We Changed (Flutter Frontend)

1. **Platform Identity Migration**:
   * Systematically renamed the application's package name and product bundle identifier from `com.example.banana` to **`com.cyto.banana`** across Android Gradle build scopes, Kotlin MainActivity namespaces, iOS project configuration plists, and macOS/Linux compilers.

2. **From Static Mocks to Reactive Riverpod Streams**:
   * Converted hardcoded views (HomeScreen, FinePrintScreen, OpinionScreen, PoliticsScreen) into **ConsumerWidgets** watching asynchronous FutureProviders:
     * `homeFeedProvider`: Bundles hero, secondary, and ground report feeds.
     * `fineprintFeedProvider`: Manages exclusive investigative feeds and sub headers.
     * `opinionFeedProvider`: Delivers columns and populates the dynamic columnist row gallery.
     * `politicsArticlesProvider`: Directs query parameters dynamically to filter the politics catalog.
     * `articleDetailProvider(id)`: Parameterized family provider returning individual article contents.

3. **Interactive settings Profile Card**:
   * Developed a state-aware `authProvider` powered by Riverpod and the native `CredentialsManager`.
   * When authenticated via Auth0, the app renders a high-fidelity subscriber profile card displaying the user's Auth0 photo, full name, email address, and a premium "SUBSCRIBER" badge.
   * When unauthenticated, the app displays a call-to-action encouraging the reader to sign in.

---

## 📝 Checkpoint Lessons Learned

* **Riverpod Build Scope Protection**: Attempting to mutate `state` asynchronously inside a Notifier's synchronous `build()` block throws an `uninitialized provider` crash because the provider has not completed registration. Always defer startup mutations using **`Future.microtask(...)`** to schedule executions on the next event loop tick.
* **Android Sockets Autonomy**: Physical Android devices block programmatic TCP connections by default. Declaring the explicit `<uses-permission android:name="android.permission.INTERNET" />` tag in the main manifest is mandatory to allow network handshakes in release compilations.
* **PKCE Native Security Best Practices**: Mobile clients should never carry Client Secrets. The PKCE flow secures native mobile logins using cryptographically ephemeral code verifiers, enabling stateless REST architectures.

---

## 📈 Next Steps Integration Roadmap

1. **Database Scaling**: **[100% COMPLETED]** Swapped local `sqlite:///./banana.db` for a remote high-availability PostgreSQL-compatible CockroachDB cloud database URL (`tpdb`). Integrated custom dialector drivers and built a type-safe data migration pipeline (`migrate_sqlite_to_remote.py`) to copy all active tables and self-referencing comment trees securely to the cloud.
2. **Bookmarking and Telemetry Writing**: Extend your local `BookmarksNotifier` and scroll telemetry tracking to make write requests (`POST /api/bookmarks/{id}`) back to the database, syncing lists across web/mobile platforms.
3. **Paytm Payment Gateways**: Implement your client-side transaction flow, querying `/api/payments/initiate` to log pending payments and trigger secure Paytm checkout views.

---

## 🎙️ Google Cloud TTS & Cloudflare R2 Audio Infrastructure Setup

To implement dynamic, high-fidelity article narrations, the speech synthesis system utilizes **Google Cloud Text-To-Speech (GCP TTS)** and stores the resulting audio assets securely inside **Cloudflare R2** using boto3 pre-signed/signed URL delivery.

### 1. GCP Service Account & Local ADC Setup
The Python backend leverages GCP's **Application Default Credentials (ADC)** strategy. This means that locally, the backend naturally inherits your logged-in Google Cloud CLI identity, while in production (e.g., Cloud Run or GKE), it inherits the attached IAM Service Account directly with **zero required environment variables**.

To set up this identity chain on your GCP project, execute the following CLI commands:

```bash
# 1. Authorize Application Default Credentials (ADC) for seamless local development
gcloud auth application-default login

# 2. Set the active GCP Project
gcloud config set project top-athlete-472606-v4

# 3. Enable the Google Cloud Text-To-Speech API on your project
gcloud services enable texttospeech.googleapis.com

# 4. Create a dedicated Service Account for Article Speech Synthesis
gcloud iam service-accounts create banana-tts-sa \
    --display-name="Banana Ganrajya Article TTS Service Account"

# 5. Bind the "Viewer" role to this Service Account on your GCP project
gcloud projects add-iam-policy-binding top-athlete-472606-v4 \
    --member="serviceAccount:banana-tts-sa@top-athlete-472606-v4.iam.gserviceaccount.com" \
    --role="roles/viewer"
```

*Note: When deploying this backend to GCP (e.g. Cloud Run, Compute Engine, or App Engine), simply attach the service account `banana-tts-sa@top-athlete-472606-v4.iam.gserviceaccount.com` during deployment, and GCP's IAM metadata service will handle token validation automatically.*

---

### 2. Cloudflare R2 Storage Configurations
Cloudflare R2 serves as your secure S3-compatible object storage. MP3 audio files generated by GCP TTS are uploaded to R2, and the backend generates a secure, authenticated **Pre-signed S3v4 URL** (with a maximum expiration limit of 7 days/604,800 seconds) so that the Flutter client can securely stream files without exposing public bucket access.

Ensure the following variables are present in your backend `.env` environment properties:

```env
# Cloudflare R2 Credentials & Endpoint
CLOUDFLARE_ACCESS_KEY_ID=your_cloudflare_access_key_id_here
CLOUDFLARE_SECRET_ACCESS_KEY=your_cloudflare_secret_access_key_here
R2_BUCKET_NAME=your_r2_bucket_name_here
R2_REGION=us-east-1
R2_ENDPOINT=https://<your_account_id>.r2.cloudflarestorage.com
```

---

### 3. Uploaded Assets Metadata Auditing (`uploaded_assets`)
To maintain complete visibility over what files are written to your Cloudflare R2 storage, the database maintains a dedicated **`uploaded_assets`** audit log. This logs file details (keys, sizes, mimetypes) atomically when an asset is successfully uploaded:

```sql
CREATE TABLE uploaded_assets (
    id VARCHAR(100) PRIMARY KEY,
    key VARCHAR(255) NOT NULL UNIQUE,
    mimetype VARCHAR(100) NOT NULL,
    category VARCHAR(100) NOT NULL, -- e.g. 'article_audio'
    size_bytes INTEGER NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
```

*This metadata tracking table is fully integrated into SQLAlchemy, covered by autogenerated Alembic migration scripts, and updated automatically by the asynchronous background TTS synthesis pipeline.*

---

## 🎙️ Checkpoint 2: Rich-Text WYSIWYG Publisher, R2/S3 Media Uploads & Native Audio Player

We extended the architecture to support complete, high-fidelity article composing with inline media uploading and native in-app audio streaming narration.

### 1. Quill.js Snow-themed Editorial Publishing Desk
* Upgraded the `/admin/publish` admin dashboard to serve a modern WYSIWYG rich text environment using **Quill.js** over a CDN.
* Form submissions capture Quill's semantic HTML containing nested `<p>` paragraphs and `<img src="..." />` tags, which are saved directly as the article's body copy.

### 2. Multi-Path Multipart Image Uploads (`/api/admin/upload-image`)
* Implemented a secure backend file-upload endpoint verifying admin bearer authentication.
* Tapping the image icon in the Quill toolbar or dropping files into the newly introduced **drag-and-drop file upload zone** executes an asynchronous multipart upload directly to Cloudflare R2 bucket storage, returning pre-signed 7-day GET URLs and logging metadata into `uploaded_assets`.
* **Adaptive fallback**: In local environments lacking cloud access, the endpoint returns a random, high-resolution news Unsplash image directly, ensuring full testing coverage.

### 3. Native In-App Audio Streaming (`audioplayers`)
* Installed **`audioplayers: ^5.2.1`** on the Flutter client and declared `audioUrl` on the `Article` model.
* The `_ListenButton` inside `article_screen.dart` instantiates an in-memory `AudioPlayer`, automatically streams secure S3 MP3 objects, registers completion stream listeners to reset playback buttons dynamically, and disposes resources on view destruction.

### 4. Semantic block-and-regex HTML rendering
* Built a custom, zero-dependency Dart HTML parser in `article_screen.dart` that extracts paragraphs (`<p>`), headings (`<h1>`, `<h2>`, `<h3>`), quotes (`<blockquote>`), lists (`<ul>`, `<ol>`, `<li>`), and inline images (`<img>`) sequentially.
* **Pre-signed ampersand decrypting**: Replaces escaped `&amp;` separators with literal `&` characters in extracted image parameters, completely restoring S3 signature validity and fixing the broken image grey boxes.
* **Nested Image Redirecting**: Intercepts Quill's nested block image wrapping (`<p><img src="..."></p>`) to cleanly output modern widescreen photo elements with `AspectRatio(aspectRatio: 16/9)`.
