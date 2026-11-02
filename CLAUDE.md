# Biodiversitas Borneo Flora App — CLAUDE.md

## Project Overview

Aplikasi mobile identifikasi flora Kalimantan, dibangun dengan Flutter. Aplikasi ini menjadi bagian klien dari proyek Biodiversitas Borneo dan sekaligus objek penelitian skripsi.

Judul skripsi: "Pengembangan Aplikasi Mobile Identifikasi Flora Kalimantan Dengan Arsitektur Client-Server Berbasis Iterative Waterfall". Status saat ini: tahap implementasi, sambil mengerjakan revisi penguji (Bab 3 lebih dulu).

Nama paket Flutter di `pubspec.yaml` masih `untitled`; impor Dart memakai `package:untitled/...`.

Workspace ini dipakai untuk dua pekerjaan:
1. **Pengembangan aplikasi** (mode kode).
2. **Penulisan skripsi** (mode tulisan).

Diskusi teknis dan teks skripsi memakai bahasa Indonesia. Kode, nama identifier, komentar kode, dan pesan commit memakai bahasa Inggris.

## Architecture

Arsitektur bersifat hybrid, bukan murni server-based:

- **Identifikasi flora berjalan di perangkat** (*on-device*) memakai model terkuantisasi `model_flora.ptl` dan `class_names.txt`.
- **REST API server** hanya dipakai untuk: peta persebaran, laporan gambar spesies tidak dikenal, dan laporan temuan spesies endemik.
- **Katalog spesies (Indeks)** memakai database lokal yang disinkronkan dari server.
- **Peta persebaran** berupa *WebView* ke halaman peta pada web app.

Jangan mengubah pembagian ini tanpa persetujuan saya.

Implementasi kode saat ini (untuk orientasi, tanpa mengubah bullet di atas): `lib/main.dart` → panduan pertama atau `AppShell`; `AppShell` empat tab (Home, Identifikasi, Indeks, Peta) plus antrean laporan offline; inferensi lewat `FloraClassifier` (`pytorch_lite`); metadata spesies diverifikasi lewat `GET species/lookup/?ai_key=`; SQLite (`borneo_flora.db` v3) menyimpan riwayat identifikasi, kandidat, dan antrean laporan — bukan salinan penuh katalog server. Tab Indeks default WebView portal (`ReportConfig.catalogWebViewUrl`); alternatif offline `FloraIndexScreen` + `FloraRepository.ensureLoadedFromAssets()` dari `assets/species_labels.json` / fallback `class_names.txt`.

## Tech Stack

- **Framework:** Flutter 3.38.5 (stable), Dart `^3.10.4` (`pubspec.yaml`; toolchain terpasang: Dart 3.10.4)
- **Inferensi:** PyTorch Lite via paket `pytorch_lite` ^4.3.2 (aset `.ptl`)
- **Database lokal:** `sqflite` ^2.3.0 (`AppDatabase`, berkas `borneo_flora.db`)
- **Preferensi ringan:** `shared_preferences` ^2.5.5 (`AppPrefs`)
- **State management:** `ChangeNotifier` (`IdentificationController`, `HistoryController`) + `ListenableBuilder`/`AnimatedBuilder`; sisanya `StatefulWidget`/`setState`. Tidak ada Provider/Riverpod/Bloc di `pubspec.yaml`.
- **HTTP client:** `dio` ^5.7.0 (`ApiClient`, `SpeciesApiRepository`, `ReportQueueRepository`)
- **WebView:** `webview_flutter` ^4.10.0 (`PortalWebViewTab`)
- **Lain-lain:** `image_picker`, `connectivity_plus`, `geolocator`, `google_fonts`, `path_provider`; `flutter_secure_storage` terdaftar di `pubspec.yaml` tetapi belum diimpor di `lib/`.
- **Desain:** Figma (screenshot dikirim per layar)
- **Linting:** `flutter analyze`, `dart format` (`analysis_options.yaml` → `flutter_lints`)
- **Testing:** `flutter test`

## Related Repository

Server: `biodiversitas_borneo-refactor-apps` (Django 5.2, PostgreSQL, Docker via `just`).

- Dari host, server diakses di `http://localhost:8001` (map Docker `8001:8000`; perintah `just dev` menampilkan `http://localhost:8000` — gunakan **8001** dari host/emulator).
- Dari emulator Android, gunakan `http://10.0.2.2:8001`.
- Dari perangkat fisik USB: `adb reverse tcp:8001 tcp:8001` lalu `--dart-define=BIO_SERVER_BASE_URL=http://127.0.0.1:8001`.
- Dari perangkat fisik via Wi‑Fi: IP LAN komputer; pastikan `ALLOWED_HOSTS` server mengizinkannya.
- Override portal/API: `--dart-define=BIO_SERVER_BASE_URL=<origin tanpa slash akhir>` → REST di `<origin>/api/v1/`.
- Endpoint mobile yang dipakai: `species/lookup/`, `unknown-images/`, `findings/` (tanpa slash awal pada path relatif Dio).

