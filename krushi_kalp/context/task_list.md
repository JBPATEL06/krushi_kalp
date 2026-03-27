# 📋 Krushi Kalp Master Task List

## Phase 1: Database Bill Protection & Speed Optimization
- [x] Install and configure `isar` database dependencies.
- [x] Create Isar Database Schemas specifically for `Mock Tests`, `Offers`, and `Resources`.
- [x] Refactor the app's fetching logic so that data prioritizes the Local DB, refreshing from the network silently in the background.
- [x] Keep `NotificationService` `.channel()` intact to preserve active push notifications.

## Phase 2: Secure Server-Side Pricing (Pure SQL)
- [x] Write a Pure PostgreSQL RPC Function (`calculate_secure_price`) in Supabase.
- [x] Ensure the SQL Function accurately replicates the existing 'Fake vs Real' offer UI logic without altering the user experience.
- [x] Update Flutter `TestService.checkout()` to fetch the price directly from the new SQL RPC before launching Razorpay.
- [x] Verify checkout success logic rigorously to prevent tampering.

## Phase 3: Architecture Upgrades (Post-Security)
- [ ] Substitute existing `Provider` architecture with `Riverpod 3.0` Notifiers.
- [ ] Convert legacy `http` calls into `Dio` networks with strict global Interceptors.
- [ ] Map out all deep links and transfer routing logic to `GoRouter`.
- [ ] Replace `flutter_dotenv` with `envied` to obfuscate API keys.

---
**Testing Protocol:** 
*After every single completed checkbox, the app MUST be built and manually verified to ensure no existing functionality was broken.*
