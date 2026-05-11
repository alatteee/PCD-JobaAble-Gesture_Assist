import 'package:flutter/material.dart' hide State;
import 'package:mongo_dart/mongo_dart.dart' show State;
import 'connectivity_service.dart';
import 'offline_service.dart';
import 'mongo_service.dart';
import '../features/profile/profile_controller.dart';
import '../features/cv/cv_controller.dart';

class SyncService {
  static bool _isSyncing = false;
  static bool? _lastConnectionStatus;

  static void initialize(BuildContext context) {
    connectivityService.connectionStream.listen((hasConnection) {
      // Hanya tampilkan snackbar jika status benar-benar berubah
      if (_lastConnectionStatus == hasConnection) return;
      _lastConnectionStatus = hasConnection;

      if (hasConnection) {
        _handleBackOnline(context);
      } else {
        _handleOffline(context);
      }
    });
  }

  static void _handleOffline(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.wifi_off, color: Colors.white),
            SizedBox(width: 12),
            Expanded(child: Text('Koneksi terputus. Data akan tersimpan offline.')),
          ],
        ),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 4),
      ),
    );
  }

  static void _handleBackOnline(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.wifi, color: Colors.white),
            SizedBox(width: 12),
            Expanded(child: Text('Koneksi internet tersedia. Mensinkronisasi...')),
          ],
        ),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
    performSync();
  }

  static Future<void> performSync() async {
    if (_isSyncing) return;
    
    final queue = OfflineService.getSyncQueue();
    if (queue.isEmpty) {
      print('DEBUG: Sync queue is empty');
      return;
    }

    _isSyncing = true;
    print('DEBUG: Starting Background Sync for ${queue.length} items...');

    try {
      // Tunggu hingga koneksi DB benar-benar siap SEBELUM memproses queue
      print('⏳ Waiting for MongoService to be ready...');
      await MongoService.ensureConnected();
      
      // Double check dengan truly verify connection (actual ping)
      print('🔍 Verifying MongoService connection is LIVE...');
      int verifyRetries = 0;
      bool isLive = false;
      while (!isLive && verifyRetries < 10) {
        isLive = await MongoService.verifyConnected();
        if (!isLive && verifyRetries < 9) {
          print('⏳ Verify attempt ${verifyRetries + 1}/10 failed. Retrying...');
          await Future.delayed(const Duration(milliseconds: 500));
        }
        verifyRetries++;
      }

      if (!isLive) {
        print('❌ FATAL: MongoService connection cannot be verified after 10 attempts. Aborting sync.');
        _isSyncing = false;
        return;
      }

      print('✅ MongoService VERIFIED LIVE. Processing ${queue.length} items...');

      // Sekarang baru proses queue
      for (var item in queue) {
        final action = item['action'];
        final data = Map<String, dynamic>.from(item['data']);

        try {
          print('📤 Syncing: $action');
          if (action == 'apply_job') {
            await MongoService.submitJobApplication(applicationData: data);
          } else if (action == 'update_profile') {
            await ProfileController.createOrUpdateProfile(data);
          } else if (action == 'create_cv') {
            await CvController.createCv(data);
          } else if (action == 'update_cv') {
            final userId = data['userId'];
            final cvData = Map<String, dynamic>.from(data['data']);
            await CvController.updateCv(userId, cvData);
          } else if (action == 'update_company_profile') {
            final companyId = data['companyId'];
            final compData = Map<String, dynamic>.from(data['data']);
            await MongoService.updateCompanyProfile(companyId: companyId, data: compData);
          }
          print('✅ Sync successful: $action');
        } catch (itemError) {
          print('❌ ERROR: Sync item failed ($action): $itemError');
          // Lanjutkan ke item berikutnya jika satu gagal
        }
      }
      
      await OfflineService.clearSyncQueue();
      print('✅ All sync completed successfully');
    } catch (e) {
      print('❌ ERROR: Sync process failed: $e');
    } finally {
      _isSyncing = false;
    }
  }
}