Server dijalankan dari repo server dengan `just dev` (build + up + migrate).

## Project Structure

```
borneo_flora_app/
├── lib/
│   ├── main.dart
│   ├── app/
│   │   └── app_shell.dart          # 4 tab, navbar, antrean laporan, toggle WebView katalog
│   ├── core/
│   │   ├── constants/app_assets.dart
│   │   ├── network/api_client.dart
│   │   ├── storage/app_database.dart, app_prefs.dart
│   │   ├── theme/app_theme.dart
│   │   └── utils/
│   ├── data/
│   │   ├── dummy_data.dart         # Contoh spesies untuk UI/dev
│   │   ├── flora_repository.dart, species_api_repository.dart
│   │   ├── models/
│   │   └── history/                # Kontrak + sqlite (+ prefs legacy)
│   ├── features/
│   │   ├── guide/                  # Panduan pengambilan citra
│   │   ├── home/                   # Home + FloraIndexScreen (katalog lokal)
│   │   ├── identification/         # Layar identifikasi, controller, FloraClassifier, widgets
│   │   ├── history/
│   │   └── report/                 # Laporan, antrean offline, ReportConfig
│   └── shared/widgets/             # navbar, WebView tab, badge, dll.
├── assets/
│   ├── model_flora.ptl             # ~17,8 MB
│   ├── class_names.txt             # 75 label (urutan = output model)
│   ├── species_labels.json         # 75 entri (ai_key 0–74)
│   └── app_icon.jpeg
├── test/
│   ├── report_draft_test.dart
│   └── widget_test.dart
├── android/
└── pubspec.yaml
```

## Development Commands

Jalankan dari akar repo. Flutter SDK harus ada di `PATH`.

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

`BIO_SERVER_BASE_URL` tidak boleh diakhiri `/`. `ApiClient` juga mendukung `--dart-define=API_BASE_URL=...` (default berbeda); jalur laporan/portal memakai `ReportConfig` + `BIO_SERVER_BASE_URL`.

## Key Screens

| Layar | Keterangan | Status |
|-------|------------|--------|
| Home | Akses kamera/galeri, menu panduan/riwayat/pengaturan | Sudah ada (`FloraHomeScreen`) |
| Identifikasi | Ambil/pilih gambar, inferensi on-device | Sudah ada (`IdentificationScreen` + `IdentificationController`) |
| Hasil Identifikasi | Kandidat, metadata API, laporan, riwayat | Sudah ada (aliran dalam tab identifikasi; `dummy_data.dart` hanya contoh/merge lokal) |
| Indeks (katalog) | WebView portal (default) atau daftar lokal dari aset | Sudah ada (`PortalWebViewTab` / `FloraIndexScreen`, toggle di pengaturan) |
| Peta Persebaran | WebView ke `/gis/map/species/` | Sudah ada (`PortalWebViewTab`, `ReportConfig.mapDistributionWebViewUrl`) |
| Riwayat | Daftar & detail identifikasi tersimpan | Sudah ada (`HistoryScreen`, SQLite) |
| Laporan Spesies Tidak Dikenal | Sheet + antrean offline → `unknown-images/` | Sudah dibuat |
| Laporan Spesies Endemik | Sheet + antrean offline → `findings/` | Sudah dibuat |

## Conventions

- **Arsitektur:** pertahankan hybrid. Inferensi tidak boleh bergantung pada koneksi internet.
- **Kode:** ikuti struktur, penamaan, dan pola yang sudah ada. Baca file terkait sebelum mengubah.
- **Perubahan:** buat perubahan yang fokus. Jangan merombak kode yang tidak terkait.
- **UI:** ikuti Figma. Jika desain belum ada, minta dulu dan jangan menebak.
- **Data contoh:** `dummy_data.dart` untuk contoh teks spesies; katalog runtime offline dari aset + lookup API untuk metadata terverifikasi.
- **Verifikasi spesies:** skor model tinggi saja bukan identifikasi final; `isVerified` butuh respons server (kingdom Plantae + `is_verified`).
- **Pesan commit:** bahasa Inggris, singkat, format `type: deskripsi` (contoh: `feat: add identification result screen`).

## Testing

