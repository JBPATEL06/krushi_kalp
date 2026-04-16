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
