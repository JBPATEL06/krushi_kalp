import 'package:flutter/material.dart';
import '../../domain/models/offer.dart';
import '../../data/services/offer_service.dart';
import '../../utils/crashlytics_service.dart';

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
      _isLoading = true;
      notifyListeners();
      CrashlyticsService.instance
          .log('OfferProvider: Fetching active offers (force: $forceRefresh)');

      final offers = await OfferService.instance.fetchActiveSaleOffers();
      _activeOffers = offers;
      _errorMessage = '';
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
