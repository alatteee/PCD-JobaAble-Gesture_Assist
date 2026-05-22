import 'package:flutter/foundation.dart';

import '../../../services/connectivity_service.dart';
import '../../../services/mongo_service.dart';
import 'gesture_log_local_service.dart';

class GestureLogSyncService {
  static final GestureLogSyncService _instance =
      GestureLogSyncService._internal();

  factory GestureLogSyncService() => _instance;

  GestureLogSyncService._internal();

  final GestureLogLocalService _localService = GestureLogLocalService();

  bool _isSyncing = false;

  Future<int> syncPendingGestureLogs() async {
    if (_isSyncing) {
      debugPrint('[GestureLogSync] Sync skipped: already syncing.');
      return 0;
    }

    _isSyncing = true;

    try {
      final hasConnection = await connectivityService.checkConnection();

      if (!hasConnection) {
        debugPrint('[GestureLogSync] Offline. Pending logs tetap di Hive.');
        return 0;
      }

      final pendingLogs = await _localService.getPendingGestureLogs();

      if (pendingLogs.isEmpty) {
        debugPrint('[GestureLogSync] Tidak ada pending gesture log.');
        return 0;
      }

      debugPrint(
        '[GestureLogSync] Mulai sync ${pendingLogs.length} gesture logs...',
      );

      int syncedCount = 0;

      for (final log in pendingLogs) {
        final mongoData = log.toMap();
        mongoData['syncStatus'] = 'synced';

        final success = await MongoService.syncGestureData([mongoData]);

        if (success) {
          await _localService.updateSyncStatus(log.id, 'synced');
          syncedCount++;

          debugPrint(
            '[GestureLogSync] Synced: ${log.gestureType} | ${log.action} | ${log.screenContext}',
          );
        } else {
          debugPrint(
            '[GestureLogSync] Failed, keep pending: ${log.id}',
          );
        }
      }

      debugPrint(
        '[GestureLogSync] Selesai sync $syncedCount/${pendingLogs.length} logs.',
      );

      return syncedCount;
    } catch (e) {
      debugPrint('[GestureLogSync] Error syncPendingGestureLogs: $e');
      return 0;
    } finally {
      _isSyncing = false;
    }
  }
}