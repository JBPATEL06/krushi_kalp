import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

part 'network_notifier.g.dart';

@Riverpod(keepAlive: true)
class NetworkNotifier extends _$NetworkNotifier {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  @override
  bool build() {
    _init();
    ref.onDispose(() => _subscription?.cancel());
    return true; // Assume connected initially
  }

  void _init() {
    _connectivity.checkConnectivity().then(_updateStatus);
    _subscription = _connectivity.onConnectivityChanged.listen(_updateStatus);
  }

  void _updateStatus(List<ConnectivityResult> results) {
    state = results.isNotEmpty && !results.contains(ConnectivityResult.none);
  }

  Future<bool> checkConnectivity() async {
    final results = await _connectivity.checkConnectivity();
    _updateStatus(results);
    return state;
  }
}
