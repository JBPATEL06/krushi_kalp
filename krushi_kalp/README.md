Here's the precise prompt to give to Claude (Antigravity) for implementing the About Page:

---

**PROMPT FOR ANTIGRAVITY:**

```
Using the Krushi Kalp unified project context (CLAUDE.md), implement a complete 
"About Page" feature with two modes: a read-only User view and a fully editable 
Admin view. The design must match the existing screenshot reference provided.

---

## FEATURE OVERVIEW

Create two screens sharing the same data source:
1. `lib/presentation/screens/about_screen.dart` — User-facing read-only About page
2. `lib/presentation/screens/admin/admin_about_screen.dart` — Admin-facing editable version

---

## DATA CONTRACT — `app_config` Table

All About Page content is stored under a single key in the `app_config` table:

**Key:** `about_page`
**Value (JSONB):**
```json
{
  "app_name": "Krushi Kalp",
  "version": "2.4.0",
  "tagline": "EMPOWERING AGRICULTURE STUDENTS",
  "mission": "Krushi Kalp is dedicated to bridging the gap between academic learning and professional excellence for agricultural students. We provide a comprehensive digital ecosystem for mastering core concepts through curated resources, rigorous testing, and data-driven insights.",
  "features": [
    {
      "icon": "quiz",
      "title": "Adaptive Mock Tests",
      "subtitle": "Personalized exam simulations"
    },
    {
      "icon": "menu_book",
      "title": "Study Materials",
      "subtitle": "Curated agricultural curriculum"
    },
    {
      "icon": "bar_chart",
      "title": "Real-time Analytics",
      "subtitle": "Track your progress and rankings"
    }
  ],
  "support": {
    "email": "support@krushikalp.com",
    "address": "Agricultural University Hub, Delhi",
    "support_label": "Need Support?",
    "support_description": "Our academic advisors are here to help you excel."
  },
  "footer_text": "MADE WITH EXCELLENCE FOR INDIA'S FUTURE FARMERS"
}
```

---

## STEP 1 — Extend `AppConfigService`

Add these two methods to `lib/data/services/app_config_service.dart`:

```dart
/// Fetches the about_page config block.
Future<Map<String, dynamic>> fetchAboutConfig() async {
  final response = await Supabase.instance.client
      .from('app_config')
      .select('value')
      .eq('key', 'about_page')
      .single();
  return Map<String, dynamic>.from(response['value'] as Map);
}

/// Upserts the entire about_page config block.
Future<void> updateAboutConfig(Map<String, dynamic> data) async {
  await Supabase.instance.client
      .from('app_config')
      .upsert({'key': 'about_page', 'value': data});
}
```

---

## STEP 2 — User Screen (`about_screen.dart`)

**Route:** Add `'/about'` to the app router. Accessible from `ProfileScreen` via a 
List tile "About Krushi Kalp" with `Icons.info_outline`.

**Layout (matches screenshot exactly):**

```
Scaffold
└── CustomScrollView
    ├── SliverAppBar (title: "About Krushi Kalp", pinned)
    └── SliverPadding
        └── Column
            ├── _HeroCard         — App logo (assets/images/playstore.png), 
            │                       app_name, version chip, tagline
            ├── SizedBox(AppSpacing.md)
            ├── _MissionCard      — "✦ Our Mission" header + mission text body
            ├── SizedBox(AppSpacing.md)
            ├── _KeyFeaturesSection — "Key Features" heading + list of 
            │                         _FeatureTile rows (icon, title, subtitle)
            ├── SizedBox(AppSpacing.md)
            ├── _SupportCard      — Dark indigo card: support_label, 
            │                       support_description, email row, address row
            └── _FooterText       — footer_text centered, letter-spaced caption
