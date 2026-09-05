# Banana Ganrajya — Frontend Implementation Plan (Flutter)

This document outlines the strategic roadmap for integrating functional requirements into the Flutter application, documenting accomplishments and solutions.

---

## 🌟 Accomplished Steps

### 1. UI Fixes & Styling
* **Status Bar Overlay Fix:**
  * Added a dynamic `statusBarHeight` property to `AppHeader` and `ArticleAppBar`.
  * Queried the status bar safe area dynamically using `MediaQuery.paddingOf(context).top` inside the screen views (`HomeScreen`, `SettingsScreen`, etc.) and offset the app bar layout by this padding.
  * **Result:** Frosted glass banners now seamlessly stretch behind the status bar while aligning the layout icons below it.
* **Secondary Grid Layout Overflow Fix:**
  * Decreased the fixed `childAspectRatio` in `HomeScreen` grid count from `0.72` to `0.61`.
  * **Result:** Provided extra vertical room for three-line titles, eliminating bottom pixel overflows on narrow displays.
* **Dynamic Dark Mode:**
  * Implemented a reactive color engine: refactored all `const` color fields inside `AppColors` into **dynamic getters** linked to a global static state: `static bool isDark = false;`.
  * Created `themeModeProvider` (using Riverpod) defaulting to `ThemeMode.system` so the terminal `'b'` hotkey triggers instant platform brightness toggle between light and dark modes out-of-the-box.
  * Upgraded `SettingsScreen` to a `ConsumerWidget` with an interactive switch to toggle dark mode manually.
  * Cleaned up and verified contrast readability on elements (such as the footer "Democracy Dies in Darkness" banner and Threads `@` icon) to ensure zero white-on-white text issues.
* **Authentication (Auth0 Native Integration):**
  * Integrated `auth0_flutter` SDK supporting secure PKCE authorization.
  * Configured native web authentication schemes on Android (`manifestPlaceholders`) and iOS (`CFBundleURLTypes`) using lowercase custom URL protocols (`com.cyto.banana`).
  * Implemented a robust Riverpod-backed `authProvider` that handles session restoration, logging in via secure native browser frames, and logging out cleanly.
  * Configured a dynamic Dio network interceptor that automatically attaches the user's real Auth0 access token as a `Bearer` token on request headers, falling back automatically to offline-testing mocks.
  * Built a dynamic Settings profile card showing Google Profile avatar, name, email, and subscriber badge when authenticated.
* **Relational Backend REST API Server (FastAPI + SQLite + Alembic):**
  * Built a scalable, clean REST API structure with FastAPI.
  * Architected a fully normalized relational schema using SQLAlchemy 2.0 covering Users, Authors, Articles, Comments, Bookmarks, and Payments.
  * Applied migrations cleanly with Alembic and seeded SQLite with high-fidelity mock data from original Stitch mockups, including a dedicated breaking news click-through.
  * Dockerized the FastAPI service using a secure, lightweight multi-stage Dockerfile and provided a compose configuration mapping SQLite database volumes for safe local data persistence.
* **Dynamic Pull-to-Refresh Feeds:**
  * Integrated `RefreshIndicator` across all key feeds (Home, Ground Reports, Opinion, and Politics), forcing asynchronous Riverpod invalidation streams to re-query the SQLite database on pull gestures.
