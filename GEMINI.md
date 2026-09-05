# Banana Ganrajya — Developer Guidelines & Retrospective

Welcome to the codebase of **Banana Ganrajya**, a modern journalistic news reading application built using Flutter. This document serves as the repository's single source of truth for architectural standards, styling conventions, design systems, development workflows, and a record of technical bug resolutions.

---

## 🏛️ Architecture

This project follows a **Feature-First, Layered Architecture** designed to facilitate modular scalability and maintainability.

```
lib/
  core/
    theme/        # Design system tokens (AppColors, AppTypography, AppTheme)
    widgets/       # Reusable, global visual widgets (AppHeader, ArticleAppBar, BottomNavShell)
    router/        # Navigation routing (go_router setup with StatefulShellRoute)
    providers/      # Shared state providers (bookmarks, theme toggler)
    models/        # Core entity definitions (e.g., Article model)
    mock/          # Hardcoded/transcribed offline content from high-fidelity Stitch mockups
  features/
    home/          # News feed, breaking tickers, newsletters
    opinion/       # Editorials, columnist gallery, quote blocks
    politics/      # Focused politics feed (currently sharing list widgets)
    fineprint/     # Premium Ground Reports tab & subscriber flow
    article/       # Immersive reader view
    settings/      # Account settings & mock logout action
```

### Future Data Source Upgrades:
To wire this bootstrap to a production API:
1. Introduce a `domain/repositories` + `data/datasources` layer inside each feature package.
2. Swap out imports of `core/mock/mock_data.dart` with state providers reading from your new repositories.
3. The presentation widgets themselves will remain completely decoupled from data transport logic.

---

## 🎨 Design System & Styling Rules

To enforce a high-quality "Journalistic Authority" brand style, the code separates content from navigation:

### 1. Color System (`AppColors`)
* **Never hardcode hex values** directly in feature widgets.
* Always refer to standard palette tokens in `AppColors`.
* **FinePrint Gradient:** The signature gold-to-purple gradient (`AppColors.fineprintGradient`) is exclusively reserved for premium components, subscriber banners, and unlock-actions.

### 2. Typography Rule (`AppTypography`)
* **Editorial Content** (headers, body text, pull quotes, bylines) uses **Source Serif 4** to evoke a classical broadsheet newspaper feel.
* **Interface Chrome** (navigation tab labels, buttons, metadata labels, profiles) uses **Work Sans** to maintain clean boundaries between editorial substance and application utility.

---

## 🗺️ Navigation & Shell Management (`app_router.dart`)

The app implements a persistent bottom navigation shell:
* **`StatefulShellRoute.indexedStack`** is used to handle independent navigation stacks and scroll memory across the five main tabs.
* **Fullscreen Overlays:** The article detail screen (`/article/:id`) is pushed directly on top of the root navigator (`parentNavigatorKey: _rootNavigatorKey`) with its own custom back bar, hiding the bottom bar during reading.

---

## ⚡ State Management & Dynamic Themes

* Standard state utilizes direct Riverpod **`Notifier` / `NotifierProvider`**.
* **`themeModeProvider`** (in `core/providers/theme_provider.dart`) manages the active theme selection (light, dark, or system).
* Out of the box, the app boots in **`ThemeMode.system`**, allowing the platform brightness changes (e.g. terminal `'b'` hotkey in `flutter run` console) to immediately update the visual theme.

---

## 🛠️ Retrospective: Phase 1 Bug Audits & Resolutions

During Phase 1 (UI Fixes & Dark Mode Integration), we resolved several critical bugs:

### 1. Status Bar Overlay Conflict (Android Overlay)
* **The Bug:** Because the custom glass `AppHeader` and `ArticleAppBar` widgets start rendering at screen coordinate $y = 0$, the system status bar elements (time, battery, WiFi) overlaid directly on top of the header branding and action icons.
* **The Solution:** Added a `statusBarHeight` parameter to the headers. At each screen's call-site, the safe region is queried via `MediaQuery.paddingOf(context).top` and passed to the custom headers. The header container's height dynamically expands to `64 + statusBarHeight` with top padding offset by `statusBarHeight`. The frosted background extends cleanly to the top, while the elements sit safely below.

