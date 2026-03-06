import 'package:flutter/material.dart';
import '../../domain/models/offer.dart';
import '../../data/services/offer_service.dart';

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
      debugPrint(
          'OfferProvider: Using cached offers (${_activeOffers.length})');
      return;
    }

    try {
      _isLoading = true;
      notifyListeners();

      final offers = await OfferService.instance.fetchActiveSaleOffers();
      _activeOffers = offers;
      _errorMessage = '';
    } catch (e) {
      debugPrint('OfferProvider: Error fetching offers: $e');
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}
