import 'package:flutter/material.dart';
import '../../domain/models/offer.dart';
import '../../data/services/offer_service.dart';
import '../../utils/crashlytics_service.dart';
import '../../data/services/local_caching_service.dart'; // NEW
import '../../data/local/entities/offer_entity.dart'; // NEW

class OfferProvider with ChangeNotifier {
  List<Offer> _activeOffers = [];
  bool _isLoading = false;
  String _errorMessage = '';

  List<Offer> get activeOffers => _activeOffers;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  OfferProvider() {
    // Initial load
    fetchActiveOffers();
    // Setup Realtime Listener
  }

  Future<void> fetchActiveOffers({bool forceRefresh = false}) async {
    if (!forceRefresh && _activeOffers.isNotEmpty) {
      
      return;
    }

    try {
      // 1. Instantly load from Isar NoSQL (Local Cache)
      final cachedEntities = await LocalCachingService.getCachedOffers();
      if (cachedEntities.isNotEmpty && _activeOffers.isEmpty) {
        _activeOffers = cachedEntities.map((e) => e.toOffer()).toList();
        Future.microtask(() => notifyListeners()); // Update UI instantly
      }

      _isLoading = true;
      notifyListeners();
      CrashlyticsService.instance
          .log('OfferProvider: Fetching active offers (force: $forceRefresh)');

      // 2. Fetch fresh data from Supabase silently
      final offers = await OfferService.instance.fetchActiveSaleOffers();
      _activeOffers = offers;
      _errorMessage = '';

      // 3. Save fresh data to Isar
      if (offers.isNotEmpty) {
        LocalCachingService.saveOffers(
            offers.map((o) => OfferEntity.fromOffer(o)).toList());
      }
    } catch (e, stack) {
      
      _errorMessage = e.toString();
      CrashlyticsService.instance
          .recordError(e, stack, reason: 'OfferProvider: fetchActiveOffers');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

}
