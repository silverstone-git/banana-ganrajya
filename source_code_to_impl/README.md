# Banana Ganrajya — Flutter Bootstrap

A Flutter UI bootstrap generated from the Stitch HTML mockups (`homescreen.html`,
`fineprint.html`, `article_view.html`, `opinion_analysis.html`) and
`DESIGN.md`. Ships 4 real screens plus 2 lightweight placeholders, wired
together with `go_router` + Riverpod, using the exact color/typography
tokens from the design system.

## What's included

| Screen | File | Source mockup |
|---|---|---|
| Home | `lib/features/home/presentation/screens/home_screen.dart` | `homescreen.html` |
| Ground Reports (FinePrint) | `lib/features/fineprint/presentation/screens/fineprint_screen.dart` | `fineprint.html` |
| Opinion | `lib/features/opinion/presentation/screens/opinion_screen.dart` | `opinion_analysis.html` |
| Article detail | `lib/features/article/presentation/screens/article_screen.dart` | `article_view.html` |
| Politics *(placeholder)* | `lib/features/politics/presentation/screens/politics_screen.dart` | — no mockup supplied |
| Settings *(placeholder)* | `lib/features/settings/presentation/screens/settings_screen.dart` | — no mockup supplied |

Bottom navigation, the frosted top app bar, the gold-to-purple "FinePrint"
gradient, and the article reading view are all implemented as reusable
widgets under `lib/core/widgets/`.

## Architecture

```
lib/
  core/
    theme/        # AppColors, AppTypography, AppTheme — every token from DESIGN.md
    widgets/       # AppHeader, ArticleAppBar, BottomNavShell, SectionHeader, ...
    router/        # go_router: StatefulShellRoute for the 5 tabs + pushed article route
    providers/      # Riverpod state (bookmarks, as an example)
    models/        # Plain Article model
    mock/          # Static sample content transcribed from the HTML
  features/
    home/opinion/fineprint/article/politics/settings/
      presentation/
        screens/
        widgets/
```

State management uses plain Riverpod `Notifier`/`NotifierProvider` (no
`build_runner` step required to compile). `riverpod_generator` and
`freezed` are left in `pubspec.yaml` as dev dependencies if you want to
move to `@riverpod` codegen or immutable models later — see the comment
at the top of `core/providers/bookmarks_provider.dart`.

This mirrors the same **feature-first, layered** shape discussed for the
Auth0 + Riverpod setup earlier: swap `core/mock/mock_data.dart` for a real
`domain/repositories` + `data/datasources` pair per feature once your
backend API gateway is ready, and the screens don't need to change.

## Running it

This bundle only contains `lib/`, `pubspec.yaml`, `analysis_options.yaml`,
and `assets/` — no native `android/`/`ios`/`web` folders, so you have two
options:

**A. Start fresh (recommended)**
```bash
flutter create banana_app
cd banana_app
# now copy this bundle's lib/, pubspec.yaml, analysis_options.yaml, assets/
# into the new project, overwriting the generated versions
flutter pub get
flutter run
```

**B. Drop into an existing project** — copy `lib/`, `assets/`, and merge
`pubspec.yaml`'s `dependencies`/`assets` into your existing project's
`pubspec.yaml`, then `flutter pub get`.

## Assets

`assets/images/banana_favicon.png` (app logo, used in the top bar and
article back-button bar) and `assets/images/banana_header_logo.png`
(wordmark, for a splash screen or marketing surface) are bundled from your
uploads. All other imagery (hero photos, author headshots, etc.) is loaded
from the same placeholder URLs used in the original HTML mockups via
`Image.network` — swap `lib/core/mock/mock_data.dart` for your CMS/API
data when ready.

## Notes & things to wire up next

- **Politics** and **Settings** tabs have no corresponding Stitch mockup,
  so they're minimal placeholders (Politics reuses the Home list pattern;
  Settings is a plain preferences list — this is also where your Auth0
  "Log Out" action would live).
- Tapping any story card pushes `/article/:id` — currently every id
  resolves to the same sample article body; wire `ArticleScreen` up to a
  repository keyed on `articleId` when you have a backend.
- The bookmark icon on the article screen is wired to a real (in-memory)
  Riverpod provider (`core/providers/bookmarks_provider.dart`) as a
  worked example of the state-management pattern — extend it to persist
  via your API instead of an in-memory `Set`.
- A few icons (social share row, some Material Symbols names) are
  reasonable stand-ins — swap for brand SVGs/exact icons as needed.
