import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Provider to manage network connectivity state globally.
/// Uses a singleton pattern to ensure only one instance exists.
class NetworkProvider extends ChangeNotifier {
  static final NetworkProvider _instance = NetworkProvider._internal();
  factory NetworkProvider() => _instance;

  NetworkProvider._internal() {
    _initConnectivity();
  }

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  bool _isConnected = true;
  bool get isConnected => _isConnected;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  void _initConnectivity() {
    // Check initial connectivity
    _connectivity.checkConnectivity().then((results) {
      _updateConnectionStatus(results);
      _isInitialized = true;
      notifyListeners();
    });

    // Listen for connectivity changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      _updateConnectionStatus,
    );
  }

  void _updateConnectionStatus(List<ConnectivityResult> results) {
    final wasConnected = _isConnected;
    _isConnected =
        results.isNotEmpty && !results.contains(ConnectivityResult.none);

    if (wasConnected != _isConnected) {
      notifyListeners();
    }
  }

  /// Force a connectivity check
  Future<bool> checkConnectivity() async {
    final results = await _connectivity.checkConnectivity();
    _updateConnectionStatus(results);
    return _isConnected;
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }
}
