# Krushi Kalp — Gemini Issue Fix Plan

> This document is a structured action plan for the AI agent (Gemini/Claude) to follow when fixing identified issues in this project. All issues were verified by reading actual source files.
> Read `CLAUDE.md` for full project context before starting.

---

## ⚡ Priority Order

Fix in this order: **CRITICAL → HIGH → MEDIUM → DEAD CODE**

---

## 🔴 CRITICAL FIX 1 — N+1 Signed URL Cache

**Why**: Every app open or Realtime stream tick fires `createSignedUrl()` individually per test/resource. 50 tests = 100 Supabase Storage API calls per refresh. At scale this causes heavy billing.

**Files to edit**:
- `lib/data/services/test_service.dart` → `_populateSignedUrls()`
- `lib/data/services/resource_service.dart` → `_signResources()`

**What to do**:

1. Add an in-memory URL cache `Map<String, _SignedUrlEntry>` near the top of each service class:

```dart
class _SignedUrlEntry {
  final String url;
  final DateTime expiresAt;
  _SignedUrlEntry(this.url, this.expiresAt);
  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

// In TestService class body:
final Map<String, _SignedUrlEntry> _urlCache = {};
```

2. In `_populateSignedUrls()`, before calling `createSignedUrl()`, check the cache:

```dart
Future<String?> _getSignedUrlCached(String path, {int ttlSeconds = 60 * 60 * 22}) async {
  final cached = _urlCache[path];
  if (cached != null && !cached.isExpired) return cached.url;
  
  final url = await _supabase.storage.from('mock_test').createSignedUrl(path, 60 * 60 * 24);
  _urlCache[path] = _SignedUrlEntry(url, DateTime.now().add(Duration(seconds: ttlSeconds)));
  return url;
}
```

3. Replace all `createSignedUrl()` calls inside `_populateSignedUrls()` and `_signResources()` with `_getSignedUrlCached()`.

4. TTL: Generate URLs for 24 hours, cache them for 22 hours to give a 2-hour safety buffer before expiry.

---

## 🔴 CRITICAL FIX 2 — Stop Stream Triggering Full URL Regeneration

**Why**: `streamMockTests()` calls `_populateSignedUrls()` on every Realtime tick, bypassing any list-level cache.

**File**: `lib/data/services/test_service.dart:98-108`

**What to do**:

After applying Fix 1 above, the URL-level cache will protect this. But additionally, add a debounce to the stream so rapid DB events don't all trigger reprocessing:

```dart
Stream<List<MockTest>> streamMockTests() {
  return _supabase
      .from('mock_tests')
      .stream(primaryKey: ['test_id'])
      .order('created_at', ascending: false)
      .debounceTime(const Duration(seconds: 2)) // ← Add this (requires rxdart)
      .asyncMap((data) async {
        List<MockTest> tests = await compute(_parseMockTests, data as List<dynamic>);
        return await _populateSignedUrls(tests); // Now uses cache from Fix 1
      });
}
```

If `rxdart` is not desired here, wrap the stream in a `distinct()` call to skip identical events.

---

## 🟠 HIGH FIX 3 — FCM Token: Only Write to DB When Changed

**Why**: Every app launch calls `_saveTokenToDatabase(token)` which does a Supabase DB `update` even when the token hasn't changed.

**File**: `lib/data/services/fcm_service.dart:135-143`

**What to do**: Add a `SharedPreferences` check before writing:

```dart
// In initialize(), replace the token saving block with:
String? token = await _firebaseMessaging.getToken();
if (token != null) {
  final prefs = await SharedPreferences.getInstance();
  final savedToken = prefs.getString('fcm_token_saved');
  if (savedToken != token) {
    await _saveTokenToDatabase(token);
    await prefs.setString('fcm_token_saved', token);
  }
}

// Also update onTokenRefresh to save to prefs:
_firebaseMessaging.onTokenRefresh.listen((newToken) async {
  await _saveTokenToDatabase(newToken);
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('fcm_token_saved', newToken);
});
```

---

## 🟠 HIGH FIX 4 — Throttle Google Translate Requests

**Why**: `translateBatch()` fires 400–500 parallel HTTP requests for a 100-question exam, causing rate-limiting and exam failures.

**File**: `lib/data/services/translation_service.dart:50-52`

**What to do**: Replace `Future.wait(futures)` with a chunked sequential approach:

```dart
static Future<List<Question>> translateBatch(List<Question> questions) async {
  const chunkSize = 5; // Translate 5 at a time
  final results = <Question>[];
  
  for (int i = 0; i < questions.length; i += chunkSize) {
    final chunk = questions.sublist(i, (i + chunkSize).clamp(0, questions.length));
    final translated = await Future.wait(chunk.map((q) => translateQuestion(q)));
    results.addAll(translated);
    // Small delay to avoid rate-limiting
    if (i + chunkSize < questions.length) {
      await Future.delayed(const Duration(milliseconds: 300));
    }
  }
  return results;
}
```

---

## 🟡 MEDIUM FIX 5 — `if (true)` Dead Branch Cleanup

**Why**: Always-true condition is dead scaffolding left from debugging. Confusing and misleading.