```

**Design tokens (Token Law — no raw values):**
- Colors: `AppTheme.colors.primary`, `AppTheme.colors.surface`, 
  `AppTheme.colors.onSurface`, `AppTheme.colors.secondary`
- Spacing: `AppSpacing.xs/sm/md/lg/xl`
- Radius: `AppRadius.md`, `AppRadius.lg`
- Typography: `AppTypography.display`, `AppTypography.heading`, 
  `AppTypography.bodyLarge`, `AppTypography.bodyLabel`
- Motion: `AppMotion.normal` for any fade-ins

**Loading state:** Show `shimmer` skeleton cards matching each section's height 
while `FutureBuilder` awaits `AppConfigService().fetchAboutConfig()`.

**Error state:** Use existing `NetworkErrorState` widget pattern.

**Edge-to-edge bottom:** Apply 
`padding: EdgeInsets.only(bottom: AppSpacing.md + MediaQuery.of(context).padding.bottom)` 
on the last item.

---

## STEP 3 — Admin Screen (`admin_about_screen.dart`)

**Route:** Add as a navigation item inside `ManageAppScreen` as a new tab 
**"About Page"** (tab index 4), using `Icons.info_outline`. Follow the exact 
same tab pattern as `feature_control_tab.dart`, `banner_management_tab.dart`, etc.

**Layout:**

```
Scaffold
└── FutureBuilder<Map>(fetchAboutConfig)
    └── SingleChildScrollView
        └── Column
            ├── _AdminHeroSection    — Preview card (same as user HeroCard, 
            │                          read-only preview) + "Edit Branding" 
            │                          ExpansionTile below it containing:
            │                          • app_name TextField
            │                          • version TextField  
            │                          • tagline TextField
            ├── _AdminMissionSection — "Mission Statement" ExpansionTile:
            │                          • mission TextFormField (maxLines: 6)
            ├── _AdminFeaturesSection— "Key Features" section:
            │                          • ListView of editable feature tiles
            │                          • Each tile: icon picker dropdown, 
            │                            title field, subtitle field, delete btn
            │                          • "Add Feature" outlined button at bottom
            ├── _AdminSupportSection — "Support Info" ExpansionTile:
            │                          • support_label TextField
            │                          • support_description TextField
            │                          • email TextField (keyboardType: email)
            │                          • address TextField
            ├── _AdminFooterSection  — "Footer Text" ExpansionTile:
            │                          • footer_text TextField
            └── _SaveButton          — Full-width AppButton "Save Changes"
                                        calls updateAboutConfig(), shows 
                                        SnackBar on success/failure
