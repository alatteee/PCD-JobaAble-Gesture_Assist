import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  final StreamController<bool> _connectionController = StreamController<bool>.broadcast();

  Stream<bool> get connectionStream => _connectionController.stream;

  ConnectivityService() {
    _connectivity.onConnectivityChanged.listen((List<ConnectivityResult> results) {
      print('DEBUG: Connectivity Changed: $results');
      final hasConnection = results.any((result) => result != ConnectivityResult.none);
      _connectionController.add(hasConnection);
    });
  }

  Future<bool> checkConnection() async {
    final List<ConnectivityResult> results = await _connectivity.checkConnectivity();
    return results.any((result) => result != ConnectivityResult.none);
  }

  void dispose() {
    _connectionController.close();
  }
}

// Global instance
final connectivityService = ConnectivityService();
