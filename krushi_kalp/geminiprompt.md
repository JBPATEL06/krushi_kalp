You are working on Krushi Kalp — a Flutter app with a unified User + Admin codebase.
Read CLAUDE.md (path:krushi_kalp\CLAUDE.md) fully before writing a single line of code.

⚠️ NEW UPDATE IN THIS PROMPT — READ BEFORE STARTING

This prompt has 3 corrections added since the last version.
Apply ALL of them. Do not skip any section marked NEW UPDATE.

NEW UPDATE 1 — Streak 5-min rule (pdf_viewer_screen.dart):
  Only call updateUserStreak if duration >= 300 seconds (5 minutes).
  If user closes PDF before 5 min → skip the call entirely, do nothing.
  Test attempt always triggers streak regardless of duration.

NEW UPDATE 2 — Chart shows study TIME not test count:
  weekly_minutes[i] = total minutes studied that day (reading + tests combined).
  The 7-day bar chart is a STUDY TIME chart.
  Bar height = minutes that day. Today bar label = "${weeklyMinutes[6]}m".
  Flutter only reads and displays this array — no calculation needed.

NEW UPDATE 3 — Where cards appear:
  USER CARD → goes INSIDE _BannerAutoSlider PageView as slot 0.
    itemCount = banners.length + 1
    index 0 → PerformanceCard (FutureBuilder loads data)
    index 1+ → real banners (use index - 1 to get banner)
    Dot indicators include slot 0.
    Pass userId as param to _BannerAutoSlider.

  ADMIN CARD → full width static card at very top of
    SingleChildScrollView Column, BEFORE
    _buildSectionHeader('MANAGEMENT QUICK ACCESS').
    Not in PageView. Not scrollable horizontally.
    Loads via FutureBuilder using _adminPerformanceFuture.
    Resets on _onRefresh() together with other streams.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
ORIGINAL PROMPT CONTINUES BELOW
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
CONTEXT — WHAT IS ALREADY DONE (DO NOT RECREATE)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Supabase table already exists:
  user_streaks (
    user_id uuid PK FK → users.id,
    streak_count integer DEFAULT 0,
    last_active_date date,
    longest_streak integer DEFAULT 0,
    weekly_study_minutes jsonb DEFAULT '[0,0,0,0,0,0,0]',
    total_study_minutes integer DEFAULT 0,
    updated_at timestamptz DEFAULT now()
  )

  weekly_study_minutes array layout:
    Index 0 = 6 days ago
    Index 1 = 5 days ago
    Index 2 = 4 days ago
    Index 3 = 3 days ago
    Index 4 = 2 days ago
    Index 5 = yesterday
    Index 6 = TODAY ← always the rightmost bar in chart

  Array rotation happens INSIDE the SQL function on the DB side.
  Flutter never rotates, calculates, or modifies this array directly.
  Flutter only READS it and DISPLAYS it as-is.

Supabase SQL functions already deployed and working:

  1. update_user_streak(p_user_id, p_duration_seconds, p_activity_type)
     - p_activity_type is either 'test_attempt' or 'resource_read'
     - Triggers streak if: p_duration_seconds >= 300 OR type = 'test_attempt'
     - If last_active_date = today → adds minutes to index 6, NO streak increment
     - If last_active_date = yesterday → streak+1, rotates array left, sets index 6
     - If older → resets streak to 1, rotates array, sets index 6
     - UPSERT — creates row if not exists
     - Returns void

  2. get_user_performance(p_user_id uuid) returns jsonb:
     {
       "streak": 3,              ← from user_streaks.streak_count
       "avg_score": 72.5,        ← AVG(score_obtained) from results table
       "tests_completed": 8,     ← COUNT(DISTINCT test_id) from results table
       "best_score": 95.0,       ← MAX(score_obtained) from results table
       "weekly_minutes": [0,30,0,45,60,20,6]  ← from user_streaks.weekly_study_minutes
     }

  3. get_admin_performance() returns jsonb:
     {
       "today_revenue": 1250,
       "weekly_new_users": 12,
       "tests_sold_week": 34,
       "top_test_title": "GK Set 1",
       "top_test_attempts": 145,
       "platform_avg_rating": 4.3,
       "completion_rate": 78.5
     }

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
FULL DATA FLOW — READ THIS CAREFULLY
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

