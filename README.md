# Banana Ganrajya — Modern Journalistic Flutter App

[![Flutter Version](https://img.shields.io/badge/Flutter-3.44.8-blue.svg)](https://flutter.dev)
[![Dart Version](https://img.shields.io/badge/Dart-3.12.2-blue.svg)](https://dart.dev)
[![State Management](https://img.shields.io/badge/Riverpod-2.6.1-red.svg)](https://riverpod.dev)
[![Build Status](https://img.shields.io/badge/Build-APK_Assembled_Success-brightgreen.svg)]()

**Banana Ganrajya** is an immersive, high-fidelity mobile news application designed around the principles of "Journalistic Authority" (lifted from `DESIGN.md`). It features an elegant frosted top app bar, the premium gold-to-purple "FinePrint" gradient system, editorial Source Serif 4 typography, and high-performance interactive components.

---

## 🏛️ Application Architecture

The application implements a **Feature-First, Layered Architecture**, cleanly separating presentation blocks from global routing, state providers, and shared design tokens.

```
lib/
  core/
    network/       # Dynamic API BaseURL resolution & fallback mechanism
    theme/        # Core design system (AppColors, AppTypography, AppTheme)
    widgets/       # Global custom widgets (AppHeader, ArticleAppBar, BottomNavShell)
    router/        # StatefulShellRoute multi-stack navigation configuration
    providers/      # Shared state providers (bookmarks, reactive theme togglers)
    models/        # Shared entities (Article, Author)
    mock/          # Transcribed Stitch high-fidelity mockup offline data
  features/
    home/          # Main news feed, breaking news ticker, newsletters
    politics/      # Coverage focused politics feeds
    opinion/       # Columnist directories, Quote of the Day, bento cards
    fineprint/     # Premium Ground Reports tab & subscriber flows
    article/       # Fully immersive article detail reader view, threaded discussions, authors
    search/        # Frosted global search view (matching tags, columnists, articles)
    settings/      # Interactive user settings, preferences, and admin publishing keys
```

---

## 🚀 Active Project Progress

We have successfully executed the key phases of **`PLAN.md` (Core UI, Relational Backend, Security, Search, Comments, and Editorial Portal)**. Below is an audit of what has been implemented, compiled, and verified:

### 1. Overlay & Layout Rectification
* **Status Bar Safety Integration:** Refactored `AppHeader` and `ArticleAppBar` to query dynamic top padding via `MediaQuery.paddingOf(context).top`. Glass headers extend seamlessly to the top edge behind the status bar, while branding icons and navigation actions are cleanly aligned in the safe region.
* **Secondary Story Grid Overflow Resolved:** Tweaked the GridView's `childAspectRatio` on the Home Feed from `0.72` to `0.61`. This dynamically allocates the correct height budget for multi-line titles, eliminating constraints overflows on narrower testing screens.
* **Non-Uniform Rounded Corner Crash Fixed:** Re-engineered the Author biography quote cards structurally with `IntrinsicHeight` and a row-based stretching accent container. This completely resolves the `'A borderRadius can only be given on borders with uniform colors'` Flutter painting assertion, keeping the soft, rounded design language intact.

### 2. Reactive, Zero-Refactor Dark Mode
* **Under-the-Hood Engine:** Refactored all `AppColors` fields into **dynamic getters** linked to a global static state: `static bool isDark = false;`.
* **Platform Brightness Integration:** Hooked up `themeModeProvider` (using Riverpod) to default to `ThemeMode.system`. The terminal `'b'` hotkey in the `flutter run` console immediately toggles Brightness, which triggers a reactive rebuild of the widget tree applying the dark palette on-the-fly.
* **Contrast Safeguards:** Verified and optimized layout elements to eliminate white-on-white text invisibilities:
  * **Footer Banner:** Background maps dynamically to `surfaceContainerLowest` with text mapped to `onSurface.withOpacity(0.3)`.
  * **Listen Button contrast:** The playing state ("PLAYING") has been updated to use `onPrimaryFixed` text and icon colors, providing impeccable contrast against its light-pink background under dark mode.
  * **Social Icons:** The threads `@` button circle background uses `onSurface` while its icon is mapped dynamically to `AppColors.surface`, providing perfect contrast on both themes.
* **UI Controls:** Added a dynamic `Switch` in the Settings tab, updating icons and titles in real-time.

### 3. Customized Brand Launcher Icons
* Integrated the `flutter_launcher_icons` toolchain using the high-res favicon asset (`assets/images/banana_favicon.png`).
* Automatically generated all Android (mipmap/drawable) and iOS launcher resources, fully packing the custom app icon into the assembled output.

### 4. Relational FastAPI Backend & SQLite Repository
* **FastAPI Core**: Engineered a complete, scalable Python backend located inside the `/backend` folder. Configured dynamic settings loading via `pydantic-settings` to auto-ingest credentials from root `.env` environments.
* **SQLAlchemy ORM & Database**: Mapped a fully normalized database schema covering Users, Authors, Articles, Comments, Bookmarks, and Payments. Successfully migrated using Alembic to create `backend/banana.db`.
* **High-Fidelity Seeding**: Populated database tables with real categorical feeds, threaded discussions, columnist profiles, and publication logs transcribed directly from mock designs, including a dedicated `breaking-1` breaking news ticker click-through.
* **Docker Deployment Ready**: Provided a multi-stage production Dockerfile and orchestration docker-compose configurations with volume mounts for persistent local database storage.

### 5. Official Auth0 Identity Integration
* **Backend Protection**: Custom integrated the official `auth0-fastapi-api` SDK as a route dependency, verifying JWT signatures, expiries, and user sub claims against your live tenant dynamically.
* **Native Universal Login**: Configured Android manifest redirect placeholders and iOS plist URL schemes utilizing custom URL schemes (`com.cyto.banana://`) for bulletproof, App-Links-free redirection handshakes.
* **Interceptors Telemetry**: Configured a dynamic Dio client interceptor that reads the Riverpod Auth state and automatically injects the user's real Bearer JWT tokens on requests, falling back to mock headers for development compatibility. Built a custom network diagnostic logger to stdout.

### 6. Dynamic Backend URL Fallback (Local Dev)
* Added a dynamic bootstrapping stage in `lib/main.dart` that executes **prior to running the app**.
* In `kDebugMode`, it queries `https://sh.aryan.cfd/localtesting` repeatedly upon boot, intercepts the `301` redirection URL pointing to your active ngrok proxy tunnel (from the `Location` header), and overrides the default API base URL. This lets developers launch the app on simulators/physical devices with zero URL configuration overhead.

### 7. Interactive Author Page & Pull-to-Refresh
* **Author Profiles**: Redesigned the author profile feeds with vintage double-line dividers, double concentric border avatar rings, upper-case red designation badges, and custom quote cards. Clicking any author name/avatar at the top of an article automatically navigates to their profile page.
* **Unified News Desk**: Dynamically checks if the author is `"Banana Ganrajya Team"` and adjusts the layout beautifully: changing the headers from `"PUBLISHED COLUMNS"` to `"LATEST REPORTS"` and replacing columnist notebook icons with active news feed symbols.
* **Pull-to-Refresh**: Integrated standard `RefreshIndicator` widgets across all key feeds (Home, Ground Reports, Opinion, Politics), forcing invalidation of the Riverpod provider cache and clean database re-queries on pull gestures.

### 8. Interactive Global Search (`lib/features/search/`)
* **Frosted Search Overlay**: Tapping the search icon in the persistent `AppHeader` now opens a beautiful, frosted search screen with a custom close handler, recent search queries, and exploring topic pills.
* **Typing Debounce**: Integrated an advanced `SearchNotifier` with a 300ms typing delay. It fires queries to `/api/search?q=...` only when the user finishes typing to protect server-side bandwidth.
* **Grouped Results**: Classifies search results in a broadsheet design under **Matching Topics (Chips)**, **Columnists & Authors (Cards with circular portraits)**, and **Articles (Category + Headline + Thumbnail)**.
* **Local Persistence**: Integrated `shared_preferences` key-value storage to cache, retrieve, delete, or clear the user's past 10 unique recent queries.

### 9. Threaded Comments & Gated Discussions (`lib/features/article/`)
* **Recursive Comment Trees**: Added recursive database models and Pydantic schemas that support infinite sub-threaded comment trees.
* **Visual Discussions Board**: Embedded an elegant `CommentsSection` at the bottom of the article view. It displays comments as individual cards with indented nested replies separated by dynamic vertical guidelines.
* **Gated Input Box**: Checks the Auth0 state. Anonymous guests are presented with a premium login CTA, while authenticated subscribers can immediately post comments or sub-threaded replies with active loading indicators.

### 10. Article Audio Synthesis & On-Device TTS Fallback
* **Database & Alembic Migrations**: Provisioned `audio_s3_key` in the `Article` database table and applied secure migrations to SQLite. Added `audioUrl` mapping to the schema.
* **GCP TTS Speech Synthesis**: Developed a `POST /api/articles` endpoint. Upon creating a new article, the server triggers an asynchronous background task to synthesize text utilizing **Google Cloud Text-To-Speech (GCP TTS)** via the naturalistic **`en-US-Neural2-F`** voice.
* **Cloudflare R2 Signed Uploads**: Uploads the synthesised MP3 bytes directly to **Cloudflare R2** and dynamically generates a secure, pre-signed S3v4 URL (valid for 7 days) stored directly into `audio_s3_key`.
* **Asset Tracking Auditing**: Logs each successful R2 upload inside a newly introduced `uploaded_assets` table (tracking key, mimetype, category, file size in bytes, and timestamp).
* **Smart Client-Side Player Fallback**: Redesigned the `[LISTEN]` component on the client side:
  1. Streams and buffers the high-quality Neural GCP TTS MP3 file from Cloudflare R2 using the pre-signed URL.
  2. Falls back to **`flutter_tts`** to speak the body text using the device's native voice engines.
  3. Completely hides the listen button if the device OS doesn't support TTS, preventing dead taps.

### 11. Secure Admin Publishing Portal (`/api/admin/publish`)
* **Endpoint Protection**: Secured `POST /api/articles` with a custom `HTTPBearer` security dependency `validate_admin_privilege` that verifies requests against a long-lived secret `ADMIN_API_KEY`.
* **FastAPI HTML Publishing Desk**: Directly serves a styled, responsive broadsheet publishing HTML page on `/api/admin/publish`. It queries the database to list actual `Author` profiles in a select dropdown, collects article inputs, and handles JSON posts with clean JavaScript Success/Error alerting cards.
* **Mobile Settings Integration**: In the Settings Screen, if the authenticated user's email matches `admin@banana.in` (dynamically synced via backend secure endpoints!):
  * Unlocks an **`EDITORIAL PUBLISHER PANEL`** card.
  * Adds a **`LAUNCH`** button that opens `/api/admin/publish` directly in their default browser (using the newly integrated `url_launcher` package).
  * Adds a **`COPY KEY`** button that copies the secure administrator credentials (fetched dynamically from `/api/admin/config`) to the system clipboard with an informative snackbar.

### 12. Quill.js Rich-Text Publishing, R2/S3 Image Uploads & Native Player
* **Quill.js Rich-Text Editor**: serving a beautiful, SNOW-themed WYSIWYG editorial publisher desk directly from the FastAPI backend at `/admin/publish`.
* **Inline Cover & Photo S3 Uploads**: Built `/api/admin/upload-image` endpoint that pipes multipart images to Cloudflare R2 bucket with clean news-focused Unsplash local fallback mocks.
* **Adaptive Block Parsing**: Refactored `_buildBodyParagraphs` in the Flutter client with a regex-driven HTML block scanner that splits and renders paragraphs (`<p>`), headings (`<h1>`, `<h2>`, `<h3>`), quotes (`<blockquote>`), list items (`<ul>`, `<ol>`, `<li>`), and inline images (`<img>`) sequentially while decoding common XML/HTML entities like `&quot;`, `&#39;`.
* **Pre-signed S3 ampersand recovery**: Intercepts extracted pre-signed R2/S3 image URLs to decode escaped ampersands (`&amp;` -> `&`) on-the-fly, completely restoring S3 signature validity and resolving broken image grey boxes.
* **Native In-App Audio Playback**: Added `audioplayers` dependency, resolved `audioUrl` on the client, and implemented stateful, background-streaming narration directly inside `article_screen.dart` with complete completion listening and automatic button reset handlers.

### 13. Production Database Scaling, Bookmarks Sync & Read Telemetry
* **PostgreSQL & CockroachDB Scaling**: Transitioned relational backend storage from local SQLite to a high-availability remote CockroachDB/PostgreSQL cloud server (`tpdb`), utilizing `psycopg2-binary` and custom database URL normalization interceptors.
* **Database Migration Engine**: Developed a robust data-copy script (`migrate_sqlite_to_remote.py`) that handles tables replication, constraints, and hierarchical self-referential parent comments perfectly on the cloud database.
* **Optimistic Bookmarks Sync**: Re-engineered `bookmarks_provider.dart` to sync saved articles with `/api/bookmarks`, implementing an optimistic state update (responsive UI) and standard try-catch rollback checks on network failure.
* **Scroll & Duration Telemetry**: Embedded scroll trackers and screen entrance timers in `ArticleScreen`, delivering fully non-blocking asynchronous interaction logs to `POST /api/analytics/reads` upon page disposal.
* **Search Suggestions Bug Fix**: Resolved suggestions lag bug by synchronizing state queries during immediate suggestion taps and bypassing typing debounces for rapid user responses.

---

## 🗺️ Future Strategic Roadmap

* **💳 Paytm All-In-One SDK Integration:** Implement subscription checkout on the FinePrint subscriber tab utilizing server-to-server transaction tokens.
* **📶 Local Cache & Full Offline Mode:** Store complete metadata of bookmarked articles using SQLite (`drift` / `hive`) and redirect to a cached-only offline feed on loss of connectivity.

---

## ⚡ Developer Execution Commands

### A. Backend Development (FastAPI)

#### 1. Setup Virtual Environment & Dependencies
```bash
cd backend
python -m venv .venv
.venv\Scripts\pip install -r requirements.txt
```

#### 2. Run Database Migrations & Seeding
```bash
cd backend
.venv\Scripts\alembic upgrade head
.venv\Scripts\python -m app.seed
```

#### 3. Start Local Development Server
```bash
cd backend
.venv\Scripts\python -m uvicorn app.main:app --port 8000 --reload
```

#### 4. Spin Up Production Containers (Docker)
```bash
cd backend
docker compose up --build -d
```

### B. Frontend Development (Flutter)

#### 1. Clean Static Analysis
Verify that all type properties, dynamic getters, and structures conform to strict Flutter lints:
```bash
flutter analyze
```

#### 2. Automated Behavioral Tests
Validate overall route navigation and widget pumping operations:
```bash
flutter test
```

#### 3. Assemble Debug Android APK
Compile the codebase into a packaged deployable binary pointing to your active ngrok proxy:
```bash
flutter build apk --debug -d "SM E146B"
```
