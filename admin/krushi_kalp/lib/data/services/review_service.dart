import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/review.dart';

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
    } catch (e) {
      debugPrint('Error submitting review: $e');
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
    } catch (e) {
      debugPrint('Error fetching reviews: $e');
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
    } catch (e) {
      debugPrint('Error checking user review: $e');
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
    } catch (e) {
      return {'average': 0.0, 'count': 0};
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

      // --- Manual Join for Item Names ---
      final testIds = reviewsData
          .where((e) => e['item_type'] == 'test')
          .map((e) => e['item_id'] as int)
          .toSet()
          .toList();

      final resourceIds = reviewsData
          .where((e) => e['item_type'] == 'resource')
          .map((e) => e['item_id'] as int)
          .toSet()
          .toList();

      Map<int, String> testNames = {};
      if (testIds.isNotEmpty) {
        final testsResponse = await _supabase
            .from('mock_tests')
            .select('test_id, title')
            .inFilter('test_id', testIds);
        for (var t in (testsResponse as List)) {
          testNames[t['test_id'] as int] = t['title'] as String;
        }
      }

      Map<int, String> resourceNames = {};
      if (resourceIds.isNotEmpty) {
        final resResponse = await _supabase
            .from('resources')
            .select('id, title')
            .inFilter('id', resourceIds);
        for (var r in (resResponse as List)) {
          resourceNames[r['id'] as int] = r['title'] as String;
        }
      }

      for (var review in reviewsData) {
        final userId = review['user_id'];
        if (usersMap.containsKey(userId)) {
          review['users'] = usersMap[userId];
        }

        final itemId = review['item_id'] as int;
        if (review['item_type'] == 'test') {
          review['item_name'] = testNames[itemId] ?? 'Unknown Test';
        } else if (review['item_type'] == 'resource') {
          review['item_name'] = resourceNames[itemId] ?? 'Unknown Resource';
        }
      }

      return reviewsData.map((json) => Review.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error fetching all reviews: $e');
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
    } catch (e) {
      debugPrint('Error deleting review: $e');
      throw e;
    }
  }
}
