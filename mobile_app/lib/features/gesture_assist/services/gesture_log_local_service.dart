import 'package:hive/hive.dart';
import '../models/gesture_log_model.dart';

class GestureLogLocalService {
  static const String _boxName = 'gestureLogs';

  Future<Box<GestureLogModel>> _openBox() async {
    return Hive.box<GestureLogModel>(_boxName);
  }

  Future<void> saveGestureLog(GestureLogModel log) async {
    final box = await _openBox();
    await box.put(log.id, log);
  }

  Future<List<GestureLogModel>> getGestureLogs() async {
    final box = await _openBox();
    return box.values.toList();
  }

  Future<List<GestureLogModel>> getPendingGestureLogs() async {
    final box = await _openBox();
    return box.values.where((log) => log.syncStatus == 'pending').toList();
  }

  Future<void> updateSyncStatus(String logId, String status) async {
    final box = await _openBox();
    final log = box.get(logId);
    if (log != null) {
      log.copyWith(syncStatus: status);
      await box.put(logId, log);
    }
  }

  Future<void> deleteGestureLog(String logId) async {
    final box = await _openBox();
    await box.delete(logId);
  }
}