### 2. Secondary News Feed Bottom Overflow (Constraints Exceeded)
* **The Bug:** On narrow-screen test devices, the 2-column secondary stories grid on the home feed threw a yellow-and-black stripe constraint overflow warning: `BOTTOM OVERFLOWED BY 31 PIXELS`. The tight `childAspectRatio` of `0.72` failed to fit the aspect-ratio-1 cover image, category text, and a three-line headline title.
* **The Solution:** Relaxed the `childAspectRatio` of the GridView to **`0.61`**. This expands the height allocated to each cell relative to its width, comfortably hosting the full headline without overflowing.

### 3. Invalid Constant Compilation Errors (Theme Transition)
* **The Bug:** Refactoring `AppColors` constants (`static const Color(...)`) to dynamic getters (`static Color get surface => isDark ? ...`) to reactively update colors broke multiple widgets, throwing compilation errors: `Invalid constant value`.
* **The Solution:** In Dart, a compile-time `const` cannot reference dynamic variables or runtime getters. We stripped the `const` prefix from the immediate wrapper constructors (such as `const Icon`, `const BoxDecoration`, and the children elements of `const Row`) to ensure full compliance with the Dart compiler.

### 4. Dynamic Dark Mode Contrast Invisibility (White-on-White)
* **The Bug:** Flipping into Dark Mode rendered certain UI elements invisible due to lack of contrast:
  * **Footer Banner:** Background mapped to `AppColors.onSurface` (which turns white in dark mode) while the text was hardcoded white, leading to complete white-on-white invisibility.
  * **Threads Icon:** The `@` share icon background was `AppColors.onSurface` (white in dark mode) and its child icon was hardcoded white, making it invisible.
* **The Solution:**
  * Remapped the footer background container to **`AppColors.surfaceContainerLowest`** (charcoal black in dark mode) and set text color dynamically to **`AppColors.onSurface.withOpacity(0.3)`**.
  * Upgraded `_ShareCircle` to accept a dynamic `iconColor` parameter, setting the `@` button icon to **`AppColors.surface`** (dark grey in dark mode, light grey in light mode), resulting in perfect automatic contrast inversion.

---

## 🛠️ Retrospective: Phase 2 Backend Setup, Custom Schemes & Auth0 Integration

During Phase 2, we architected the relational database, launched the FastAPI services, Dockerized the environment, and integrated Auth0 PKCE-native security. Below are the key technical nuances, lessons, and bug resolutions:

### 1. The Pydantic/FastAPI Alias Serialization Pitfall
* **The Bug:** Using Pydantic's `Field(..., alias="cover_image_s3_key")` inside response schemas led to a Dart-side `TypeError: Null is not a subtype of String` crash. While Python code reads the field name (`imageUrl`), FastAPI's default Pydantic serializer outputs the alias names (`cover_image_s3_key`, `is_premium`) during REST outputs by default.
* **The Solution:** We eliminated serialization alias configurations, declaring response properties directly in camelCase (`imageUrl`, `isPremium`, `isLocked`) and mapping ORM models manually in `from_orm_model` to guarantee zero serialization key mismatch errors on client applications.

### 2. Riverpod Build Scope State Mutability Exception
* **The Bug:** Calling `_restoreSession()` asynchronously within our Auth0 Notifier's synchronous `build()` block crashed the app with an `uninitialized provider` error. This was caused by attempting to write to `state` before the parent Notifier provider had completed initialization.
* **The Solution:** Deferred startup mutations securely inside a **`Future.microtask(...)`** wrapper. This schedules the state restoration on the very next event-loop tick, immediately after the notifier has fully completed registration.

### 3. Universal Links 404 "Not Found" vs. Custom URL Schemes
* **The Bug:** Configuring web authentication schemes over HTTPS redirects (`https://dev-3pc3mxrpo2gnszza.us.auth0.com/...`) on a physical device failed with a browser 404 "Not Found" because the Auth0 tenant lacked local `assetlinks.json` (Android) and `apple-app-site-association` (iOS) domain verification files.
* **The Solution:** Switched to an ultra-reliable **Custom URL Scheme (`com.cyto.banana://`)** by registering the package name as the scheme in the Android manifest placeholders. Explicitly passed the scheme to the SDK: `_auth0.webAuthentication(scheme: 'com.cyto.banana')`. This forces the device OS to instantly intercept redirects locally, bypassing web-domain hosting checks.

