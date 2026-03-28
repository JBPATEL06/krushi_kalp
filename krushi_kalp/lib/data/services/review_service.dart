import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/review.dart';
import '../../utils/crashlytics_service.dart';

class ReviewService {
  static final _supabase = Supabase.instance.client;

  /// Submit or Update a review
  static Future<void> submitReview({
    required String userId,
    required int itemId,
    required String itemType,
    required double rating,
    String? reviewText,
  }) async {
    try {
      final data = {
        'user_id': userId,
        'item_id': itemId,
        'item_type': itemType,
        'rating': rating,
        'review_text': reviewText,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };

      // Upsert: Insert or Update if (user_id, item_id, item_type) conflicts
      await _supabase
          .from('reviews')
          .upsert(data, onConflict: 'user_id, item_id, item_type');
    } catch (e, stack) {
      CrashlyticsService.instance.recordError(e, stack, reason: 'review_service');
      throw Exception('Failed to submit review');
    }
  }

  /// Fetch reviews for a specific item (Test or Resource)
  static Future<List<Review>> getReviewsForItem(
      int itemId, String itemType) async {
    try {
      // 1. Fetch reviews without join
      final response = await _supabase
          .from('reviews')
          .select()
          .eq('item_id', itemId)
          .eq('item_type', itemType)
          .order('created_at', ascending: false);

      final reviewsData = List<Map<String, dynamic>>.from(response);

      if (reviewsData.isEmpty) return [];

      // 2. Extract user IDs
      final userIds =
          reviewsData.map((e) => e['user_id'] as String).toSet().toList();

      // 3. Fetch user details manually (public.users)
      final usersResponse = await _supabase
          .from('users')
          .select('id, username')
          .inFilter('id', userIds);

      final usersMap = {
        for (var u in (usersResponse as List)) u['id'] as String: u
      };

      // 4. Merge data
      for (var review in reviewsData) {
        final userId = review['user_id'];
        if (usersMap.containsKey(userId)) {
          review['users'] = usersMap[userId]; // Inject 'users' map
        }
      }

      return reviewsData.map((e) => Review.fromJson(e)).toList();
    } catch (e, stack) {
      CrashlyticsService.instance.recordError(e, stack, reason: 'review_service');
      return [];
    }
  }

  /// Get the current user's review for an item (if exists)
  static Future<Review?> getUserReview(
      String userId, int itemId, String itemType) async {
    try {
      final response = await _supabase
          .from('reviews')
          .select()
          .eq('user_id', userId)
          .eq('item_id', itemId)
          .eq('item_type', itemType)
          .maybeSingle();

      if (response == null) return null;
      return Review.fromJson(response);
    } catch (e, stack) {
      CrashlyticsService.instance.recordError(e, stack, reason: 'review_service');
      return null;
    }
  }

  /// Get Rating Stats (Average & Count)
  /// Note: Ideally, this should be an RPC or a separate stats table for performance.
  /// For V1, we can calculate strictly on client or use a simple query if data size is small.
  static Future<Map<String, dynamic>> getRatingStats(
      int itemId, String itemType) async {
    try {
      final response = await _supabase
          .from('reviews')
          .select('rating')
          .eq('item_id', itemId)
          .eq('item_type', itemType);

      final ratings = (response as List)
          .map((e) => (e['rating'] as num).toDouble())
          .toList();

      if (ratings.isEmpty) {
        return {'average': 0.0, 'count': 0};
      }

      double total = ratings.reduce((a, b) => a + b);
      double avg = total / ratings.length;

      return {
        'average': double.parse(avg.toStringAsFixed(1)),
        'count': ratings.length,
      };
    } catch (e, stack) {
      CrashlyticsService.instance.recordError(e, stack, reason: 'review_service');
      return {'average': 0.0, 'count': 0};
    }
  }

  /// Fetch rating stats for multiple items in a single DB round-trip.
  /// Returns a map of itemId → {'average': double, 'count': int}
  static Future<Map<int, Map<String, dynamic>>> getBulkRatingStats(
    List<int> itemIds,
    String itemType,
  ) async {
    if (itemIds.isEmpty) return {};
    try {
      final response = await _supabase
          .from('reviews')
          .select('item_id, rating')
          .eq('item_type', itemType)
          .inFilter('item_id', itemIds);

      // Group ratings by itemId
      final Map<int, List<double>> grouped = {};
      for (final row in (response as List)) {
        final id = row['item_id'] as int;
        final rating = (row['rating'] as num).toDouble();
        grouped.putIfAbsent(id, () => []).add(rating);
      }

      // Build result map for every requested itemId
      final Map<int, Map<String, dynamic>> result = {};
      for (final id in itemIds) {
        final ratings = grouped[id] ?? [];
        if (ratings.isEmpty) {
          result[id] = {'average': 0.0, 'count': 0};
        } else {
          final avg = ratings.reduce((a, b) => a + b) / ratings.length;
          result[id] = {
            'average': double.parse(avg.toStringAsFixed(1)),
            'count': ratings.length,
          };
        }
      }
      return result;
    } catch (e, stack) {
      CrashlyticsService.instance.recordError(e, stack, reason: 'review_service');
      return {};
    }
  }

  // --- ADMIN METHODS ---

  /// Fetch all reviews (paginated) for Admin Dashboard
  static Future<List<Review>> getAllReviews({
    int limit = 20,
    int offset = 0,
    String? itemType,
  }) async {
    try {
      var query = _supabase.from('reviews').select();

      if (itemType != null) {
        query = query.eq('item_type', itemType);
      }

      final response = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      final reviewsData = List<Map<String, dynamic>>.from(response);

      if (reviewsData.isEmpty) return [];

      // Manual Join for Usernames
      final userIds =
          reviewsData.map((e) => e['user_id'] as String).toSet().toList();

      final usersResponse = await _supabase
          .from('users')
          .select('id, username')
          .inFilter('id', userIds);

      final usersMap = {
        for (var u in (usersResponse as List)) u['id'] as String: u
      };

      for (var review in reviewsData) {
        final userId = review['user_id'];
        if (usersMap.containsKey(userId)) {
          review['users'] = usersMap[userId];
        }
      }

      return reviewsData.map((json) => Review.fromJson(json)).toList();
    } catch (e, stack) {
      CrashlyticsService.instance.recordError(e, stack, reason: 'review_service');
      return [];
    }
  }

  /// Delete a review (Moderation)
  static Future<void> deleteReview(int reviewId) async {
    try {
      await Supabase.instance.client
          .from('reviews')
          .delete()
          .eq('id', reviewId);
    } catch (e, stack) {
      rethrow;
    }
  }
}