── HOW STREAK INCREASES ──────────────────

TRIGGER 1 — Mock Test Submitted:
  Location: test_result_screen.dart
  When: After result is successfully saved to Supabase (inside the success callback)
  What to send:
    p_duration_seconds = result.timeTakenSeconds (already stored in result model)
    p_activity_type = 'test_attempt'
  Why 'test_attempt' always triggers regardless of duration:
    The SQL function treats 'test_attempt' as always qualifying.
    Even a 30-second test attempt counts as study activity for that day.

TRIGGER 2 — PDF Resource Read:
  Location: pdf_viewer_screen.dart
  How to measure read time:
    - In State.initState(): record _openedAt = DateTime.now()
    - In State.dispose(): calculate duration = DateTime.now().difference(_openedAt).inSeconds
    - Only call update_user_streak if duration >= 300 (5 minutes)
    - If user closes PDF after 2 minutes → do NOT call the function at all
    - If user reads for 7 minutes → call with duration=420, type='resource_read'
  What to send:
    p_duration_seconds = duration (in seconds, integer)
    p_activity_type = 'resource_read'

BOTH TRIGGERS:
  - Fire and forget — use .ignore() on the Future, never await
  - Never show any UI for this call
  - Never setState after this call
  - If it fails silently, streak just doesn't update — acceptable

── HOW WEEKLY MINUTES WORKS ──────────────

The DB returns weekly_minutes as a 7-element array already in the right order:
  [index0, index1, index2, index3, index4, index5, index6]
  [6daysAgo, 5daysAgo, 4daysAgo, 3daysAgo, 2daysAgo, yesterday, TODAY]

Flutter just maps each index to a bar in the chart left-to-right:
  Bar 0 (leftmost)  = weekly_minutes[0] = 6 days ago
  Bar 1             = weekly_minutes[1] = 5 days ago
  Bar 2             = weekly_minutes[2] = 4 days ago
  Bar 3             = weekly_minutes[3] = 3 days ago
  Bar 4             = weekly_minutes[4] = 2 days ago
  Bar 5             = weekly_minutes[5] = yesterday
  Bar 6 (rightmost) = weekly_minutes[6] = TODAY ← highlighted bar

Day labels below bars (always fixed, never calculated):
  Bar 0 → label = today's weekday minus 6 days
  IMPORTANT: Calculate dynamically using DateTime.now():
    final today = DateTime.now().weekday; // 1=Mon, 7=Sun
    final labels = List.generate(7, (i) {
      final day = DateTime.now().subtract(Duration(days: 6 - i));
      return ['M','T','W','T','F','S','S'][day.weekday - 1];
    });
  This way labels always show correct days relative to today.
  Today's label (index 6) is highlighted in primary color.

Chart bar height calculation:
  final maxMinutes = weeklyMinutes.reduce(max).clamp(1, 9999);
  // clamp to 1 to avoid division by zero when all bars are 0
  heightFactor = weeklyMinutes[i] / maxMinutes
  // heightFactor range: 0.0 to 1.0
  // If minutes == 0: show stub bar at heightFactor = 0.08
  // If minutes > 0: show bar proportional to max, minimum heightFactor = 0.12

Today's bar special treatment:
  - Full primary color opacity (not 35% like other bars)
  - Show minute label ABOVE bar: "${weeklyMinutes[6]}m"
  - Only show label if weeklyMinutes[6] > 0