### 4. Free ngrok Interstitial Programmatic Bypass
* **The Bug:** ngrok's free tier serves security warning landing pages, causing programmatic clients (Dio) expecting JSON to crash or fail when trying to fetch feeds.
* **The Solution:** Added a request interceptor in the global `dioProvider` to inject the `'ngrok-skip-browser-warning': 'true'` header on all out-of-band requests, ensuring the client resolves raw JSON payloads seamlessly.

### 5. CORS Credentials Wildcard Restriction
* **The Nuance:** Using a wildcard `allow_origins=["*"]` with `allow_credentials=True` is strictly forbidden by modern browser engines under CORS specifications, throwing preflight violations on web clients (e.g., Flutter Web).
* **The Solution:** Configured an explicit list of allowed origins (`allowed_origins`) including localhost testing ports, your ngrok proxy, and your production release domain (`https://banana.aryan.cfd`) to guarantee flawless browser compatibility upon release.

---

## 🛠️ Retrospective: Phase 3 Advanced Search, Comments, Audio Polly & Admin Portal

During Phase 3, we successfully implemented local dynamic fallback mechanisms, debounced search, nested recursive comment engines, background speech synthesis, and secure publisher portal handshakes. Below is the technical audit of constraints, nuances, and architectural pitfalls to avoid:

### 1. Dynamic BaseURL Resolution Infinite Loop Block
* **The Nuance:** To resolve dynamic local ngrok tunnels on physical testing devices without configuration overhead, we implemented an asynchronous pre-boot loop querying `https://sh.aryan.cfd/localtesting` inside `main()`.
* **The Pitfall:** If the backend server or the short-link proxy is completely down or unreachable, the `while (true)` loop inside `ApiConfig.resolveDebugBaseUrl()` runs indefinitely. Since this occurs *before* `runApp()`, the Flutter application will hang permanently on the native splash screen with no visual feedback.
* **The Workaround:** Ensure that your local backend/proxy is actively running during development. For production builds, this routine is completely bypassed: `if (!kDebugMode) return;` guarantees zero startup latency for release users.

### 2. Flutter Non-Uniform BorderRadius Painting Assertion
* **The Bug:** Attempting to set a `borderRadius` on a `BoxDecoration` while configuring non-uniform border sides (e.g. setting only `left: BorderSide(...)` with a custom color/width, and other sides using a different color) throws a fatal rendering exception inside Flutter's `box_border.dart` painting routine: `A borderRadius can only be given on borders with uniform colors`.
* **The Solution:** Decouple border decorations from shape rounding. We enclosed the layout inside an `IntrinsicHeight` wrapper, nest a vertical `Row` inside a `Border.all(color: AppColors.surfaceContainer)` rounded container, and paint the custom thick indicator bar as a standalone, stretched left-accent `Container` with its own `topLeft` and `bottomLeft` corner roundings.

### 3. Recursive JSON Parsing Mismatch in Threaded Comments
* **The Nuance:** The backend comments system supports infinitely deep sub-threads (nested replies). The response payload represents a self-referential tree structure.
* **The Pitfall:** Standard parsing loops or lazy JSON maps that don't recursively traverse children lists will crash with `TypeError: List<dynamic> is not a subtype of List<ArticleComment>`.
* **The Solution:** Ensure that model deserialization is strictly recursive:
  ```dart
  factory ArticleComment.fromJson(Map<String, dynamic> json) {
    final rawReplies = json['replies'] as List<dynamic>? ?? [];
    final replies = rawReplies
        .map((item) => ArticleComment.fromJson(item as Map<String, dynamic>))
        .toList();
    return ArticleComment(
      id: json['id'] as String,
      articleId: json['article_id'] as String,
      userName: json['user_name'] as String,
      userAvatar: json['user_avatar'] as String?,
      body: json['body'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      replies: replies,
    );
  }
  ```

### 4. Android 11+ Package Visibility (Queries Intent) Restrictions
* **The Nuance:** Modern Android versions (API 30+) enforce strict application queries guidelines.
* **The Pitfall:** Calling `flutterTts.isLanguageAvailable("en-US")` or `launchUrl(...)` via `url_launcher` will fail silently or return `false` on modern physical devices if the target intents/schemes are not declared inside the Android manifest.
* **The Solution:** Register explicit queries blocks inside `<manifest>` in `android/app/src/main/AndroidManifest.xml`:
  ```xml
  <queries>
      <!-- TTS engine support check -->
      <intent>
          <action android:name="android.intent.action.TTS_SERVICE" />
      </intent>
      <!-- Browser launch support check -->
      <intent>
          <action android:name="android.intent.action.VIEW" />
          <data android:scheme="https" />
      </intent>
  </queries>
  ```

