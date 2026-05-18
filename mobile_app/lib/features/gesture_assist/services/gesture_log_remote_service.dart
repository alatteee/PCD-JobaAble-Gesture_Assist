import '../../../services/mongo_service.dart';
import '../models/gesture_log_model.dart';

class GestureLogRemoteService {
  Future<bool> syncGestureLogs(List<GestureLogModel> logs) async {
    if (logs.isEmpty) return true;

    try {
      // Assuming a method like syncGestureLogs exists in MongoService
      // or we use a general sync endpoint
      final List<Map<String, dynamic>> data =
          logs.map((log) => log.toMap()).toList();

      // For now, let's use a placeholder or check if MongoService has a generic insert
      // Based on JobAble patterns, we usually pass to a controller or specific method
      return await MongoService.syncGestureData(data);
    } catch (e) {
      print('❌ Remote Sync Error: $e');
      return false;
    }
  }
}