Top right pill label:
  Text: "${weeklyMinutes[6]}m" (today's total minutes)
  If weeklyMinutes[6] == 0: show "0m"

── HOW ADMIN DATA IS FETCHED ─────────────

Called once via FutureBuilder when AdminHomeScreen builds.
On pull-to-refresh (_onRefresh already exists in AdminHomeScreen):
  Add PerformanceService.instance.getAdminPerformance() to the
  existing _onRefresh flow so it refreshes together with streams.
  Store result in a local Future variable that resets on refresh
  (same pattern as _topTestsStream/_topUsersStream).

Revenue display: "₹${data['today_revenue']}"
  Format as integer if .0, else show 1 decimal:
  final rev = (data['today_revenue'] as num).toDouble();
  final revStr = rev == rev.truncate() ? '₹${rev.toInt()}' : '₹${rev.toStringAsFixed(1)}';

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
DESIGN SYSTEM RULES (NON-NEGOTIABLE)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Token Law — no raw values anywhere:
  Spacing: AppSpacing.xs(4) sm(8) md(12) lg(16) xl(24) xxl(32)
  Radius:  AppRadius.xs(2) sm(4) md(8) lg(16) full(999)
  Font:    context.sp(value)
  Width:   context.w(value)
  Height:  context.h(value)
  Colors:  theme.colorScheme.* only — NO hardcoded hex except:
           admin card bg: Color(0xFF1E293B) light / Color(0xFF0F172A) dark
           green accent:  Color(0xFF10B981) — completion rate + live dot

All imports: package:krushi_kalp/... paths
No .withOpacity() — use .withValues(alpha: x) only
No const on widgets using context.sp/w/h or AppSpacing tokens

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
FILES TO BUILD — IN ORDER
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

─── FILE 1: lib/domain/models/user_performance.dart ───
// NEW FILE

class UserPerformance {
  final int streak;
  final double avgScore;
  final int testsCompleted;
  final double bestScore;
  final List<int> weeklyMinutes; // always 7 elements, index 6 = today

  const UserPerformance({
    required this.streak,
    required this.avgScore,
    required this.testsCompleted,
    required this.bestScore,
    required this.weeklyMinutes,
  });

  factory UserPerformance.fromJson(Map<String, dynamic> json) {
    // weekly_minutes comes from DB as jsonb — could be List<dynamic>
    // Safe cast:
    final raw = json['weekly_minutes'];
    List<int> minutes;
    if (raw is List) {
      minutes = raw.map((e) => (e as num?)?.toInt() ?? 0).toList();
      // Ensure exactly 7 elements
      while (minutes.length < 7) minutes.add(0);
      if (minutes.length > 7) minutes = minutes.sublist(0, 7);
    } else {
      minutes = List.filled(7, 0);
    }

    return UserPerformance(
      streak: (json['streak'] as num?)?.toInt() ?? 0,
      avgScore: (json['avg_score'] as num?)?.toDouble() ?? 0.0,
      testsCompleted: (json['tests_completed'] as num?)?.toInt() ?? 0,
      bestScore: (json['best_score'] as num?)?.toDouble() ?? 0.0,
      weeklyMinutes: minutes,
    );
  }

  factory UserPerformance.empty() => UserPerformance(
    streak: 0,
    avgScore: 0,
    testsCompleted: 0,
    bestScore: 0,
    weeklyMinutes: List.filled(7, 0),
  );
}

─── FILE 2: lib/data/services/performance_service.dart ───
// NEW FILE — Singleton

class PerformanceService {
  PerformanceService._();
  static final PerformanceService instance = PerformanceService._();

  final _client = Supabase.instance.client;

  Future<UserPerformance> getUserPerformance(String userId) async {
    try {
      final result = await _client
        .rpc('get_user_performance', params: {'p_user_id': userId});
      if (result == null) return UserPerformance.empty();
      return UserPerformance.fromJson(result as Map<String, dynamic>);
    } catch (e) {
      debugPrint('[PerformanceService] getUserPerformance error: $e');
      return UserPerformance.empty();
    }
  }

  Future<Map<String, dynamic>> getAdminPerformance() async {
    try {
      final result = await _client.rpc('get_admin_performance');
      if (result == null) return {};
      return Map<String, dynamic>.from(result as Map);
    } catch (e) {
      debugPrint('[PerformanceService] getAdminPerformance error: $e');
      return {};
    }
  }

  // Fire and forget — never throws, never awaited by caller
  Future<void> updateUserStreak(
    String userId,
    int durationSeconds,
    String activityType, // 'test_attempt' or 'resource_read'
  ) async {
    try {
      await _client.rpc('update_user_streak', params: {
        'p_user_id': userId,
        'p_duration_seconds': durationSeconds,
        'p_activity_type': activityType,
      });
    } catch (e) {
      debugPrint('[PerformanceService] updateUserStreak error: $e');
      // Intentionally swallowed — streak update is best-effort
    }
  }
}

─── FILE 3: lib/presentation/widgets/performance_card.dart ───
// NEW FILE

Widget signature:
  class PerformanceCard extends StatelessWidget {
    final UserPerformance data;
    final bool isLoading;
    const PerformanceCard({required this.data, this.isLoading = false, super.key});
  }

Outer container:
  height: context.h(180)
  margin: EdgeInsets.symmetric(horizontal: AppSpacing.xs)
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(AppRadius.lg),
    boxShadow: [BoxShadow(
      color: theme.colorScheme.shadow.withValues(alpha: 0.08),
      blurRadius: 12, offset: Offset(0, 4)
    )]
  )
  child: ClipRRect(borderRadius: ..., child: IntrinsicHeight(child: Row([leftPanel, rightPanel])))

