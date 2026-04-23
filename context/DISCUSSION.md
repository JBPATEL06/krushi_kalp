# Discussion & Decisions Log

## 2026-04-16: Phase 1 Completion & Crash Analysis

### Discussion: Background Service Stabilization and UX Polish
- **Problem**: 
    1. Background isolate crashes when recording errors to Crashlytics because Firebase is not initialized.
    2. Notifications show raw system filenames (e.g. `result_123.pdf`), which lacks clarity and looks unprofessional.
    3. Storage images (signed URLs) returning 404 for some assets.
- **Proposed Solution**:
    1. Initialize Firebase inside the background isolate `onStart` entry point.
    2. Add `itemName` metadata to `UploadTask` to store human-readable names.
    3. Update `BackgroundUploadService.uploadFile` and UI call-sites.
    4. Enhance `SupabaseUrlHelper` with better logging for 404 tracking.
- **Risks**: 
    - None significant; slight memory increase in background isolate for Firebase.
- **Decision**: Implement `itemName` across the stack and ensure Firebase is ready for crash reporting in the background.
- **Branch Choice**: `fix/background-crashes-and-ux` (Requested user confirmation)
- **Status**: Pending approval of [implementation_plan.md](file:///C:/Users/jeelp/.gemini/antigravity/brain/86259068-81e8-47ba-8267-729d7e93cf6e/implementation_plan.md)

### Topic: Background Isolate Stability
- **Problem**: UI was freezing or crashing when generating/uploading large PDF results due to heavy lifting on the main thread. Isolates were also being terminated without proper cleanup.
- **Decision**: Implemented `BackgroundUploadService` with a static worker isolate.
- **Validation**:
  - RENAMED `_generateAndDownloadPdf` to `_generateAndUploadPdf` throughout `TestResultScreen` to resolve "MethodNotFound" runtime errors.
  - Added `runZonedGuarded` in `main.dart` to prevent uncaught async errors from killing the app process.
  - Implemented automatic notification cleanup on boot to prevent "Ghost Notifications".
  - Verified static analysis for the new Isolate bridge.

### Topic: UI Aesthetics & Fallbacks
- **Problem**: Users noted that images were missing in some tests and the error state looked "broken".
- **Decision**: Added a "Premium Gradient Placeholder" in `MockTestDetailScreen`.
- **Outcome**: Tests without images now appear Intentional and high-quality rather than "empty".

## Branch Confirmation
- **Status**: Work performed on `fix/mock-test-anr-freeze`.
- **Active**: Yes.

## Conclusion on Crashes
By offloading all storage and network operations to a **managed background isolate** and wrapping the entry point in a **Global Error Zone**, the primary causes of the observed ANRs (Application Not Responding) and "Method Not Found" crashes are effectively neutralized.

## 2026-04-18: PDF UX & Profile Stability

### Discussion: PDF Generation UX Refactor
- **Problem**: PDF generation used a blocking modal dialog that made the app feel "frozen" and "unresponsive". Users couldn't cancel, and there was a risk of data loss if they navigated away.
- **Decision**: 
    - Replaced the modal with **Inline Progress** inside the Download button.
    - Added a **Cancel** button to abort the process.
    - Implemented **Safe-Exit Protection** via `PopScope` to warn users if a PDF is unsaved.
- **Outcome**: The experience feels much faster and safer.

### Discussion: Profile Stability & Linking
- **Problem**: 
    1. Users on 5G reported occasional "network errors" on the Profile screen due to `StreamBuilder` overhead.
    2. The "Link Google" button was always visible, leading to redundant clicks or confusion.
- **Decision**:
    - Converted `ProfileScreen` to `FutureBuilder` to reduce constant socket connections for static data.
    - Implemented **Conditional Visibility**: The "Link Google Account" button now hides automatically if a Google provider is already detected in the user's identities.
    - Integrated `ErrorUtils` to handle the specific "identity already linked" (conflict) scenario gracefully with user-friendly feedback.
- **Branch**: `fix/profile-future-pdf-ux`
- **Status**: Completed and Verified.

## 2026-04-23: NDK Build Resolution & Production AAB
- **Problem**: Persistent NDK build failure blocking production AAB generation. Environment was mismatching NDK versions.
- **Solution**: 
    1. Configured Android SDK to include NDK r27.0.12077973.
    2. Verified project structure and ensured `flutter build appbundle` is run from the correct root (`krushi_kalp`).
    3. Successfully generated `build\app\outputs\bundle\release\app-release.aab` (v1.0.1+7).
- **Outcome**: The production build pipeline is now clear and stable.
- **Status**: Completed.