```bash
flutter test
flutter test --coverage
flutter test test/report_draft_test.dart
flutter test test/widget_test.dart --plain-name "layar panduan awal dapat dibangun"
```

Pola test di repo:
- **`test/report_draft_test.dart`** — unit test: `CoordinateApproximator` (grid 0,1°), `generateUuidV4`, formatter di `lib/core/utils/format.dart`, `ReportDraft.create` (endemik vs tidak dikenal, koordinat approximate, `allow_training` hanya untuk citra tidak dikenal).
- **`test/widget_test.dart`** — widget test: `FloraApp(seenGuide: false)` menampilkan teks panduan `"Kenali flora Kalimantan dari satu foto"`.

Catat skenario uji, hasil, dan metrik (akurasi model setelah kuantisasi, waktu inferensi, antrean laporan) karena data ini dipakai di bab pengujian skripsi. Belum ada test integrasi untuk inferensi model atau upload antrean.

## Gotchas

- **Model dan label** — `IdentificationConfig.classCount` = 75; baris non-kosong di `class_names.txt`, panjang output model, dan entri `species_labels.json` (ai_key 0–74) harus selaras. Salah urutan → nama spesies keliru.
- **Emulator Android** — `localhost` menunjuk ke emulator. Gunakan `10.0.2.2:8001` ke server di host.
- **Ukuran model** — `assets/model_flora.ptl` ~17,8 MB; memengaruhi ukuran APK dan waktu inferensi (catat untuk skripsi).
- **WebView** — `AndroidManifest.xml`: `INTERNET`, `usesCleartextTraffic="true"`; URL dari `ReportConfig`; gagal muat → UI error + tombol muat ulang di `PortalWebViewTab`.
- **Offline** — inferensi dan katalog aset tetap jalan tanpa jaringan; antrean laporan (`ReportQueueRepository`) retry saat koneksi kembali (`connectivity_plus` di `AppShell`).
- **Default host** — bila `BIO_SERVER_BASE_URL` kosong, `ReportConfig` memakai `http://kalimantanbio.com` (bukan `10.0.2.2`); untuk dev lokal wajib `--dart-define`.
- **Dio path** — jangan awali endpoint dengan `/` (base sudah `/api/v1/`).
- **Migrasi SQLite** — `AppDatabase` versi 3; jangan rusak kompatibilitas migrasi saat ubah skema.
- **Ambang penerimaan** — `IdentificationConfig.acceptanceThreshold` default 0,95 (`--dart-define=FLORA_ACCEPTANCE_THRESHOLD=...`); terpisah dari ambang UI `confidenceThreshold` 0,45.

## Git Workflow

**Saya yang menjalankan semua perintah git secara manual.** Claude tidak boleh menjalankan perintah git yang mengubah state repository.

Yang **tidak boleh** dilakukan Claude:
- `git add`, `git commit`, `git push`, `git pull`, `git fetch`
- `git checkout`, `git switch`, `git branch` (buat, ubah, atau hapus)
- `git merge`, `git rebase`, `git cherry-pick`, `git reset`, `git revert`
- `git stash`, `git tag`, `git restore`, `git clean`, `git rm`, `git mv`
- Membuat atau mengubah remote, serta membuka *pull request*

Yang **boleh** dilakukan Claude (hanya baca):
- `git status`, `git diff`, `git log`, `git show`, `git blame`, `git branch --list`

Aturan kerja:
- Ubah file langsung di *working tree*, lalu biarkan perubahan itu tidak ter-*commit* agar saya bisa me-*review* dengan `git diff`.
- Setelah selesai mengubah kode, ringkas perubahan per file dalam beberapa kalimat.
- Jangan menyatukan banyak perubahan yang tidak terkait dalam satu tugas. Pecah menjadi langkah kecil agar mudah saya *review* dan di-*commit* terpisah.
- Jika tugas menurut Claude butuh operasi git (misalnya membuat branch baru), tulis saran perintahnya dalam blok kode dan biarkan saya yang menjalankannya.
- Jika Claude ingin tahu kondisi repo, gunakan perintah baca saja.
- Jangan menyentuh folder `.git` secara langsung.

Saran pesan commit:
- Jika saya meminta, usulkan pesan commit dalam bahasa Inggris dengan format `type: deskripsi` (contoh: `feat: add identification result screen`).
- Tipe yang dipakai: `feat`, `fix`, `refactor`, `docs`, `test`, `chore`.

Konvensi branch (untuk acuan saya):
- Branch utama: `main` (`origin/HEAD` → `origin/main`)
- Feature branch: `feat/<nama>`, refactor: `refactor/<nama>`