LEFT PANEL (flex 55):
  decoration: BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft, end: Alignment.bottomRight,
      colors: [
        theme.colorScheme.primary,
        theme.colorScheme.primary.withValues(alpha: 0.75)
      ]
    )
  )
  padding: EdgeInsets.all(AppSpacing.lg)

  Content (Column, crossAxisAlignment: start):
    Row: [Text("🔥") SizedBox(w:6) Text("${data.streak} Day Streak", bold sp(17) white)]
    SizedBox(h: AppSpacing.xs)
    Text("Keep it up!", sp(11), white.withValues(alpha:0.7))
    Spacer()
    Row(children: [
      Column(crossAxisAlignment: start, children: [
        Text("AVG SCORE", sp(9), white.withValues(alpha:0.6), letterSpacing:0.8),
        Text("${data.avgScore}%", bold, sp(15), white),
      ]),
      SizedBox(w: AppSpacing.lg),
      Column(crossAxisAlignment: start, children: [
        Text("TESTS DONE", sp(9), white.withValues(alpha:0.6), letterSpacing:0.8),
        Text("${data.testsCompleted}", bold, sp(15), white),
      ]),
    ])
    SizedBox(h: AppSpacing.xs)
    Text("BEST SCORE", sp(9), white.withValues(alpha:0.6), letterSpacing:0.8)
    Text("${data.bestScore}", bold, sp(15), white)

