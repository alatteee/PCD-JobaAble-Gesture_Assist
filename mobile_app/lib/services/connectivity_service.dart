import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class ConnectivityService {
  ConnectivityService();

  final Connectivity _connectivity = Connectivity();

  final StreamController<bool> _connectionController =
      StreamController<bool>.broadcast();

  StreamSubscription<List<ConnectivityResult>>? _subscription;

  bool _isOnline = true;
  bool _initialized = false;

  Stream<bool> get connectionStream => _connectionController.stream;

  bool get isOnline => _isOnline;

  final ValueNotifier<bool> isOnlineNotifier = ValueNotifier<bool>(true);

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    await refresh();

    _subscription = _connectivity.onConnectivityChanged.listen(
      (List<ConnectivityResult> results) {
        debugPrint('DEBUG: Connectivity Changed: $results');

        final hasConnection = _hasConnectionFromResults(results);
        _updateConnectionStatus(hasConnection);
      },
    );
  }

  Future<bool> refresh() async {
    try {
      final List<ConnectivityResult> results = await _connectivity
          .checkConnectivity()
          .timeout(const Duration(milliseconds: 700));

      final hasConnection = _hasConnectionFromResults(results);
      _updateConnectionStatus(hasConnection);

      return hasConnection;
    } catch (e) {
      debugPrint('DEBUG: Connectivity check timeout/error: $e');

      _updateConnectionStatus(false);
      return false;
    }
  }

  Future<bool> checkConnection() async {
    return refresh();
  }

  bool _hasConnectionFromResults(List<ConnectivityResult> results) {
    return results.any((result) => result != ConnectivityResult.none);
  }

  void _updateConnectionStatus(bool value) {
    if (_isOnline == value) return;

    _isOnline = value;
    isOnlineNotifier.value = value;

    if (!_connectionController.isClosed) {
      _connectionController.add(value);
    }

    debugPrint('DEBUG: Internet status: ${value ? "ONLINE" : "OFFLINE"}');
  }

  Future<void> dispose() async {
    await _subscription?.cancel();

    if (!_connectionController.isClosed) {
      await _connectionController.close();
    }

    isOnlineNotifier.dispose();
  }
}

// Global instance
final connectivityService = ConnectivityService();