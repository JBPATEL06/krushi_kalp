import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/offer.dart';
import '../../utils/network_utils.dart'; // Import NetworkUtils

class OfferService {
  // Singleton
  static final OfferService _instance = OfferService._internal();
  factory OfferService() => _instance;
  OfferService._internal();

  static OfferService get instance => _instance;

  final _supabase = Supabase.instance.client;

  SupabaseClient get supabaseClient => _supabase;

  RealtimeChannel getOffersChannel() {
    return _supabase.channel('offers_channel');
  }

  // Fetch all offers (Admin)
  Future<List<Offer>> getAllOffers() async {
    try {
      final response = await _supabase
          .from('offers')
          .select()
          .order('created_at', ascending: false);
      final List<dynamic> data = response;
      return data.map((e) => Offer.fromJson(e)).toList();
    } catch (e) {
      if (NetworkUtils.isNetworkError(e)) {
        debugPrint('OfferService: Network Error fetching offers.');
        return [];
      }
      print('Error fetching offers: $e');
      return [];
    }
  }

  // Stream all offers (Admin)
  Stream<List<Offer>> streamOffers() {
    return _supabase
        .from('offers')
        .stream(primaryKey: ['offer_id'])
        .order('created_at', ascending: false)
        .map((data) => data.map((json) => Offer.fromJson(json)).toList());
  }

  // Fetch claim counts for all offers
  Future<Map<int, int>> getOfferClaimCounts() async {
    try {
      debugPrint('OfferService: Fetching all offer claim counts...');
      final response =
          await _supabase.from('offer_redemptions').select('offer_id');

      final List<dynamic> data = response;
      final Map<int, int> counts = {};

      for (var row in data) {
        final rawId = row['offer_id'];
        if (rawId == null) continue;

        final int id =
            (rawId is int) ? rawId : int.tryParse(rawId.toString()) ?? 0;
        if (id == 0) continue;

        counts[id] = (counts[id] ?? 0) + 1;
      }
      debugPrint('OfferService: Calculated counts: $counts');
      return counts;
    } catch (e) {
      if (NetworkUtils.isNetworkError(e)) {
        debugPrint('OfferService: Network Error fetching claim counts.');
        return {};
      }
      debugPrint('OfferService: Error fetching claim counts: $e');
      return {};
    }
  }

  // Fetch active global offers (Store Display)
  Future<List<Offer>> getActiveGlobalOffers() async {
    try {
      final now = DateTime.now().toUtc().toIso8601String();
      final response = await _supabase
          .from('offers')
          .select()
          .eq('is_active', true)
          .eq('target_type', 'ALL')
          .lte('start_date', now)
          .gte('end_date', now);

      final List<dynamic> data = response;
      return data.map((e) => Offer.fromJson(e)).toList();
    } catch (e) {
      if (NetworkUtils.isNetworkError(e)) return [];
      print('Error fetching active offers: $e');
      return [];
    }
  }

  Future<List<Offer>> fetchActiveSaleOffers() async {
    try {
      // Add a 5-minute grace period to account for slight clock drift
      final now = DateTime.now().toUtc();
      final adjustedNow = now.add(const Duration(minutes: 5)).toIso8601String();
      debugPrint(
          'OfferService: Fetching active offers at ${now.toIso8601String()} (Adjusted: $adjustedNow)');

      // Use or() to include offers where dates are null or within range
      final response = await _supabase
          .from('offers')
          .select()
          .eq('is_active', true)
          .or('start_date.is.null,start_date.lte.$adjustedNow')
          .or('end_date.is.null,end_date.gte.${now.toIso8601String()}');

      final List<dynamic> data = response;
      debugPrint('OfferService: Raw data count returned: ${data.length}');

      final offers = data.map((e) => Offer.fromJson(e)).toList();
      for (var o in offers) {
        debugPrint(
            'OfferService: Loaded Offer ID: ${o.id}, Title: ${o.title}, Target: ${o.targetType}, IDs: ${o.targetIds}');
      }

      return offers;
    } catch (e) {
      if (NetworkUtils.isNetworkError(e)) {
        debugPrint('OfferService: Network Error fetching active sale offers.');
        return [];
      }
      debugPrint('OfferService: Error fetching sale offers: $e');
      return [];
    }
  }