### 5. Google Cloud TTS (GCP TTS) & Cloudflare R2 Uploads
* **The Nuance:** Direct synchronous GCP speech synthesis is highly optimized, but uploading the generated MP3 bytes to Cloudflare R2 is delegated asynchronously inside FastAPI background tasks.
* **The Pitfall:** Cloudflare R2 is fully S3-compatible, but it requires the boto3 client to be configured with **S3v4 signature versions** explicitly: `Config(signature_version="s3v4")`. Failing to pass this parameter causes Cloudflare R2 upload requests to fail with authentication discrepancies.
* **The Solution:** Instantiate the R2 client using `boto3.client("s3", endpoint_url=...)`, setting the config to `s3v4`. All R2 uploads are dynamically tracked inside the `uploaded_assets` SQL table to prevent orphaned storage assets.

### 6. Double-Security Fallback for Admin Route Verification
* **The Nuance:** The admin form submitted from `/api/admin/publish` requires authorization.
* **The Pitfall:** Forcing the administrator to input their native Auth0 JWT Token in web forms is extremely inconvenient, as tokens expire every 1-2 hours.
* **The Solution:** Secure endpoints with a static, server-side secret `ADMIN_API_KEY`. If the admin logs in via Auth0 in the mobile app, their email is verified and they are presented with a button to copy the static `ADMIN_API_KEY` to copy-paste directly.

### 7. Auth0 ID Token vs. Access Token (JWT Segments Mismatch)
* **The Nuance:** The backend JWT validator (`auth0-fastapi-api`) expects standard 3-segment signed JSON Web Signatures (JWS) matching the audience claims.
* **The Pitfall:** When logging in via native web authentication without specifying a custom API audience, Auth0 returns a compact opaque/encrypted token as the `accessToken` (often formatting as a JWE with 5 segments). Sending this token to the backend results in a validation crash: `Invalid token format: expected 3 segments, got 5`, returning HTTP 401.
* **The Solution:** Update the client request interceptor to prefer the **`idToken`** if available before falling back to `accessToken`. Because `idToken` always formats as a standard 3-segment JWS and contains the user's email, name, and identity claims with the Client ID as its audience, it perfectly matches the backend JWT parser defaults when no custom API audience is configured on the tenant.

### 8. Auth0 API Audience Matching & Access Token Recovery
* **The Nuance:** When an API audience is registered on the Auth0 dashboard, Auth0 returns the `accessToken` as a valid 3-segment signed JWS JWT. However, if the client sends the `idToken` to a backend configured with `audience="https://banana-api"`, it will fail with a 401 Audience Mismatch because the ID Token's audience is strictly the Client ID.
* **The Pitfall:** Sending the `idToken` as a bypass when the audience *is* configured correctly throws an audience mismatch, while sending the `accessToken` before the API is configured throws a JWE parse error.
* **The Solution:** Set up the custom API in the Auth0 Dashboard with identifier `https://banana-api`, and refactor the request interceptor (`api_client_provider.dart`) to send `auth.accessToken`. Because the API is fully registered, the `accessToken` is successfully generated as a standard 3-segment signed JWS JWT, matching the backend's expected audience perfectly.

### 9. Decoupling Administrator Email & Key Checks
* **The Nuance:** The admin panel card in Settings was strictly hardcoded to `admin@banana.in` on the client.
* **The Pitfall:** The administrator's dynamic `ADMIN_EMAIL` and `ADMIN_API_KEY` in the backend `.env` could not be propagated automatically to mobile clients, causing visibility and security discrepancies.
* **The Solution:** Added a public `/api/config` endpoint that retrieves and returns the administrator's email. On the client, a Riverpod `configProvider` fetches this on boot, dynamically verifying admin status. To protect the secure `ADMIN_API_KEY`, we added an authenticated `/api/admin/config` endpoint that verifies the sub claim against the DB email and returns the key exclusively to the verified administrator, which is then mapped to the `adminConfigProvider` and copied seamlessly to the clipboard.

