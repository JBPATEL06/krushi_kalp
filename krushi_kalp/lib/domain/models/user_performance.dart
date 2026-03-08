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
      while (minutes.length < 7) {
        minutes.add(0);
      }
      if (minutes.length > 7) {
        minutes = minutes.sublist(0, 7);
      }
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
