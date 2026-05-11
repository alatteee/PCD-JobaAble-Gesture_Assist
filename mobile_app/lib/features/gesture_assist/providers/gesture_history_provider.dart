import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/gesture_log_model.dart';
import '../services/gesture_log_local_service.dart';

class GestureHistoryProvider extends ChangeNotifier {
  final GestureLogLocalService _localService = GestureLogLocalService();
  List<GestureLogModel> _gestureLogs = [];
  bool _isLoading = false;

  List<GestureLogModel> get gestureLogs => _gestureLogs;
  bool get isLoading => _isLoading;

  Future<void> init() async {
    await fetchGestureLogs();
  }

  Future<void> addTestGesture(String type, String action) async {
    final newLog = GestureLogModel(
      id: const Uuid().v4(),
      userId: 'test_user',
      gestureType: type,
      action: action,
      confidence: 0.85 + (DateTime.now().millisecond % 15) / 100,
      screenContext: 'Testing Mode',
      timestamp: DateTime.now(),
    );
    await _localService.saveGestureLog(newLog);
    await fetchGestureLogs();
  }

  Future<void> clearAllLogs() async {
    final logs = await _localService.getGestureLogs();
    for (var log in logs) {
      await _localService.deleteGestureLog(log.id);
    }
    await fetchGestureLogs();
  }

  Future<void> fetchGestureLogs() async {
    _isLoading = true;
    notifyListeners();

    _gestureLogs = await _localService.getGestureLogs();
    // Sort by timestamp descending (newest first)
    _gestureLogs.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    _isLoading = false;
    notifyListeners();
  }
}

