import 'package:hive/hive.dart';

import '../models/gesture_log_model.dart';

class GestureLogLocalService {
  static const String _boxName = 'gestureLogs';

  Future<Box<GestureLogModel>> _openBox() async {
    if (Hive.isBoxOpen(_boxName)) {
      return Hive.box<GestureLogModel>(_boxName);
    }

    return Hive.openBox<GestureLogModel>(_boxName);
  }

  Future<void> saveGestureLog(GestureLogModel log) async {
    final box = await _openBox();
    await box.put(log.id, log);
  }

  Future<List<GestureLogModel>> getGestureLogs() async {
    final box = await _openBox();

    final logs = box.values.toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return logs;
  }

  Future<void> deleteGestureLog(String logId) async {
    final box = await _openBox();
    await box.delete(logId);
  }

  Future<void> clearGestureLogs() async {
    final box = await _openBox();
    await box.clear();
  }
}