RIGHT PANEL (flex 45):
  color: theme.colorScheme.surface
  padding: EdgeInsets.all(AppSpacing.md)

  Content (Column, crossAxisAlignment: stretch):
    Row(mainAxisAlignment: spaceBetween):
      Text("This Week", bold, sp(11), onSurfaceVariant, letterSpacing:0.5)
      Container(
        padding: EdgeInsets.symmetric(vertical:3, horizontal: AppSpacing.sm),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha:0.15),
          borderRadius: BorderRadius.circular(AppRadius.full)
        ),
        child: Text("${data.weeklyMinutes[6]}m", bold, sp(9), primary)
      )

    SizedBox(h: AppSpacing.sm)

    // 7-BAR CHART
    Expanded(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(7, (i) {
          final minutes = data.weeklyMinutes[i];
          final maxVal = data.weeklyMinutes.reduce(max).clamp(1, 9999);
          final heightFactor = minutes == 0 ? 0.08 : (minutes / maxVal).clamp(0.12, 1.0);
          final isToday = i == 6;
          final barColor = minutes == 0
            ? theme.colorScheme.surfaceContainerHighest
            : isToday
              ? theme.colorScheme.primary
              : theme.colorScheme.primary.withValues(alpha: 0.35);

          return Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 2),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (isToday && minutes > 0)
                    Padding(
                      padding: EdgeInsets.only(bottom: 2),
                      child: Text("${minutes}m", style: TextStyle(
                        fontSize: context.sp(8),
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      )),
                    ),
                  Flexible(
                    child: FractionallySizedBox(
                      alignment: Alignment.bottomCenter,
                      heightFactor: heightFactor,
                      child: Container(
                        decoration: BoxDecoration(
                          color: barColor,
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(AppRadius.sm)
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    )

    SizedBox(h: AppSpacing.xs)

    // Day labels — dynamic, always relative to today
    Builder(builder: (context) {
      final dayLabels = List.generate(7, (i) {
        final day = DateTime.now().subtract(Duration(days: 6 - i));
        return ['M','T','W','T','F','S','S'][day.weekday - 1];
      });
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(7, (i) => Text(
          dayLabels[i],
          style: TextStyle(
            fontSize: context.sp(9),
            color: i == 6
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurfaceVariant,
            fontWeight: i == 6 ? FontWeight.bold : FontWeight.normal,
          ),
        )),
      );
    })

    SizedBox(h: AppSpacing.xs)
    Text("+12% vs last week",
      style: TextStyle(
        fontSize: context.sp(9),
        color: theme.colorScheme.onSurfaceVariant,
        fontStyle: FontStyle.italic,
      ),
      textAlign: TextAlign.center,
    )
    // Note: "+12%" is static for now — Phase 2 will calculate from weekly_minutes

SHIMMER STATE (when isLoading == true):
  Show same card container but replace content with:
  Left panel: Column of 3 shimmer rectangles using flutter_animate .shimmer()
  Right panel: Row of 7 mini shimmer rectangles as bar placeholders
  Shimmer color: theme.colorScheme.surfaceContainerHighest

─── FILE 4: lib/presentation/widgets/admin_performance_card.dart ───
// NEW FILE

Widget signature:
  class AdminPerformanceCard extends StatelessWidget {
    final Map<String, dynamic> data;
    final bool isLoading;
    const AdminPerformanceCard({required this.data, this.isLoading = false, super.key});

    // Safe getters — never crash on missing keys
    double get _todayRevenue => (data['today_revenue'] as num?)?.toDouble() ?? 0;
    int get _weeklyNewUsers => (data['weekly_new_users'] as num?)?.toInt() ?? 0;
    int get _testsSoldWeek => (data['tests_sold_week'] as num?)?.toInt() ?? 0;
    String get _topTestTitle => (data['top_test_title'] as String?) ?? 'N/A';
    int get _topTestAttempts => (data['top_test_attempts'] as num?)?.toInt() ?? 0;
    double get _platformAvgRating => (data['platform_avg_rating'] as num?)?.toDouble() ?? 0;
    double get _completionRate => (data['completion_rate'] as num?)?.toDouble() ?? 0;

    // Revenue formatting helper
    String get _revenueStr {
      if (_todayRevenue == _todayRevenue.truncateToDouble())
        return '₹${_todayRevenue.toInt()}';
      return '₹${_todayRevenue.toStringAsFixed(1)}';
    }
  }

Card background:
  Always dark slate — check brightness:
  final cardBg = Theme.of(context).brightness == Brightness.dark
    ? const Color(0xFF0F172A)
    : const Color(0xFF1E293B);

Layout:
  Container(
    decoration: BoxDecoration(
      color: cardBg,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      boxShadow: [BoxShadow(
        color: Colors.black.withValues(alpha:0.15),
        blurRadius: 10, offset: Offset(0,4)
      )]
    ),
    padding: EdgeInsets.all(AppSpacing.lg),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        // Header row
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text("ADMIN PERFORMANCE CARD",
            style: TextStyle(
              fontSize: context.sp(10),
              color: Colors.white.withValues(alpha:0.6),
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            )
          ),
          Container(
            width: 8, height: 8,
            decoration: BoxDecoration(
              color: const Color(0xFF10B981),
              shape: BoxShape.circle,
            )
          ),
        ]),

        SizedBox(height: AppSpacing.sm),

        // 2x2 metric grid
        // Use two Rows instead of GridView to avoid height issues
        Row(children: [
          _MetricChip(value: _revenueStr, label: "TODAY REVENUE"),
          SizedBox(width: AppSpacing.sm),
          _MetricChip(value: '$_weeklyNewUsers', label: "NEW THIS WEEK"),
        ]),
        SizedBox(height: AppSpacing.sm),
        Row(children: [
          _MetricChip(value: '$_testsSoldWeek', label: "SOLD THIS WEEK"),
          SizedBox(width: AppSpacing.sm),
          _MetricChip(value: '⭐ ${_platformAvgRating.toStringAsFixed(1)}', label: "RATING PLATFORM"),
        ]),

        SizedBox(height: AppSpacing.sm),
        Divider(color: Colors.white.withValues(alpha:0.15), height: 1),
        SizedBox(height: AppSpacing.xs),

        // Bottom row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 6,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text("MOST ATTEMPTED",
                  style: TextStyle(fontSize: context.sp(9),
                    color: Colors.white.withValues(alpha:0.5), letterSpacing:0.8)),
                Text("$_topTestTitle · $_topTestAttempts attempts",
                  style: TextStyle(fontSize: context.sp(11),
                    color: Colors.white, fontWeight: FontWeight.bold),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                ),
              ]),
            ),
            SizedBox(width: AppSpacing.sm),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text("COMPLETION",
                style: TextStyle(fontSize: context.sp(9),
                  color: Colors.white.withValues(alpha:0.5), letterSpacing:0.8)),
              Text("${_completionRate.toStringAsFixed(1)}%",
                style: TextStyle(fontSize: context.sp(14),
                  color: const Color(0xFF10B981), fontWeight: FontWeight.bold)),
            ]),
          ],
        ),
      ],
    ),
  )

