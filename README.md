# 🎨 ChromaAid AI (Asisten Warna Cerdas & Aksesibilitas)

Selamat datang di repositori ChromaAid AI. Ini adalah aplikasi mobile berarsitektur Offline-First yang dibangun menggunakan Flutter, Pengolahan Citra Digital (PCD), Edge AI (TFLite), Hive, dan MongoDB Atlas. Aplikasi ini dirancang untuk mendeteksi warna secara real-time untuk membantu aksesibilitas penyandang buta warna serta kebutuhan desain profesional.

Mohon baca dan patuhi panduan ini untuk menjaga alur kerja tim tetap rapi dan efisien.

---
# 🏗️ Struktur Folder

Struktur ini adalah proyek Flutter dengan penerapan Clean Architecture, di mana folder `lib/` adalah akar dari aplikasi kita.

```text
├── android/            # Konfigurasi native Android
├── build/              # Hasil build aplikasi (jangan di-commit)
├── ios/                # Konfigurasi native iOS
├── lib/                # --- Folder Utama FLUTTER ---
│   ├── controllers/    # Logic aplikasi, State Management, & Kamera
│   ├── models/         # Blueprint/Schema data (cth: color_model.dart)
│   ├── services/       # Engine PCD, ML (TFLite), Hive, & MongoDB API
│   ├── views/          # Halaman UI dan Screen (Dilarang menaruh logic DB di sini)
│   │   ├── scanner/    # Layar utama kamera & CustomPainter (Overlay)
│   │   ├── detail/     # Layar detail informasi warna
│   │   └── library/    # Layar riwayat palet warna (My Palette)
│   ├── utils/          # Konstanta, fungsi scaling koordinat, dan warna
│   └── main.dart       # Titik masuk utama aplikasi (Entry Point)
├── assets/             # File statis (model.tflite, colors.json)
├── test/               # Unit test dan Widget test
├── pubspec.yaml        # Manajemen dependensi (Package Flutter/Dart)
└── README.md           # Dokumentasi proyek
```
---
# 🌿 Struktur Branch

## Branch Utama
- `main` → Versi rilis (produksi) stabil. (DILARANG PUSH LANGSUNG)
- `develop` → Gabungan dari semua fitur yang sudah selesai dan siap untuk diuji coba. Ini adalah target PR utama.
## Branch Fitur
Gunakan format: 
```
<tipe>/<nama-fitur-singkat>
```
Contoh:

`fitur/pcd-average-pooling`

`fitur/ui-scanner-reticle`

`bug/fix-memory-leak-camera`

---
# 🚀 Project Setup (Lokal)

## 1. Clone Repositori
```
git clone https://github.com/zainandhinf/A8-PCD-ChromaAid.git
```
```
cd ChromaAid
```
## 2. Install Dependensi (Packages)
Unduh semua dependensi yang tercatat di pubspec.yaml:
```
flutter pub get
```
## 3. Setup Environment Variables
Aplikasi ini membutuhkan file environment untuk Confidence Threshold dan koneksi MongoDB.
**1. Salin file `.env.example` menjadi `.env`.** 
```
cp .env.example .env
```
**2. Pastikan file `model.tflite` dan `colors.json` sudah ada di dalam folder `assets/` agar Edge AI dapat berjalan secara lokal tanpa internet.**
---
# 💻 Menjalankan di Mode Development

Pastikan emulator sudah berjalan atau perangkat fisik sudah terhubung melalui debugging mode.
- Jalankan aplikasi dengan fitur Hot Reload:
```
flutter run
```
---
# 📦 Build untuk Production

Build APK (Untuk testing internal):
```
flutter build apk --release
```
---
# 🔁 Alur Kerja GitHub

## 1. Selalu mulai dari develop
```
git checkout develop
```
```
git pull origin develop
```
## 2. Buat branch fitur baru
```
git checkout -b fitur/ui-scanner-reticle
```
## 3. Kerjakan fitur (Coding...)
## 4. Commit perubahan Anda
```
git add .
```
```
git commit -m "feat: implementasi custom painter untuk reticle bidikan"
```
## 5. Push branch Anda ke GitHub
```
git push origin fitur/ui-scanner-reticle
```
## 6. Buat Pull Request (PR)
- Buka repositori di GitHub.
- Buat Pull Request dari fitur/offline-draft-peminjaman ke develop.
- Minta 1-2 rekan setim untuk me-review kode Anda.
---
# ✅ Format Commit Message

Gunakan format konvensional: 
```
<tipe>: <deskripsi singkat>
```
Tipe umum:
- feat: fitur baru
- fix: perbaikan bug
- docs: dokumentasi
- style: perubahan visual tanpa logic
- refactor: perbaikan kode internal
- test: pengujian
- chore: pembaruan kecil (update package di pubspec.yaml, dll)
Contoh:
```
feat: integrasi tflite_flutter untuk deteksi objek layar utama
fix: perbaiki error saat kamera di-dispose
refactor: pindahkan logika ekstraksi warna ke isolate terpisah
```
---
# 🧼 Tips Tambahan

- Pastikan fungsi kamera di-dispose() dengan benar saat keluar layar untuk mencegah kebocoran RAM.
- Pastikan aplikasi tetap berfungsi mulus saat mode offline/tanpa internet diuji coba.
- Jalankan dart format . dan flutter analyze sebelum push.
- Pisahkan logika pengolahan data (Controller/Service) dari desain tampilan (View).
- Jika ragu saat terjadi merge conflict, tanyakan ke rekan setim sebelum di-merge.
---
Semangat berkontribusi! 💪