**File**: `lib/data/services/fcm_service.dart:15`

**What to do**: Remove the `if (true)` wrapper entirely. Keep the code block inside it, just un-indent one level.

Before:
```dart
if (true) {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = ...
  ...
}
```
After:
```dart
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = ...
...
```

---

## 🟡 MEDIUM FIX 6 — Full Table Scan for Categories & Languages

**Why**: `fetchCategories()` and `fetchLanguages()` fetch all rows from `mock_tests` just to get distinct values. Wasteful as the table grows.

**File**: `lib/data/services/test_service.dart:60-96`

**What to do**:

Step 1 — Create RPC functions in Supabase SQL Editor:
```sql
CREATE OR REPLACE FUNCTION get_distinct_categories()
RETURNS SETOF text AS $$
  SELECT DISTINCT category FROM mock_tests WHERE category IS NOT NULL ORDER BY category;
$$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION get_distinct_languages()
RETURNS SETOF text AS $$
  SELECT DISTINCT language FROM mock_tests WHERE language IS NOT NULL AND language != '';
$$ LANGUAGE sql;
```

Step 2 — Update the Dart methods to call the RPC:
```dart
Future<List<String>> fetchCategories() async {
  try {
    final response = await _supabase.rpc('get_distinct_categories');
    return List<String>.from(response as List);
  } catch (e) {
    return [];
  }
}
```

---

## 🟡 MEDIUM FIX 7 — Remove Unreferenced Realtime Channel

**Why**: `getOffersChannel()` in `test_service.dart` creates a Realtime channel object that is never subscribed to anywhere. Dead code and a potential socket leak if someone calls it by accident.

**File**: `lib/data/services/test_service.dart:19-21`

**What to do**: Delete the following method entirely.
```dart
// DELETE THIS:
RealtimeChannel getOffersChannel() {
  return _supabase.channel('public:offers:realtime');
}
```
Verify by running `grep -r "getOffersChannel" lib/` — should return zero results confirming it is safe to delete.

---

## 🗑️ DEAD CODE REMOVAL

All items below are **verified by code review**. Safe to delete with zero impact on running features.

### Delete File 1 — `theme_test_screen.dart`
- **Path**: `lib/presentation/screens/theme_test_screen.dart`
- **Why**: 162-line dev-only token test scaffold. Zero imports referencing it anywhere in the project.
- **Action**: Delete the file. Run `flutter analyze` — no new errors should appear.

### Delete File 2 — `feedback_model.dart`
- **Path**: `lib/domain/models/feedback_model.dart`
- **Why**: Orphan model (31 lines). `FeedbackModel` class and `FeedbackStatus` enum are defined but never imported or used by any other file.
- **Action**: Delete the file. Run `flutter analyze` — no new errors should appear.

### Remove Dead Members in `resource_detail_screen.dart`
- **Path**: `lib/presentation/screens/resource_detail_screen.dart`
- **Lines to remove**:
  - Line 48: `bool _isDownloading = false;`
  - Line 49: `bool _isAddingToCart = false;`
  - Lines 155–190: entire `_openPdf()` method
  - Lines 192–227: entire `_addToCart()` method
- **Why**: Both methods are fully implemented but never called from `build()` or anywhere else. The current UI uses `DirectCheckoutSheet` and `PdfService` instead. The fields only mutate state inside these dead methods, so nothing in the UI reads them.
- **Caution**: Before removing `_openPdf`, verify the current PDF-opening flow works correctly via `PdfService`. Both methods can be removed safely as they are unreachable.

### Remove 4 Unused Imports in `cart_screen.dart`
- **Path**: `lib/presentation/screens/cart_screen.dart`
- **Lines to remove**:
  - Line 10: `import '../../data/services/resource_service.dart';`
  - Line 14: `import '../../domain/models/resource.dart';`
  - Line 15: `import '../../domain/models/mock_test.dart';`
  - Line 18: `import '../../utils/responsive.dart';`
- **Why**: Confirmed unused by `flutter analyze`. None of these types or functions are referenced in `cart_screen.dart`'s code.
- **Action**: Delete these 4 import lines. Run `flutter analyze` — the 4 `unused_import` warnings should disappear.

---

## ✅ Verification After All Fixes

Run these commands after completing all fixes:

```bash
# 1. Check for lint errors (should be near-zero warnings)
flutter analyze

# 2. Check app still builds
flutter build apk --obfuscate --split-debug-info=debug-info/

# 3. Manual test checklist:
# - Open app → test list loads without visible delay
# - Scroll test list → no excessive waiting
# - Switch away and come back → URLs load from cache (instant)
# - Admin broadcast notification → received on user device
# - Gujarati language in exam → questions translate correctly
```

---

## 📝 Notes for the AI Agent

- Do NOT remove `excel`, `pdf`, or `flutter_chat_ui` packages — they are core to the business model.
- Do NOT touch `translator` package replacement without user approval — it requires pre-translated Supabase content strategy.
- The `.env` security issue (#6 in original report) is a known Flutter limitation — document it but do not attempt to fix without user discussion.
- After each fix, run `flutter analyze` to confirm no regressions.
- Fixes 1 & 2 together are the highest ROI — implement them first.