### 10. SQLite Database Missing Profile AttributeError (500)
* **The Nuance:** Comments require a relational `User` record to join and populate author bio details.
* **The Pitfall:** If a user logs in via Auth0 but the client never synchronizes their profile, posting a comment inserts the comment with the Auth0 ID successfully (as SQLite has FKs disabled by default), but dereferencing `comment.user.name` immediately crashes the server with `AttributeError: 'NoneType' object has no attribute 'name'`.
* **The Solution:** Implemented two-way safety: (1) Server-side auto-creation inside `create_comment` that reads signed token claims and inserts a profile on-the-fly, and (2) client-side proactive profile sync via `/api/users/sync` triggered inside AuthNotifier upon successful login/session restore.

### 11. Comments Status Code Verification Mismatch (200 vs 201)
* **The Nuance:** The comments posting endpoint returned standard HTTP `201 Created` upon successful comment creation.
* **The Pitfall:** The comments provider (`comments_provider.dart`) strictly checked for `response.statusCode == 200`. Because `201 != 200`, the app treated success as a failure, failing to clear the text controller, and prompting the user to submit again—resulting in duplicate comments.
* **The Solution:** Expanded the status check to allow either `200` or `201`: `if (response.statusCode == 200 || response.statusCode == 201)`, enabling flawless UI clearing and loading on first tap.

### 12. Infinite Height Constraints inside Scrollable Columns
* **The Nuance:** The `AppNetworkImage` is configured to expand to `double.infinity` height inside its layout container.
* **The Pitfall:** Rendering an unconstrained vertical widget (like `AppNetworkImage`) inside a scrollable `Column` causes a fatal layout crash: `RenderImage relayoutBoundary NEEDS-LAYOUT NEEDS-PAINT` with height: `Infinity`.
* **The Solution:** Wrap the inline image inside a responsive **`AspectRatio(aspectRatio: 16 / 9)`** widget, enforcing responsive, bounded layout constraints across all devices.

### 13. S3 Pre-signed URL Ampersand Entity Escaping
* **The Nuance:** Storing pre-signed S3/R2 URLs inside HTML `<img>` tags often causes XML-parsers or text serializers to escape query separators (`&` to `&amp;`).
* **The Pitfall:** Passing `&amp;` inside S3 parameters to the `Image.network` stream breaks S3 signature verification, returning `403 Forbidden` and loading a broken grey card.
* **The Solution:** Added an inline decode step in `_buildInlineImage`: `url = url.replaceAll('&amp;', '&');`, instantly restoring S3 signature validity.

### 14. Nested Image Parsing in Rich WYSIWYG Editor HTML
* **The Nuance:** Quill.js wraps block elements like images inside `<p>` paragraphs (e.g. `<p><img src="..."></p>`).
* **The Pitfall:** A standard sequential block regex matching `<p>.*?</p>` will capture the paragraph wrapper first and pass the raw `<img>` tag to the rich-text spans renderer, which outputs the literal HTML string on the screen.
* **The Solution:** Upgraded the standard paragraph block handler to check if the stripped content begins with `<img` or `<IMG`. If so, it intercepts it, extracts the `src` URL, and redirects it to the widescreen `_buildInlineImage` widget natively.

---

## 🛠️ Retrospective: Phase 4 Relational Database Scaling, Bookmarks Sync & Interaction Telemetry

During Phase 4, we successfully scaled the backend to a remote PostgreSQL-compatible cloud CockroachDB cluster, implemented robust client-side bookmarks synchronizations, deployed background scroll and focus-time telemetry, and resolved search feedback anomalies.

### 1. The CockroachDB Dialect Parsing Assertion (SQLAlchemy Engine Boot)
* **The Nuance:** CockroachDB is wire-compatible with PostgreSQL, but when connecting with a standard `postgresql://` protocol SQLAlchemy attempts to query standard PostgreSQL system tables for version identification.
* **The Pitfall:** CockroachDB returns version strings starting with `CockroachDB CCL v...` instead of standard PostgreSQL numbers, causing SQLAlchemy's default Postgres dialect parser to throw a fatal assertion: `AssertionError: Could not determine version from string 'CockroachDB...'` and crashing the FastAPI server and Alembic migrations on startup.
* **The Solution:** We integrated the **`sqlalchemy-cockroachdb`** and **`psycopg2-binary`** packages. Then, we engineered an automatic protocol normalizer in `backend/app/core/config.py` that intercepts incoming environment variables and dynamically rewrites `postgresql://` URLs to use the optimized `cockroachdb://` protocol scheme. This loads the correct database dialect automatically without requiring developers to change legacy configuration values.

