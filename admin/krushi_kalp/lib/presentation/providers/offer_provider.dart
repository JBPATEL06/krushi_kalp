import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/offer.dart';
import '../../data/services/offer_service.dart';

class OfferProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  List<Offer> _activeOffers = [];
  bool _isLoading = false;
  String _errorMessage = '';

  List<Offer> get activeOffers => _activeOffers;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  RealtimeChannel? _offerChannel;

  OfferProvider() {
    // Initial load
    fetchActiveOffers();
    // Setup Realtime Listener
    _setupListener();
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

      final offers = await OfferService.fetchActiveSaleOffers();
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

  void _setupListener() {
    _offerChannel = _supabase
        .channel('public:offers:realtime')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'offers',
          callback: (payload) {
            debugPrint(
                'OfferProvider: Realtime change detected. Refreshing...');
            fetchActiveOffers();
          },
        )
        .subscribe();
  }

  @override
  void dispose() {
    _offerChannel?.unsubscribe();
    super.dispose();
  }
}
