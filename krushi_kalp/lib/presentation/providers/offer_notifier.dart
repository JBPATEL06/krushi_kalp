import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/services/offer_service.dart';
import '../../utils/crashlytics_service.dart';
import '../../data/services/local_caching_service.dart';
import '../../data/local/entities/offer_entity.dart';
import 'offer_state.dart';

part 'offer_notifier.g.dart';

@Riverpod(keepAlive: true)
class OfferNotifier extends _$OfferNotifier {
  @override
  OfferState build() {
    // Fetch offers after build completion safely
    Future(() => fetchActiveOffers());
    return const OfferState();
  }

  Future<void> fetchActiveOffers({bool forceRefresh = false}) async {
    // Defer to next event loop tick to avoid "setState during build"
    await Future(() {});

    if (!forceRefresh && state.activeOffers.isNotEmpty) {
      return;
    }

    try {
      // 1. Instantly load from Isar NoSQL (Local Cache)
      final cachedEntities = await LocalCachingService.getCachedOffers();
      if (cachedEntities.isNotEmpty && state.activeOffers.isEmpty) {
        state = state.copyWith(activeOffers: cachedEntities.map((e) => e.toOffer()).toList());
      }

      state = state.copyWith(isLoading: true);
      CrashlyticsService.instance.log('OfferNotifier: Fetching active offers (force: $forceRefresh)');

      // 2. Fetch fresh data from Supabase silently
      final offers = await OfferService.instance.fetchActiveSaleOffers();
      state = state.copyWith(activeOffers: offers, errorMessage: '');

      // 3. Save fresh data to Isar
      if (offers.isNotEmpty) {
        LocalCachingService.saveOffers(offers.map((o) => OfferEntity.fromOffer(o)).toList());
      }
    } catch (e, stack) {
      state = state.copyWith(errorMessage: e.toString());
      CrashlyticsService.instance.recordError(e, stack, reason: 'OfferNotifier: fetchActiveOffers');
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }
}