  Future<bool> checkCodeExists(String code) async {
    try {
      final response = await _supabase
          .from('offers')
          .select('offer_id')
          .eq('code', code.toUpperCase())
          .maybeSingle();
      return response != null;
    } catch (e) {
      return false; // Error assuming doesn't exist or DB issue
    }
  }

  // Check Usage Limit for a User
  Future<bool> checkUsageLimit(int offerId, String userId, int limit) async {
    try {
      final count = await _supabase
          .from('offer_redemptions')
          .count(CountOption.exact)
          .eq('offer_id', offerId)
          .eq('user_id', userId);
      return count < limit;
    } catch (e) {
      print("Error checking usage limit: $e");
      return true; // Allow if check fails to prevent blocking? Or fail? Fail safe preferred.
    }
  }

  // Create Offer (Admin)
  Future<void> createOffer(Offer offer) async {
    try {
      if (offer.code != null) {
        final exists = await checkCodeExists(offer.code!);
        if (exists) throw Exception('Coupon Code already exists!');
      }

      final data = offer.toJson();
      data.remove('offer_id'); // Let DB handle ID on insert
      await _supabase.from('offers').insert(data);
    } catch (e) {
      if (NetworkUtils.isNetworkError(e)) {
        throw Exception('Network Error: Please check your connection.');
      }
      print('Error creating offer: $e');
      throw Exception('$e');
    }
  }

  // Update Offer (Admin)
  Future<void> updateOffer(Offer offer) async {
    try {
      if (offer.id == 0) throw Exception("Invalid Offer ID for update");

      if (offer.code != null) {
        // Check existence but exclude current offer ID
        final response = await _supabase
            .from('offers')
            .select('offer_id')
            .eq('code', offer.code!.toUpperCase())
            .neq('offer_id', offer.id) // Exclude self
            .maybeSingle();

        if (response != null) throw Exception('Coupon Code already exists!');
      }

      final data = offer.toJson();
      // data.remove('offer_id'); // Optional, but better to keep for reference or rely on eq
      await _supabase.from('offers').update(data).eq('offer_id', offer.id);
    } catch (e) {
      if (NetworkUtils.isNetworkError(e)) {
        throw Exception('Network Error: Please check your connection.');
      }
      print('Error updating offer: $e');
      throw Exception('$e');
    }
  }

  // Delete/Deactivate
  // Returns: 'DELETED', 'ARCHIVED', or throws error
  Future<String> deleteOffer(int id) async {
    try {
      await _supabase.from('offers').delete().eq('offer_id', id);
      return 'DELETED';
    } catch (e) {
      // Check for Postgres Error Code 23503 (Foreign Key Violation)
      if (e.toString().contains('23503') ||
          e.toString().contains('violates foreign key constraint')) {
        debugPrint(
            "OfferService: FK Violation on delete. Archiving offer $id instead.");
        // Soft Delete: Deactivate
        await _supabase
            .from('offers')
            .update({'is_active': false}).eq('offer_id', id);
        return 'ARCHIVED';
      }
      throw e;
    }
  }

  // Verify Coupon Code
  Future<Offer?> verifyCoupon(String code) async {
    try {
      final now = DateTime.now().toUtc().toIso8601String();
      final response = await _supabase
          .from('offers')
          .select()
          .eq('code', code.toUpperCase())
          .eq('is_active', true)
          .lte('start_date', now)
          .gte('end_date', now)
          .maybeSingle();

      if (response == null) return null;
      return Offer.fromJson(response);
    } catch (e) {
      if (NetworkUtils.isNetworkError(e)) return null;
      print('Error verifying coupon: $e');
      return null;
    }
  }

  // --- ORDER COUPON MANAGEMENT ---
  Future<void> applyCouponToOrder({
    required String orderId,
    required int offerId,
  }) async {
    try {
      await _supabase.from('orders').update({
        'offer_id': offerId,
        'updated_at': DateTime.now().toUtc().toIso8601String()
      }).eq('order_id', orderId);
    } catch (e) {
      debugPrint('OfferService: Error applying coupon to order: $e');
      throw Exception('Failed to apply coupon');
    }
  }

  Future<void> removeCouponFromOrder(String orderId) async {
    try {
      await _supabase.from('orders').update({
        'offer_id': null,
        'updated_at': DateTime.now().toIso8601String()
      }).eq('order_id', orderId);
    } catch (e) {
      debugPrint('OfferService: Error removing coupon from order: $e');
    }
  }
}