* **Author & Columnist Profiles (Author's Page):**
  * Developed endpoints on the backend (`/api/authors/{id}` and `/api/authors/{id}/articles`) to fetch profile metadata and pagination logs.
  * Built a gorgeous broadsheet Author Profile Screen displaying high-resolution photographs, professional biography blocks, and scrollable grids of all columns published by them.
  * Wired up interactive navigation callbacks so that tapping the author's bio card at the bottom of any article transitions the reader smoothly to their profile.
* **Interactive Global Search (New!):**
  * Implemented search endpoints on the backend to match articles, authors/columnists, and tags.
  * Wired up the default search tap on `AppHeader` to seamlessly push a gorgeous, frosted fullscreen `SearchScreen`.
  * Implemented an advanced debounced `SearchNotifier` (300ms delay) that queries `/api/search?q=...` only when typing stops to protect server bandwidth.
  * Added robust search history management utilizing the newly added `shared_preferences` local persistence layer (holding up to 10 unique recent searches).
  * Grouped results cleanly into matching tags/topics, columnist/author profiles, and article rows with modern circular avatar/media thumbnail designs.
* **Interaction & Social (Comments):**
  * Implemented recursive comment trees on the backend utilizing modern self-referential relations.
  * Created the `ArticleComment` recursive model and `CommentsNotifier` Riverpod provider to fetch and submit nested comments.
  * Added a fully featured, elegant discussion board (`CommentsSection`) at the bottom of the article detail view.
  * Engineered a secure gated input mechanism allowing subscribers to log in directly through Auth0 to join discussions, while showing call-to-actions for anonymous guests.
  * Supported unlimited threaded indentation loops natively with a faint left border separator guiding nested dialogues.

---

## 🧩 Technical Retrospective: The `const` Compilation Challenge

### The Problem
When transitioning `AppColors` properties from compile-time constants (`static const Color(...)`) to reactive dynamic getters (`static Color get surface => isDark ? ...`), we encountered compiler errors: `Invalid constant value` across multiple widgets.

### The Technical Reason
In Dart, any expression prefixed with the `const` keyword (such as `const Icon(...)`, `const BoxDecoration(...)`, or elements of a `const []` list literal) must be fully evaluated and baked into the binary at **compile-time**. 
Because our updated `AppColors` properties are dynamic getters evaluated at **runtime** (depending on the `isDark` state), they can no longer be used inside a compile-time constant context.

### Did We Really Need to Remove Them?
**Yes!** There is no way in Dart to have a compile-time constant depend on a runtime mutable state. If we did not remove the `const` prefix from the constructors and collections that referenced `AppColors`, the compiler would refuse to assemble the app, failing the build completely.

### The Alternatives considered
The alternative would be creating two distinct static classes (`AppColorsLight` and `AppColorsDark`) and replacing every reference to `AppColors` with `Theme.of(context).colorScheme.xxxx` across 68 files. 
By converting `AppColors` to dynamic getters instead, we preserved the exact same call-site syntax (e.g., `AppColors.surface`), meaning we only had to remove the `const` keywords from the immediate widget wrappers. This was the most surgical, token-efficient, and maintainable path possible.

---

## 🗺️ Completed Strategic Roadmap

### 2. Authentication (Auth0) — [COMPLETED]
* **Integration:** Fully integrated `auth0_flutter` package.
* **Flow:**
  * Wired up dynamic login/logout flows in the Settings tab.
  * Secured state synchronization seamlessly across the client and backend.
* **Profile Screen / Session Header:**
  * Integrated a dynamic profile session header inside the Settings Screen displaying the logged-in user profile, email, picture, and dynamic subscription tier badge.
* **Subscription Status:** 
  * Displays "SUBSCRIBER" or "FREE" tiers reactively based on Auth0 synchronization.

### 3. Article Features & Media — [COMPLETED]
* **Bookmarked Articles:**
  * Connected `bookmarksProvider` to synchronize directly with the backend SQLite database `/bookmarks` endpoints.
* **On-Device Text-to-Speech (TTS) & Cloudflare R2 Integration:**
  * Provisioned `audio_s3_key` columns on SQLite, implemented automated background speech synthesis asynchronously using **Google Cloud Text-To-Speech (GCP TTS)**, uploaded the audio bytes to **Cloudflare R2**, and saved pre-signed URLs directly inside the database.
  * Audited all uploads inside the newly created `uploaded_assets` database tracking table (logging key, mimetype, category, size_bytes, and timestamp).
  * Implemented an intelligent client-side fallback checking R2 pre-signed URLs first, falling back to local `flutter_tts` engines second, and hiding the button if TTS is completely unsupported.

### 4. Payments (Paytm Integration) — [COMPLETED]
* **Flow & Backend Schema:** Mapped Paytm transactions schema on SQLAlchemy, implemented transactional state tracking, order ID generation, and signature verifying endpoints (`/payments/initiate` and `/payments/verify`) fully prepared for merchant client-side hybrid bridging.

### 5. Offline Capabilities (Local Sync) — [COMPLETED]
* **Local Sync:** Provided full local database sync caching for authors, articles, comments, and recent search history (utilizing SQLite migrations, shared_preferences, and robust offline-safe mock fallback modes).

### 6. Interaction & Social (Comments) — [COMPLETED]
* **Design & Layout:** Appended a gorgeous, broadsheet-inspired `CommentsSection` at the bottom of `ArticleScreen`.
* **Features:**
  * Renders recursive nested comment cards indents dynamically with faint vertical guidelines.
  * **Gated Input Field**: Gated comment submissions to verified subscribers, prompting anonymous guests to log in first.

### 7. Read Analytics (Microanalysis Engine) — [COMPLETED]
* **Metrics:** Developed deep telemetry tables (`analytics_reads`) on SQLite and implemented telemetry POST schemas (`/analytics/reads`) recording reading milestones (scroll-depths, milestones, completion checks, and focused read duration).

### 8. Author's Page — [COMPLETED]
* **Scope:** Redesigned `AuthorProfileScreen` with premium double-line dividers, nested concentric border picture frames, red-accented uppercase designation badges, and custom quote containers.
* **Unified News Desk**: Dynamically redirects and reformats layout details for `"Banana Ganrajya Team"` desk profiles, adapting columns into reports seamlessly.
* **Inline Interactivity**: Implemented reactive, inline bookmark toggles within the cards so readers can save column stories instantly.

### 9. Interactive Global Search (New!) — [COMPLETED]
* **Scope:** Integrated a frosted fullscreen `SearchScreen` reachable from the top search actions on `AppHeader`.
* **Features:**
  * **Typing Debounce**: Integrated an advanced 300ms typing delay to protect server-side bandwidth.
  * **Grouped Results**: Classifies matching records cleanly into Matching Tags (Chips), Columnist profiles, and Article rows.
  * **Search History**: Persists up to 10 unique recent queries locally using the newly added `shared_preferences` package.

### 10. Rich-Text WYSIWYG Editor & Image Uploads — [COMPLETED]
* **Scope**: Upgraded `/admin/publish` to load **Quill.js**, rendering a high-fidelity semantic HTML editorial workspace.
* **Inline R2/S3 Image Uploads**: Added a secure `/api/admin/upload-image` endpoint that pipes multipart images to Cloudflare R2 with beautiful, news-focused Unsplash fallback mocks.
* **Drag-and-Drop Image Tool**: Created dual upload paths (Quill toolbar button and a dotted drag-and-drop widget) that upload to S3 and insert the pre-signed image URL directly into the editor cursor.
* **Semantic HTML block rendering**: Refactored `_buildBodyParagraphs` in `article_screen.dart` with a regex-based HTML block scanner that parses paragraphs (`<p>`), headers (`<h1>`, `<h2>`, `<h3>`), quotes (`<blockquote>`), list items (`<ul>`, `<ol>`, `<li>`), and inline images (`<img>`) sequentially while decoding common XML/HTML entities.
* **Pre-signed S3 ampersand recovery**: Corrected S3 signature verification failures by decoding escaped HTML ampersands (`&amp;` -> `&`) in extracted image source parameters.
* **In-App Native Audio Playback**: Integrated `audioplayers` package on the client, parsed `audioUrl` inside `Article.fromJson`, and developed a fully stateful, background-streaming narrator player in `article_screen.dart`.
