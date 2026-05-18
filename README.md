# Produktivity & Keuangan App

Aplikasi berbasis Flutter yang dirancang untuk membantu pengguna mengelola keuangan pribadi sekaligus meningkatkan produktivitas harian dalam satu platform yang terintegrasi.

## 🚀 Fitur Utama

### 💰 Manajemen Keuangan
* **Pencatatan Transaksi:** Catat pemasukan dan pengeluaran harian dengan mudah.
* **Kategori Kustom:** Pengelompokan transaksi berdasarkan kategori (makanan, edukasi, investasi, dll).
* **Laporan Keuangan:** Visualisasi data pengeluaran dan pemasukan menggunakan grafik yang interaktif.
* **Export Data:** Export laporan ke CSV & PDF.

### ⏱️ Produktivitas
* **Kanban Board:** Manajemen tugas dengan board visual.
* **Habit Tracker:** Pantau konsistensi kebiasaan positif Anda setiap hari.

---

## 🛠️ Tech Stack

* **Framework:** [Flutter](https://flutter.dev/) (Dart)
* **State Management:** Provider
* **Backend:** Firebase (Auth, Firestore)
* **Charts:** fl_chart

---

## 💻 Cara Menjalankan Project

### Prasyarat
* Flutter SDK >= 3.0.0
* Android Studio / VS Code
* Git
* Firebase Project ([Firebase Console](https://console.firebase.google.com))

### 🔐 Firebase Setup (WAJIB)

Project ini **tidak menyertakan file konfigurasi Firebase** demi keamanan. Ikuti langkah berikut:

#### 1. Setup `firebase_options.dart`

```bash
# Copy template file
cp lib/firebase_options.dart.example lib/firebase_options.dart
```

Buka `lib/firebase_options.dart` dan isi dengan nilai dari **Firebase Console → Project Settings → Your apps**.

#### 2. Setup `google-services.json` (Android)

```bash
# Copy template file
cp android/app/google-services.json.example android/app/google-services.json
```

Atau download langsung dari **Firebase Console → Project Settings → Your apps → Android → Download google-services.json**.

#### 3. (Opsional) Setup iOS

Download `GoogleService-Info.plist` dari Firebase Console dan letakkan di `ios/Runner/`.

### ▶️ Jalankan Aplikasi

```bash
flutter pub get
flutter run
```

---

## 📁 Struktur Project

```
lib/
├── data/              # Data layer (models, repositories)
├── presentation/      # UI layer
│   ├── screens/       # Halaman-halaman app
│   └── widgets/       # Reusable widgets
├── firebase_options.dart   # ⚠️ Tidak di-commit (berisi API key)
└── main.dart
```

## ⚠️ Catatan Keamanan

File-file berikut **TIDAK di-commit** ke repository karena berisi API key:
- `lib/firebase_options.dart`
- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`

Gunakan file `.example` sebagai template untuk setup.

---

## 👤 Kontributor

* **Naufal** - [Naufal1-ai](https://github.com/Naufal1-ai)

## 📄 Lisensi

Project ini dilisensikan di bawah MIT License.

## 📚 Resources

- [Flutter Documentation](https://docs.flutter.dev/)
- [Firebase for Flutter](https://firebase.google.com/docs/flutter/setup)
- [FlutterFire Overview](https://firebase.flutter.dev/)
