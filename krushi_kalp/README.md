# Krushi Kalp - Agricultural Academic Platform

A comprehensive digital ecosystem for agricultural students, providing curated resources, mock tests, and analytics.

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (v3.0.0 or higher)
- [Dart SDK](https://dart.dev/get-started)
- [Supabase Account](https://supabase.com/) for backend services.

### Installation Steps
1.  **Clone the Repository**:
    ```bash
    git clone https://github.com/JBPATEL06/krushi_kalp.git
    cd krushi_kalp
    ```
2.  **Install Dependencies**:
    ```bash
    flutter pub get
    ```
3.  **Environment Setup**:
    -   Create a `.env` file in the root directory.
    -   Add the following variables (replacing with your Supabase credentials):
        ```env
        SUPABASE_URL=your_supabase_url
        SUPABASE_ANON_KEY=your_supabase_anon_key
        ```
4.  **Database Initialization**:
    -   Execute the SQL scripts found in `lib/data/sql/` in your Supabase SQL Editor to set up the required tables and initial data.
5.  **Run the Application**:
    ```bash
    flutter run
    ```

## 📦 Backup Strategy

Before launching or making major changes, ensure you have backups of the following critical files:

### 1. Configuration & Security
- **`.env`**: Contains API keys, Supabase credentials, and environment-specific settings. **CRITICAL: This file should never be committed to git.**
- **`pubspec.yaml`**: Defines project dependencies, assets, and versioning.

### 2. Firebase Integration
- **`android/app/google-services.json`**: Required for Firebase services on Android.
- **`ios/Runner/GoogleService-Info.plist`**: Required for Firebase services on iOS.

### 3. Database & Backend
- **`lib/data/sql/`**: Contains all SQL initialization, seed data, and migration scripts.
- **`lib/data/services/app_config_service.dart`**: Core logic for handling application configurations.

### 4. Brand & Identity
- **`assets/images/`**: Contains logos, banners, and other visual assets.
  - `playstore.png`: Primary app logo and launcher icon.
  - `notification_logo.png`: Icon used for push notifications.
  - `homeBanner.png`: Main banner used on the home screen.

### 5. Deployment Keys
- **Signing Keys**: Any `.jks` or `.keystore` files used for signing the Android APK/App Bundle.
- **Export Options**: `ios/exportOptions.plist` if using custom CI/CD for iOS.
