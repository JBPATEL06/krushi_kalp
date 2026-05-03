# Product: Krushi Kalp

Krushi Kalp is a mobile-first agricultural academic platform for students preparing for agricultural exams. It is a Flutter app targeting Android (primary) and iOS.

## Core Features

- **Mock Tests**: Practice exams with timer, scoring, and detailed post-test analytics
- **Resources**: Curated study materials (PDFs, documents) with in-app viewer
- **Store / Cart**: Purchase tests and resources via Razorpay payment gateway
- **User Library**: Access to purchased/unlocked content and downloads
- **Notifications**: Push notifications (FCM) and local notifications for updates
- **Admin Panel**: Content management, user management, and order management for admins
- **Chat**: Real-time chat UI for student support
- **Auth**: Email/password and Google Sign-In via Supabase Auth

## Target Users

- Agricultural students (primary)
- Admin/content managers (secondary)

## Backend

Supabase (PostgreSQL) is the primary backend. Firebase is used for Crashlytics, FCM push notifications, and Cloud Firestore (supplementary data). Razorpay handles payments.
