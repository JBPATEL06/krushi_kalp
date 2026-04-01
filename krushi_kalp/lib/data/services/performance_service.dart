// NEW FILE
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:krushi_kalp/domain/models/user_performance.dart';

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
      // Fetch both admin stats and platform rating in parallel
      final results = await Future.wait([
        _client.rpc('get_admin_performance'),
        _client.rpc('get_platform_avg_rating'),
      ]);

      final adminStats = results[0] != null
          ? Map<String, dynamic>.from(results[0] as Map)
          : <String, dynamic>{};

      // Add the rating to the map
      adminStats['platform_avg_rating'] =
          (results[1] as num?)?.toDouble() ?? 0.0;

      return adminStats;
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
