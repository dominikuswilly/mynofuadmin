# MyNofu Admin Dashboard

A premium Flutter-based admin application for NOFU Coffee, featuring secure login integration and real-time dashboard analytics.

## 🚀 Features

- **Secure Authentication**: Integrated with the NOFU Public Admin API.
- **Dynamic Dashboard**: Real-time stats for sales, orders, products, and customers.
- **Premium UI**: Modern design with smooth transitions and optimized layouts.
- **Optimized for Release**: Pre-configured with R8/ProGuard for minimal app size.

---

## 🛠️ Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (v3.0.0 or higher)
- [Android Studio](https://developer.android.com/studio) or VS Code
- Android SDK & Java 17+

### Installation

1. Clone the repository.
2. Install dependencies:
   ```bash
   flutter pub get
   ```

---

## 💻 How to Run

### Development Mode
To run the app on a connected device or emulator in debug mode:
```bash
flutter run
```

### Release Mode (Testing)
To test the performance on a physical device with release optimizations:
```bash
flutter run --release
```

---

## 📦 How to Release (Android)

The project is fully configured for Google Play Store release with signed App Bundles.

### 1. Signing Configuration
The app uses a signing key located at `android/app/upload-keystore.jks`. The credentials are managed in `android/key.properties`:

- **Key Alias**: `upload`
- **Keystore/Key Password**: `jagainoke`

> [!IMPORTANT]
> Keep `android/key.properties` and `android/app/upload-keystore.jks` secure. Do not commit them to public version control.

### 2. Build the App Bundle (AAB)
To generate the `.aab` file for the Play Store:
```bash
flutter build appbundle
```
The output will be located at:
`build/app/outputs/bundle/release/app-release.aab`

### 3. Build the APK (Optional)
If you need a universal APK for manual distribution:
```bash
flutter build apk --release
```
The output will be located at:
`build/app/outputs/flutter-apk/app-release.apk`

---

## 🔧 Maintenance

### Troubleshooting Gradle Errors
If you encounter "Multiple build operations failed" or cache errors:
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
```

### Updating API Endpoints
Login API integration can be found in `lib/login_screen.dart`. Ensure the `x-request-id` header is updated if required by the backend.