// Private helper widget — in same file
class _MetricChip extends StatelessWidget {
  final String value;
  final String label;
  const _MetricChip({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: AppSpacing.sm, horizontal: AppSpacing.md),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value,
              style: TextStyle(
                fontSize: context.sp(20),
                color: Colors.white,
                fontWeight: FontWeight.bold,
              )
            ),
            SizedBox(height: 2),
            Text(label,
              style: TextStyle(
                fontSize: context.sp(10),
                color: Colors.white.withValues(alpha: 0.5),
                letterSpacing: 0.8,
              )
            ),
          ],
        ),
      ),
    );
  }
}

─── FILE 5: MODIFY home_screen.dart ───
// MODIFIED — add performance card above banner carousel

In _buildBannerCarousel():
  Wrap existing return value in a Column:

  Widget _buildBannerCarousel() {
    return Column(
      children: [
        _buildPerformanceCard(),      // NEW
        SizedBox(height: AppSpacing.sm), // NEW
        // existing StreamBuilder code unchanged below this line
        StreamBuilder<List<HomeBanner>>(
          ... existing unchanged code ...
        ),
      ],
    );
  }

  // NEW method — add below _buildBannerCarousel
  Widget _buildPerformanceCard() {
    final userId = context.read<AuthProvider>().currentUser?.id ?? '';
    if (userId.isEmpty) return const SizedBox.shrink();
    return FutureBuilder<UserPerformance>(
      future: PerformanceService.instance.getUserPerformance(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return PerformanceCard(data: UserPerformance.empty(), isLoading: true);
        }
        if (!snapshot.hasData || snapshot.hasError) {
          return const SizedBox.shrink();
        }
        return PerformanceCard(data: snapshot.data!);
      },
    );
  }

New imports needed:
  import 'package:krushi_kalp/data/services/performance_service.dart';
  import 'package:krushi_kalp/domain/models/user_performance.dart';
  import 'package:krushi_kalp/presentation/widgets/performance_card.dart';

DO NOT change: AppBar, drawer, category grid, refresh logic, banner streaming.

─── FILE 6: MODIFY admin_home_screen.dart ───
// MODIFIED — add admin performance card at top

Add instance variable:
  Future<Map<String, dynamic>>? _adminPerformanceFuture; // NEW

In initState(), add:
  _adminPerformanceFuture = PerformanceService.instance.getAdminPerformance(); // NEW

In _onRefresh(), add inside setState():
  _adminPerformanceFuture = PerformanceService.instance.getAdminPerformance(); // NEW

In build(), inside Column children, insert as FIRST child
before _buildSectionHeader('MANAGEMENT QUICK ACCESS'):

  // NEW — admin performance card
  FutureBuilder<Map<String, dynamic>>(
    future: _adminPerformanceFuture,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.lg),
          child: AdminPerformanceCard(data: const {}, isLoading: true),
        );
      }
      if (!snapshot.hasData || snapshot.hasError || snapshot.data!.isEmpty) {
        return const SizedBox.shrink();
      }
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.lg),
        child: AdminPerformanceCard(data: snapshot.data!),
      );
    },
  ),
  // existing _buildSectionHeader('MANAGEMENT QUICK ACCESS') stays here

New imports needed:
  import 'package:krushi_kalp/data/services/performance_service.dart';
  import 'package:krushi_kalp/presentation/widgets/admin_performance_card.dart';

DO NOT change: _buildDashboardCard, _buildTopTestsList, _buildTopUsersList,
_buildSectionHeader, StreamBuilders, _refreshKey, any existing logic.

─── FILE 7: MODIFY test_result_screen.dart ───
// MODIFIED — call streak update after result saved

