import 'dart:async';

import 'package:flutter/material.dart' hide State;

import '../features/cv/cv_controller.dart';
import '../features/profile/profile_controller.dart';
import 'connectivity_service.dart';
import 'mongo_service.dart';
import 'offline_service.dart';

class SyncService {
  static bool _isSyncing = false;
  static bool? _lastConnectionStatus;
  static bool _initialized = false;
  static bool _hasShownOfflineSnackBar = false;
  static StreamSubscription<bool>? _connectionSubscription;

  static void initialize(BuildContext context) {
    if (_initialized) return;
    _initialized = true;

    final messenger = ScaffoldMessenger.of(context);

    _connectionSubscription =
        connectivityService.connectionStream.listen((hasConnection) async {
      // Event pertama hanya disimpan sebagai status awal.
      // Jangan munculkan SnackBar apa pun saat app baru dibuka.
      if (_lastConnectionStatus == null) {
        _lastConnectionStatus = hasConnection;
        return;
      }

      if (_lastConnectionStatus == hasConnection) return;

      // Kalau terdeteksi offline, cek ulang cepat.
      // Ini mencegah false offline saat app baru start / jaringan sedang transisi.
      if (!hasConnection) {
        await Future.delayed(const Duration(milliseconds: 900));

        final stillOffline = !(await connectivityService.refresh());

        if (!stillOffline) {
          _lastConnectionStatus = true;
          return;
        }

        _lastConnectionStatus = false;
        _hasShownOfflineSnackBar = true;
        _handleOffline(messenger);
        return;
      }

      _lastConnectionStatus = true;

      // SnackBar online hanya muncul kalau sebelumnya user benar-benar
      // sudah melihat SnackBar offline.
      if (_hasShownOfflineSnackBar) {
        _hasShownOfflineSnackBar = false;
        _handleBackOnline(messenger);
      } else {
        // Tetap sync diam-diam tanpa SnackBar.
        Future.delayed(const Duration(seconds: 3), performSync);
      }
    });
  }

  static void _handleOffline(ScaffoldMessengerState messenger) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.wifi_off, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text('Koneksi terputus. Data akan tersimpan offline.'),
              ),
            ],
          ),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 4),
        ),
      );
  }

  static void _handleBackOnline(ScaffoldMessengerState messenger) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.wifi, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text('Koneksi internet tersedia. Mensinkronisasi...'),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

    Future.delayed(const Duration(seconds: 3), performSync);
  }

  static Future<bool> _prepareMongoConnection() async {
    // Pakai status koneksi global dulu, jangan DNS lookup.
    bool hasConnection = connectivityService.isOnline;

    // Kalau status terakhir offline, coba refresh cepat sekali.
    if (!hasConnection) {
      hasConnection = await connectivityService.refresh();
    }

    if (!hasConnection) {
      print('📴 Sync cancelled: no internet connection.');
      return false;
    }

    // Untuk sync, kita memang butuh koneksi Mongo yang benar-benar live.
    // Maka verifyLive dibuat true, tapi hanya di proses sync, bukan setiap query halaman.
    bool isLive = await MongoService.ensureConnected(verifyLive: true);

    if (isLive) return true;

    for (int i = 0; i < 5; i++) {
      await Future.delayed(const Duration(seconds: 1));

      isLive = await MongoService.ensureConnected(verifyLive: true);

      if (isLive) return true;

      print('⏳ Ensure/verify attempt ${i + 1}/5 failed. Retrying...');
    }

    print('🔁 Verify failed after retries. Forcing MongoDB reconnect...');

    await MongoService.forceReconnect();

    for (int i = 0; i < 3; i++) {
      await Future.delayed(const Duration(seconds: 1));

      isLive = await MongoService.verifyConnected(force: true);

      if (isLive) return true;

      print('⏳ Post-reconnect verify attempt ${i + 1}/3 failed. Retrying...');
    }

    return false;
  }

  static Future<void> performSync() async {
    if (_isSyncing) return;

    final queue = OfflineService.getSyncQueue();

    if (queue.isEmpty) {
      print('DEBUG: Sync queue is empty');
      return;
    }

    _isSyncing = true;
    print('DEBUG: Starting Background Sync for ${queue.length} item(s)...');

    final failedItems = <Map<String, dynamic>>[];

    try {
      print('⏳ Preparing MongoService live connection...');
      final mongoReady = await _prepareMongoConnection();

      if (!mongoReady) {
        print('❌ MongoDB not live. Sync cancelled. Queue kept.');
        return;
      }

      print(
        '✅ MongoService VERIFIED LIVE. Processing ${queue.length} item(s)...',
      );

      for (final item in queue) {
        final action = item['action']?.toString() ?? '';
        final rawData = item['data'];

        if (action.isEmpty || rawData == null) {
          print('⚠️ Invalid sync item skipped: $item');
          continue;
        }

        final data = Map<String, dynamic>.from(rawData);

        try {
          print('📤 Syncing: $action');

          final success = await _syncSingleItem(
            action: action,
            data: data,
          );

          if (success) {
            print('✅ Sync successful: $action');
          } else {
            print('❌ Sync returned false: $action');
            failedItems.add(item);
          }
        } catch (itemError) {
          print('❌ ERROR: Sync item failed ($action): $itemError');
          failedItems.add(item);
        }
      }

      await OfflineService.clearSyncQueue();

      for (final failedItem in failedItems) {
        await OfflineService.addToSyncQueue(
          failedItem['action']?.toString() ?? '',
          Map<String, dynamic>.from(failedItem['data']),
        );
      }

      if (failedItems.isEmpty) {
        print('✅ All sync completed successfully');
      } else {
        print(
          '⚠️ Sync completed with ${failedItems.length} failed item(s). Failed item(s) kept in queue.',
        );
      }
    } catch (e) {
      print('❌ ERROR: Sync process failed: $e');
    } finally {
      _isSyncing = false;
    }
  }

  static Future<bool> _syncSingleItem({
    required String action,
    required Map<String, dynamic> data,
  }) async {
    if (action == 'apply_job') {
      return await MongoService.submitJobApplicationOnlineOnly(data);
    }

    if (action == 'update_profile') {
      return await ProfileController.createOrUpdateProfile(data);
    }

    if (action == 'create_cv') {
      return await CvController.createCv(data);
    }

    if (action == 'update_cv') {
      final userId = data['userId'];
      final cvData = Map<String, dynamic>.from(data['data']);

      return await CvController.updateCv(userId, cvData);
    }

    if (action == 'update_company_profile') {
      final companyId = data['companyId']?.toString() ?? '';
      final compData = Map<String, dynamic>.from(data['data']);

      return await MongoService.updateCompanyProfile(
        companyId: companyId,
        data: compData,
      );
    }

    print('⚠️ Unknown sync action: $action');
    return false;
  }
}