### 2. Optimistic UI Bookmarks Sync with Rollback (Bookmarks saved journey)
* **The Nuance:** Bookmarking articles previously lived as a purely local in-memory `Set<String>` in Riverpod.
* **The Pitfall:** Relational constraints on the remote database require bookmarks to be bound to actual authenticated users, and keeping readers waiting for round-trip HTTP requests to complete on bookmark taps introduced heavy UI responsiveness lag.
* **The Solution:** We updated `bookmarks_provider.dart` to watch `authProvider` and asynchronously fetch synced saved lists on boot/auth-change via `GET /api/bookmarks`. We then updated `toggle` to apply an **optimistic UI state update** (making the bookmark icon immediately react on-tap) and asynchronously trigger backend requests, while employing standard `try-catch` blocks that automatically roll back the local UI state if the backend post or delete fails.

### 3. Non-Blocking Analytics Telemetry on Widget Disposal (Reads Telemetry)
* **The Nuance:** The reading engagement metrics need to track both total article focus time and the maximum vertical scroll depth achieved during the reading session.
* **The Pitfall:** Adding blocking synchronous database reports inside scrolling widgets causes heavy layout micro-stutters. Also, attempting to send telemetry on page exit using standard future hooks can block screen pop-transitions if not structured correctly.
* **The Solution:** We instantiated a `ScrollController` listener inside `ArticleScreen` to calculate and capture the maximum scroll percentage reached by the user. On screen `dispose()`, we computed the focus duration using a simple millisecond timer delta and dispatched a fire-and-forget, fully non-blocking asynchronous `POST /api/analytics/reads` call inside an isolated `try-catch` block, guaranteeing zero layout stutters or navigation latency for the reader.

### 4. Search Suggestions Out-of-Sync Feedback Loop (Recent searches feedback lag)
* **The Bug:** Tapping on a recent search query suggestion below the search bar pasted the query text into the search field and triggered `performSearch(query)`, but results would fail to show up until the user typed another character.
* **The Cause:** `_buildSearchBody` checks `state.query.isEmpty` to decide whether to show recent queries versus actual search results. Since `performSearch` executed queries but forgot to update `state.query` in the Riverpod notifier, the state's query remained empty, rendering the suggestions view over the loaded results until `onChanged` forced a `setQuery` update.
* **The Solution:** Refactored `performSearch` in `search_provider.dart` to cancel any pending debounce timers and update `state = state.copyWith(query: query, isLoading: true)` immediately upon immediate invocation. Also refactored `_onTagTapped` in `search_screen.dart` to call `performSearch` directly, bypassing the 300ms debounce delay entirely for rapid suggestions feedback.

### 5. Article Detail Author Avatar Overlay Mismatch (Author avatar placeholder bug)
* **The Bug:** In the immersive `ArticleScreen` reader view, the circular portrait of the author in the byline block at the top of the article body loaded the article's main widescreen cover image instead of the author's real portrait.
* **The Cause:** The `AppNetworkImage` in the circular container was hardcoded to query `article.imageUrl` (the cover image field) rather than the author's specific profile avatar.
* **The Solution:** We updated the backend `ArticleSchema` response model to dynamically resolve and serialize `authorAvatarUrl = obj.author.avatar_s3_key`. We then expanded the client-side `Article` model class constructor and parsing factory to ingest `authorAvatarUrl`. Finally, we refactored the circle avatar in `article_screen.dart` to load `article.authorAvatarUrl ?? article.imageUrl` to safely overlay their genuine portrait with fallback coverage.

### 6. GCP TTS Semantic Text Sanitization (Semantic HTML and link stripping bug)
* **The Nuance:** The backend creates synthetic audio files of articles on-the-fly and uploads them to S3/R2.
* **The Pitfall:** Passing raw rich-text body content directly to GCP's text-to-speech engine caused the voice narrator to literally read out raw XML tags (e.g. speaking out loud "p", "em", "strong") and spelling out full URL string links, creating a highly disruptive auditory experience.
* **The Solution:** We integrated a regex sanitization pipeline into `synthesize_article_audio_task` inside `backend/app/api/routers/articles.py` before text submission. It dynamically strips out all standard URLs (`https?://\S+|www\.\S+`), removes all HTML tags (`<[^>]+>`), and consolidates multiple whitespaces/newlines into clean, pronunciation-friendly sentences.

