# AgentSkills: Mobile Engineer (Flutter)

## 1. Core Dart Competencies

Keahlian fundamental dan tingkat lanjut dalam bahasa pemrograman Dart yang mendasari Flutter.

- **Dart Fundamentals:** Pemahaman mendalam tentang tipe data, Object-Oriented Programming (OOP), _mixins_, _extension methods_, dan _null safety_.
- **Asynchronous Programming:** Penguasaan eksekusi kode asinkron menggunakan _Futures_, `async/await`, dan _Streams_ (termasuk _StreamControllers_).
- **Memory & Performance:** Pemahaman tentang cara kerja Dart _Garbage Collector_ dan eksekusi kode dalam _Isolates_ untuk komputasi berat tanpa memblokir UI.

---

## 2. Flutter Fundamentals & UI Styling

Kemampuan membangun antarmuka pengguna (UI) yang responsif, indah, dan berkinerja tinggi.

- **Widget Tree & Lifecycle:** Penguasaan siklus hidup komponen dasar seperti `StatelessWidget`, `StatefulWidget`, dan `InheritedWidget`.
- **Layout & Responsiveness:** Kemampuan membuat tata letak adaptif menggunakan `Row`, `Column`, `Flex`, `LayoutBuilder`, dan `MediaQuery` untuk berbagai ukuran layar.
- **Design Systems:** Penerapan komponen desain visual menggunakan _Material Design_ (Android) dan _Cupertino_ (iOS), serta pembuatan tema kustom.
- **Animations:** Implementasi animasi menggunakan _Implicit Animations_, _Explicit Animations_ (AnimationController), dan transisi layar kustom (Hero animations).

---

## 3. State Management & Data Handling

Pengelolaan alur data aplikasi dan pembaruan UI secara efisien.

- **Local State:** Pengelolaan _state_ sederhana menggunakan `setState` dan _ValueNotifier_.
- **Global State Management:** Penguasaan satu atau lebih pola arsitektur _state_ populer seperti **BLoC/Cubit**, **Riverpod**, **Provider**, atau **GetX**.
- **Data Parsing:** Serialisasi dan deserialisasi data JSON secara efisien menggunakan pustaka seperti `json_serializable` atau `freezed`.

---

## 4. API Integration & Local Storage

Manajemen sinkronisasi data dari server dan penyimpanan luring.

- **Network Requests:** Melakukan panggilan HTTP/REST API dengan efisien menggunakan pustaka `http` atau `dio`, serta menangani _error_ dan _interceptors_.
- **Local Storage:** Menyimpan data secara lokal menggunakan `shared_preferences` untuk data preferensi sederhana, atau basis data lokal seperti `sqflite`, `Hive`, atau `Isar` untuk data terstruktur.

---

## 5. Software Architecture & Clean Code

Penerapan prinsip desain perangkat lunak untuk menjaga kode agar mudah dipelihara dan diuji.

- **Design Patterns & Architecture:** Pemahaman tentang pola arsitektur seperti **Clean Architecture**, **MVVM**, atau **MVC**, serta pemisahan logika bisnis dari UI.
- **Dependency Injection:** Penggunaan pustaka seperti `get_it` atau `injectable` untuk mengelola dependensi dan _inversion of control_.
- **SOLID Principles:** Penerapan prinsip SOLID untuk menulis kode Dart yang modular dan dapat diskalakan.

---

## 6. Testing & Debugging

Memastikan kualitas aplikasi melalui pengujian otomatis dan pemecahan masalah.

- **Automated Testing:** Kemampuan menulis **Unit Tests** (untuk logika bisnis), **Widget Tests** (untuk komponen UI), dan **Integration Tests** (untuk alur pengguna penuh) menggunakan pustaka `flutter_test` dan `mockito`.
- **Debugging & Profiling:** Menggunakan **Flutter DevTools** untuk menganalisis memori, kinerja (_UI jank_), ukuran aplikasi, dan log jaringan.

---

## 7. Native Integration & Platform Channels

Berinteraksi dengan fitur spesifik sistem operasi native (Android/iOS).

- **Method Channels:** Kemampuan menulis kode platform-spesifik menggunakan _Platform Channels_ untuk berkomunikasi dengan Swift/Objective-C (iOS) dan Kotlin/Java (Android).
- **Permissions:** Mengelola izin aplikasi (_permissions_) untuk fitur seperti kamera, lokasi, atau penyimpanan menggunakan paket seperti `permission_handler`.

---

## 8. CI/CD & App Distribution

Otomatisasi build dan proses publikasi aplikasi.

- **CI/CD Pipelines:** Mengonfigurasi integrasi berkelanjutan menggunakan alat seperti **GitHub Actions**, **Bitrise**, atau **Codemagic** untuk menjalankan tes dan _build_ secara otomatis.
- **App Store & Play Store:** Memahami proses penandatanganan aplikasi (_App Signing_), pengelolaan rilis, dan publikasi ke **Google Play Store** dan **Apple App Store**.

---

## 9. Security & Third-Party Services

Keamanan aplikasi dan integrasi dengan layanan eksternal.

- **App Security:** Mengamankan data menggunakan `flutter_secure_storage`, mengimplementasikan _Certificate Pinning_, serta melakukan enkripsi dan _code obfuscation_.
- **Firebase & Cloud Services:** Integrasi layanan esensial seperti Push Notifications (FCM), Crashlytics, Analytics, dan Authentication.
