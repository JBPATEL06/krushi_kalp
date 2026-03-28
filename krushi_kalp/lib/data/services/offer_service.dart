import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/offer.dart';
import '../../utils/network_utils.dart';
import '../../utils/crashlytics_service.dart';
import 'auth_service.dart'; 
import '../../utils/retry_helper.dart';

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
      final response = await RetryHelper.run(() => _supabase.from('offers').select().order('created_at', ascending: false));
      final List<dynamic> data = response;
      return data.map((e) => Offer.fromJson(e)).toList();
    } catch (e, stack) {
      CrashlyticsService.instance.recordError(e, stack, reason: 'offer_service');
      if (NetworkUtils.isNetworkError(e)) {
        return [];
      }
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

      return counts;
    } catch (e, stack) {
      CrashlyticsService.instance.recordError(e, stack, reason: 'offer_service');
      if (NetworkUtils.isNetworkError(e)) {
        return {};
      }
      return {};
    }
  }

  // Fetch active global offers (Store Display)
  Future<List<Offer>> getActiveGlobalOffers() async {
    try {
      final now = DateTime.now().toUtc().toIso8601String();
      final response = await RetryHelper.run(() => _supabase.from('offers').select().eq('is_active', true).eq('target_type', 'ALL').lte('start_date', now).gte('end_date', now));

      final List<dynamic> data = response;
      return data.map((e) => Offer.fromJson(e)).toList();
    } catch (e, stack) {
      CrashlyticsService.instance.recordError(e, stack, reason: 'offer_service');
      if (NetworkUtils.isNetworkError(e)) return [];
      return [];
    }
  }

  Future<List<Offer>> fetchActiveSaleOffers() async {
    try {
      final now = DateTime.now().toUtc();
      final adjustedNow = now.add(const Duration(minutes: 5)).toIso8601String();

      final response = await _supabase
          .from('offers')
          .select()
          .eq('is_active', true)
          .or('start_date.is.null,start_date.lte.$adjustedNow')
          .or('end_date.is.null,end_date.gte.${now.toIso8601String()}');

      final List<dynamic> data = response;
      return data.map((e) => Offer.fromJson(e)).toList();
    } catch (e, stack) {
      CrashlyticsService.instance.recordError(e, stack, reason: 'offer_service');
      if (NetworkUtils.isNetworkError(e)) {
        return [];
      }
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
    } catch (e, stack) {
      CrashlyticsService.instance.recordError(e, stack, reason: 'offer_service');
      return false;
    }
  }

  Future<bool> checkUsageLimit(int offerId, String userId, int limit) async {
    try {
      final count = await _supabase
          .from('offer_redemptions')
          .count(CountOption.exact)
          .eq('offer_id', offerId)
          .eq('user_id', userId);
      return count < limit;
    } catch (e, stack) {
      CrashlyticsService.instance.recordError(e, stack, reason: 'offer_service');
      return true;
    }
  }

  Future<void> createOffer(Offer offer) async {
    try {
      if (offer.code != null) {
        final exists = await checkCodeExists(offer.code!);
        if (exists) throw Exception('Coupon Code already exists!');
      }

      final data = offer.toJson();
      data.remove('offer_id');
      await _supabase.from('offers').insert(data);
    } catch (e, stack) {
      CrashlyticsService.instance.recordError(e, stack, reason: 'offer_service');
      if (NetworkUtils.isNetworkError(e)) {
        throw Exception('Network Error: Please check your connection.');
      }
      throw Exception('$e');
    }
  }

  Future<void> updateOffer(Offer offer) async {
    try {
      if (offer.id == 0) throw Exception("Invalid Offer ID for update");

      if (offer.code != null) {
        final response = await _supabase
            .from('offers')
            .select('offer_id')
            .eq('code', offer.code!.toUpperCase())
            .neq('offer_id', offer.id)
            .maybeSingle();

        if (response != null) throw Exception('Coupon Code already exists!');
      }

      final data = offer.toJson();
      await _supabase.from('offers').update(data).eq('offer_id', offer.id);
    } catch (e, stack) {
      CrashlyticsService.instance.recordError(e, stack, reason: 'offer_service');
      if (NetworkUtils.isNetworkError(e)) {
        throw Exception('Network Error: Please check your connection.');
      }
      throw Exception('$e');
    }
  }

  Future<String> deleteOffer(int id) async {
    try {
      await _supabase.from('offers').delete().eq('offer_id', id);
      return 'DELETED';
    } catch (e, stack) {
      CrashlyticsService.instance.recordError(e, stack, reason: 'offer_service');
      if (e.toString().contains('23503') ||
          e.toString().contains('violates foreign key constraint')) {
        await _supabase
            .from('offers')
            .update({'is_active': false}).eq('offer_id', id);
        return 'ARCHIVED';
      }
      rethrow;
    }
  }

  Future<Offer?> verifyCoupon(String code) async {
    try {
      final now = DateTime.now().toUtc().toIso8601String();
      final response = await RetryHelper.run(() => _supabase.from('offers').select().eq('code', code.toUpperCase()).eq('is_active', true).lte('start_date', now).gte('end_date', now).maybeSingle());

      if (response == null) return null;
      return Offer.fromJson(response);
    } catch (e, stack) {
      CrashlyticsService.instance.recordError(e, stack, reason: 'offer_service');
      if (NetworkUtils.isNetworkError(e)) return null;
      return null;
    }
  }

  Future<void> applyCouponToOrder({
    required String orderId,
    required int offerId,
  }) async {
    try {
      await _supabase.from('orders').update({
        'offer_id': offerId,
        'updated_at': DateTime.now().toUtc().toIso8601String()
      }).eq('order_id', orderId);
    } catch (e, stack) {
      CrashlyticsService.instance.recordError(e, stack, reason: 'offer_service');
      throw Exception('Failed to apply coupon');
    }
  }

  Future<void> removeCouponFromOrder(String orderId) async {
    try {
      await _supabase.from('orders').update({
        'offer_id': null,
        'updated_at': DateTime.now().toIso8601String()
      }).eq('order_id', orderId);
    } catch (e, stack) {
      await CrashlyticsService.instance.recordError(e, stack,
          reason: 'Failed to remove coupon from order');
    }
  }

  // ---------------------------------------------------------------------------
  // DB-Driven Display Pricing
  // ---------------------------------------------------------------------------
  Future<Map<String, dynamic>> getDisplayPrice({
    required String itemType,
    required int itemId,
    String? couponCode,
  }) async {
    try {
      final user = AuthService.instance.currentUser;
      final result = await _supabase.rpc('calculate_display_price', params: {
        'p_item_type': itemType,
        'p_item_id': itemId,
        if (user != null) 'p_user_id': user.id,
        if (couponCode != null && couponCode.isNotEmpty)
          'p_coupon_code': couponCode,
      });
      final map = Map<String, dynamic>.from(result as Map);
      return {
        'base_price': (map['base_price'] as num).toDouble(),
        'final_price': (map['final_price'] as num).toDouble(),
        'mrp_display': (map['mrp_display'] as num).toDouble(),
        'discount_label': map['discount_label'] as String?,
        'has_discount': map['has_discount'] as bool,
      };
    } catch (e, stack) {
      CrashlyticsService.instance.recordError(e, stack,
          reason: 'offer_service.getDisplayPrice');
      return {
        'base_price': 0.0,
        'final_price': 0.0,
        'mrp_display': 0.0,
        'discount_label': null,
        'has_discount': false,
      };
    }
  }
}