```

**Admin-specific rules:**
- All `ExpansionTile` sections start **collapsed** to reduce cognitive load.
- Each section has its own local `_isSaving` bool so only the Save button 
  shows a `CircularProgressIndicator` during the async call.
- Icon picker for features: show a `DropdownButtonFormField` with these 
  options mapped to `Icons.*`:
  `quiz`, `menu_book`, `bar_chart`, `science`, `agriculture`, 
  `school`, `emoji_events`, `chat`, `download`, `star`
- The icon string stored in JSON maps to Flutter `Icons` via a helper:
  ```dart
  static IconData iconFromString(String name) {
    const map = {
      'quiz': Icons.quiz,
      'menu_book': Icons.menu_book,
      'bar_chart': Icons.bar_chart,
      'science': Icons.science,
      'agriculture': Icons.agriculture,
      'school': Icons.school,
      'emoji_events': Icons.emoji_events,
      'chat': Icons.chat,
      'download': Icons.download,
      'star': Icons.star,
    };
    return map[name] ?? Icons.help_outline;
  }
  ```
- **Add Feature**: appends a new entry 
  `{"icon": "star", "title": "", "subtitle": ""}` to the features list 
  and expands its tile immediately.
- **Delete Feature**: shows a confirmation `AlertDialog` before removing.
- **Validation**: `app_name`, `version`, `email`, `mission` are required. 
  Show inline `errorText` if empty on save attempt.
- Save calls `AppConfigService().updateAboutConfig(updatedMap)` and on 
  success shows `ScaffoldMessenger` snackbar: "About page updated successfully".

---

## STEP 4 — Wire Up Navigation

### User App
In `lib/presentation/screens/profile_screen.dart`, add a `ListTile` in the 
"App Info" section:
```dart
ListTile(
  leading: Icon(Icons.info_outline),
  title: Text('About Krushi Kalp'),
  trailing: Icon(Icons.chevron_right),
  onTap: () => Navigator.pushNamed(context, '/about'),
)
```

### Admin Panel
In `lib/presentation/screens/admin/manage_app/manage_app_screen.dart`, 
add a 5th tab:
```dart
Tab(icon: Icon(Icons.info_outline), text: 'About Page')
```
And add `AdminAboutScreen()` to the `TabBarView` children list.

---

## STEP 5 — Initial Data Seed (SQL)

Add this migration to `lib/data/sql/`:

```sql
-- Migration: seed_about_page_config.sql
INSERT INTO public.app_config (key, value, description)
VALUES (
  'about_page',
  '{
    "app_name": "Krushi Kalp",
    "version": "2.4.0",
    "tagline": "EMPOWERING AGRICULTURE STUDENTS",
    "mission": "Krushi Kalp is dedicated to bridging the gap between academic learning and professional excellence for agricultural students. We provide a comprehensive digital ecosystem for mastering core concepts through curated resources, rigorous testing, and data-driven insights.",
    "features": [
      {"icon": "quiz", "title": "Adaptive Mock Tests", "subtitle": "Personalized exam simulations"},
      {"icon": "menu_book", "title": "Study Materials", "subtitle": "Curated agricultural curriculum"},
      {"icon": "bar_chart", "title": "Real-time Analytics", "subtitle": "Track your progress and rankings"}
    ],
    "support": {
      "email": "support@krushikalp.com",
      "address": "Agricultural University Hub, Delhi",
      "support_label": "Need Support?",
      "support_description": "Our academic advisors are here to help you excel."
    },
    "footer_text": "MADE WITH EXCELLENCE FOR INDIA''S FUTURE FARMERS"
  }'::jsonb,
  'About page content — editable by admin from Manage App > About Page tab'
)
ON CONFLICT (key) DO NOTHING;
```

---

## STRICT RULES — DO NOT VIOLATE

1. **Token Law**: Zero raw pixel values, raw colors, or raw durations anywhere in UI. 
   Only `AppSpacing.*`, `AppRadius.*`, `AppTypography.*`, `AppTheme.colors.*`, `AppMotion.*`.

2. **Edge-to-Edge**: No `SafeArea(bottom: true)`. Use 
   `MediaQuery.of(context).padding.bottom` added to bottom content padding.

3. **No new packages**: Use only packages already in `pubspec.yaml`. 
   No `cached_network_image`, no new state packages.

4. **Provider pattern**: Both screens use `FutureBuilder` with 
   `AppConfigService` directly — no new Provider needed for this feature.

5. **Deprecated Material 3 members**: Use `.withValues(alpha: ...)` 
   not `.withOpacity()`. Use `surfaceContainerHighest` not `surfaceVariant`. 
   Use `surface` not `background`.

6. **Async safety**: All async methods check `if (!mounted) return;` before 
   calling `setState` or `Navigator`.

7. **0 analyze errors**: After implementation, `flutter analyze` must show 
   zero errors and zero warnings. Remove all unused variables/imports.

8. **File naming**: snake_case. New files:
   - `lib/presentation/screens/about_screen.dart`
   - `lib/presentation/screens/admin/admin_about_screen.dart`
   - `lib/data/sql/seed_about_page_config.sql`

9. **Do not modify** `main.dart`, any existing Provider, or any Service 
   other than appending to `app_config_service.dart`.

10. **Dark mode**: All cards and text must respond correctly to 
    `ThemeMode.system`. Test both light (Indigo+Saffron) and dark 
    (Forest Sage + Emerald #2DD4BF) themes mentally before writing code.

---

Deliver all three files completely. No placeholders, no `// TODO` comments. 
Production-ready code only.
```

---

This prompt gives Antigravity everything it needs: the exact data schema, JSON structure, layout breakdown matching your screenshot, the service methods to add, all navigation wiring, the SQL seed, and every constraint from your design system. Just paste it directly.