Find the block where result is saved to Supabase successfully.
Identify: userId and timeTakenSeconds from the result object.

After the successful save, add exactly this (fire and forget):
  // MODIFIED — update streak after test attempt, fire and forget
  PerformanceService.instance.updateUserStreak(
    userId,              // String user ID
    timeTakenSeconds,    // int seconds taken for this test
    'test_attempt',      // always 'test_attempt' for mock tests
  ).ignore();

Rules:
  - Never await this call
  - Never wrap in setState
  - Never show UI for it
  - Place it AFTER the successful DB save, not before

New import:
  import 'package:krushi_kalp/data/services/performance_service.dart';

─── FILE 8: MODIFY pdf_viewer_screen.dart ───
// MODIFIED — measure read time and update streak on close

In the State class, add:
  DateTime? _openedAt; // NEW — tracks when PDF was opened

In initState(), add AFTER super.initState():
  _openedAt = DateTime.now(); // NEW

In dispose(), add BEFORE super.dispose():
  // NEW — calculate read duration and update streak if >= 5 minutes
  if (_openedAt != null) {
    final durationSeconds = DateTime.now().difference(_openedAt!).inSeconds;
    if (durationSeconds >= 300) {
      // Get userId via global navigatorKey — safe in dispose
      final ctx = navigatorKey.currentContext;
      final userId = ctx != null
        ? (ctx.read<AuthProvider>().currentUser?.id ?? '')
        : '';
      if (userId.isNotEmpty) {
        PerformanceService.instance
          .updateUserStreak(userId, durationSeconds, 'resource_read')
          .ignore();
      }
    }
  }

New imports:
  import 'package:krushi_kalp/data/services/performance_service.dart';
  import 'package:krushi_kalp/presentation/utils/navigator_key.dart';
  import 'package:provider/provider.dart';
  import 'package:krushi_kalp/presentation/providers/auth_provider.dart';

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
GLOBAL RULES
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. NO raw hex — only Color(0xFF...) for the 2 admin bg values + green
2. NO raw pixel values — AppSpacing/AppRadius/context.sp/w/h only
3. NO chart libraries — bars are plain Container + FractionallySizedBox
4. NO new providers — FutureBuilder only
5. NO .withOpacity() — always .withValues(alpha: x)
6. NO const on widgets using context.sp/w/h or AppSpacing
7. DO NOT touch: auth, payment, download, notification, routing,
   AppTheme, AppColors, AppSpacing, AppRadius, main.dart, splash_screen.dart
8. Every new file: // NEW FILE comment at top
9. Every changed line: // MODIFIED inline comment
10. Run flutter analyze mentally before outputting


━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
new rules
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
IMPORTANT — STREAK TRIGGER RULE FOR PDF READING:
In pdf_viewer_screen.dart dispose():
  - Calculate duration = DateTime.now().difference(_openedAt!).inSeconds
  - If duration < 300 (less than 5 minutes) → do NOT call updateUserStreak at all
  - If duration >= 300 (5 minutes or more) → call updateUserStreak with 'resource_read'
  - Test attempts always count regardless of duration — no minimum check needed there
  - Streak can be increase by 1 in a day not more than 1
IMPORTANT — WHAT THE 7-DAY BAR CHART DISPLAYS:
weekly_minutes[i] = total study minutes for that day
  = mock test time + resource reading time COMBINED
  = stored and summed inside the SQL function on every updateUserStreak call

So the chart is a STUDY TIME chart, not a test count chart.
Bar height = minutes studied that day (both reading + tests)
Today bar label above = "${weeklyMinutes[6]}m" (today's total study minutes)
Pill top-right = "${weeklyMinutes[6]}m" (same value)
If a user reads for 8 min + takes a 20 min test today → today's bar = 28m
Flutter just reads and displays the array — no calculation needed on Flutter side
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
DELIVERABLE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Output in this exact order, each as complete file:
1. user_performance.dart
2. performance_service.dart
3. performance_card.dart
4. admin_performance_card.dart
5. home_screen.dart (full file)
6. admin_home_screen.dart (full file)
7. test_result_screen.dart (full file)
8. pdf_viewer_screen.dart (full file)

Then update CLAUDE.md:
  Database Tables → add user_streaks entry
  Architecture section → add 4 new files
  Historical Improvements → add Performance Card entry with date