### 7. Multi-Line Rich Text Regex Parsing Support (Italics/em-tags formatting bug)
* **The Bug:** Specific HTML formatting tags like `<em>` (italics) and `<strong>` (bold) were being outputted on the mobile reader screen as raw literal strings (e.g. rendering literal `<em>content</em>`) instead of italicizing the text.
* **The Cause:** Dart's standard RegExp dot `.` matches any character *except* newlines. When a paragraph contained formatting that spanned across line-breaks, the parser's `.*?` match failed, leaving the raw HTML tags un-parsed.
* **The Solution:** We upgraded the regex parser pattern in `_buildRichTextParagraph` inside `article_screen.dart` to utilize `[\s\S]*?` instead of `.*?`. Because `[\s\S]` matches any whitespace or non-whitespace character universally (including newlines), formatting blocks spanning multiple lines now parse flawlessly and render with correct styles!

### 8. On-the-Fly Dynamic S3/R2 Signature Generation (Media expiry scaling bug)
* **The Nuance:** Pre-signed S3/R2 URLs have a maximum cryptographic lifetime of 7 days before they expire.
* **The Pitfall:** Storing full static pre-signed URLs directly in the database (`audio_s3_key`) meant that any articles older than 7 days threw `HTTP 403 Forbidden` errors when readers tapped "Listen", making legacy content audio unplayable.
* **The Solution:** We transitioned the architecture to use **On-the-Fly Dynamic Pre-signing**:
  1. Refactored **`synthesize_article_audio_task`** to save only the clean, un-signed S3 path key (e.g., `audio/{article_id}.mp3`) in the database column instead of a static signed URL.
  2. Refactored **`ArticleSchema.from_orm_model`** on GET queries to dynamically intercept any stored keys containing `audio/`, instantiate a local S3/R2 client, and generate a fresh pre-signed GET URL valid for exactly **2 hours**.
  3. Since generating pre-signed URLs is a purely local cryptographic operation (HMAC signature calculation), it executes in under **0.1ms** with zero network roundtrip cost to S3/R2.
  4. Created and executed a standalone database migration script (`migrate_to_clean_s3_keys.py`) to clean, normalize, and migrate all existing full URL database rows retroactively to clean keys, making the storage layer 100% resilient and scale-proof!

### 9. On-Tap Dynamic Debug URL Resolution (Local environment testing retry bug)
* **The Nuance:** When testing on physical mobile devices, dynamic local ngrok tunnels resolve dynamically on boot by calling `resolveDebugBaseUrl` which polls `sh.aryan.cfd/localtesting`.
* **The Pitfall:** If the developer launches the mobile app *before* booting their local ngrok/backend tunnel, the initial resolution loop logs failures, and the app drops into a "Connection Error" screen. Tapping standard "Retry Connection" buttons would try reloading Riverpod providers using the old/stale baseUrl, remaining permanently broken until the entire mobile app was restarted.
* **The Solution:** We implemented **`ApiConfig.forceResolveDebugBaseUrl()`**—a standalone, non-blocking, one-off dynamic URL resolution query. We then refactored the "Retry Connection" buttons across all five primary screens (`HomeScreen`, `OpinionScreen`, `FinePrintScreen`, `PoliticsScreen`, and `ArticleScreen`) to asynchronously await this forced resolution on-tap *before* invalidating and refreshing their Riverpod state providers, allowing seamless environment syncing without restarting the client!

---

## 🛠️ Verification & Build Workflows

### 1. Static Analysis & Lints
The repository enforces strict custom rules alongside standard Flutter lints. Redundant folders are ignored from static checks.
* **Analyze the active workspace:**
  ```bash
  flutter analyze
  ```

### 2. Automated Testing
* **Run the test suite:**
  ```bash
  flutter test
  ```

### 3. Compilation & Build
* **Assemble Debug APK:**
  ```bash
  flutter build apk --debug -d "SM E146B"
  ```
