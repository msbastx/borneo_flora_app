# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working in this repository.

## Project

Flora Borneo is a Flutter app for identifying Bornean flora from camera/gallery images, browsing a species catalog and distribution map, viewing identification history, and submitting reports to the Biodiversitas Borneo portal. Flutter package name is currently `untitled` in `pubspec.yaml`; Dart imports use `package:untitled/...`.

## Commands

Run from repository root. Flutter SDK must be installed and available on `PATH`.

```bash
flutter pub get
flutter run
flutter run --dart-define=BIO_SERVER_BASE_URL=http://10.0.2.2:8001
flutter analyze
flutter test
flutter test test/report_draft_test.dart
flutter test test/widget_test.dart --plain-name "layar panduan awal dapat dibangun"
dart format lib test
flutter build apk
```

For a USB-connected Android device against a local portal, use `adb reverse tcp:8001 tcp:8001` and pass `--dart-define=BIO_SERVER_BASE_URL=http://127.0.0.1:8001`. Android emulator uses `http://10.0.2.2:8001`. `BIO_SERVER_BASE_URL` must not end with `/`; API endpoints are appended to `/api/v1/`.

## Architecture

- `lib/main.dart` initializes Flutter bindings, checks the first-launch guide preference, and selects the guide or `AppShell`.
- `lib/app/app_shell.dart` owns the four-tab navigation, shared identification controller, and offline report queue processing. The catalog tab can use the portal WebView or local catalog; the map tab uses a portal WebView.
- Feature UI and flows live under `lib/features/`: `home`, `identification`, `history`, `report`, and `guide`. Screens are composed from each feature's `widgets/`; feature controllers hold state and orchestrate repositories/services.
- Identification flow: `IdentificationController` coordinates image capture/picking, `FloraClassifier` (on-device PyTorch Lite model), local `FloraRepository`, remote `SpeciesApiRepository`, and identification history. Model inputs and class labels are assets. A high model score alone is not a verified identification; verification requires server/catalog metadata.
- Data access is separated into `lib/data/` (flora data models/repositories and history contracts/implementations). Shared infrastructure is in `lib/core/` (Dio client, SQLite database, preferences, theme, assets, utilities). Shared widgets are in `lib/shared/widgets/`.
- `AppDatabase` is a singleton SQLite database (`borneo_flora.db`) with versioned migrations. It stores identification history, ranked suggestions, and the offline report queue. Preserve migration compatibility when changing schema.
- Reports are persisted offline by `ReportQueueRepository`; image files are copied into app documents storage. Queue processing retries transient failures and resumes when connectivity returns. API base URL and portal URLs are configured in `lib/features/report/report_config.dart`.
- `assets/model_flora.ptl`, `assets/class_names.txt`, and `assets/species_labels.json` support local inference/catalog fallback. Keep model output ordering aligned with labels; only verified metadata should establish species properties.

## Project Configuration

- `pubspec.yaml` defines dependencies, assets, app icon, and splash screen. Notable integrations: `pytorch_lite`, `image_picker`, `sqflite`, `dio`, `connectivity_plus`, `geolocator`, `webview_flutter`, and secure/local preferences.
- `analysis_options.yaml` includes `flutter_lints`; generated platform/build directories are excluded from analysis.
- Tests are under `test/`. Existing coverage includes report draft behavior and the initial guide widget.
