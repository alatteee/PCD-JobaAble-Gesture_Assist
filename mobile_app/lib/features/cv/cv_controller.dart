import 'package:mongo_dart/mongo_dart.dart';
import '../../services/mongo_service.dart';
import '../../services/connectivity_service.dart';
import '../../services/offline_service.dart';

class CvController {
  static Future<Map<String, dynamic>?> getCvByUserId(dynamic userId) async {
    try {
      final hasConnection = await connectivityService.checkConnection();
      
      String? uidString;
      ObjectId? uid;
      
      if (userId is ObjectId) {
        uid = userId;
        uidString = userId.toHexString();
      } else if (userId is String) {
        if (userId.startsWith('ObjectId("') && userId.endsWith('")')) {
          uidString = userId.substring(10, userId.length - 2);
        } else {
          uidString = userId;
        }
        uid = ObjectId.fromHexString(uidString);
      }

      if (uidString != null && !hasConnection) {
        print('📱 CV: Offline. Using cache.');
        return OfflineService.getCachedUserCV(uidString);
      }

      // Cek dengan truly verify connection
      await MongoService.ensureConnected();
      final isLive = await MongoService.verifyConnected();
      
      if (!isLive && uidString != null) {
        print('⚠️ CV: DB not live. Using cache.');
        return OfflineService.getCachedUserCV(uidString);
      }

      if (uid == null) return null;

      final cv = await MongoService.cvs.findOne(where.eq('user_id', uid));
      
      if (cv != null && uidString != null) {
        await OfflineService.cacheUserCV(uidString, cv);
      } else if (uidString != null) {
        // Kalau DB tidak ada tapi cache ada, gunakan cache
        final cachedCv = OfflineService.getCachedUserCV(uidString);
        if (cachedCv != null) {
          print('💾 CV: Using cached CV (DB has none)');
          return cachedCv;
        }
      }
      
      return cv;
    } catch (e) {
      print('❌ Error getCvByUserId: $e');
      // Tentukan uidString untuk fallback
      String? uidString;
      if (userId is ObjectId) {
        uidString = userId.toHexString();
      } else if (userId is String) {
        uidString = userId.startsWith('ObjectId("') && userId.endsWith('")') 
            ? userId.substring(10, userId.length - 2) 
            : userId;
      }
      // Fallback ke cache saat error
      return uidString != null ? OfflineService.getCachedUserCV(uidString) : null;
    }
  }

  static Future<bool> createCv(Map<String, dynamic> data) async {
    try {
      final hasConnection = await connectivityService.checkConnection();
      final userId = data['user_id'];
      String? uidString;
      
      if (userId is ObjectId) {
        uidString = userId.toHexString();
      } else if (userId is String) uidString = userId;

      if (!hasConnection && uidString != null) {
        print('📱 CV creation: Offline. Queueing sync.');
        await OfflineService.cacheUserCV(uidString, data);
        await OfflineService.addToSyncQueue('create_cv', data);
        return true;
      }

      await MongoService.ensureConnected();
      
      // Verify koneksi sebelum operasi DB
      final isLive = await MongoService.verifyConnected();
      if (!isLive && uidString != null) {
        print('⚠️ CV creation: DB not live. Queueing sync.');
        await OfflineService.cacheUserCV(uidString, data);
        await OfflineService.addToSyncQueue('create_cv', data);
        return true;
      }
      
      data['created_at'] = DateTime.now();
      data['updated_at'] = DateTime.now();
      
      final result = await MongoService.cvs.insertOne(data);
      
      if (result.isSuccess && uidString != null) {
        await OfflineService.cacheUserCV(uidString, data);
      }
      
      return result.isSuccess;
    } catch (e) {
      print('❌ Error createCv: $e');
      // Fallback: cache dan queue untuk sync nanti
      try {
        final userId = data['user_id'];
        String? uidString;
        if (userId is ObjectId) {
          uidString = userId.toHexString();
        } else if (userId is String) uidString = userId;
        
        if (uidString != null) {
          await OfflineService.cacheUserCV(uidString, data);
          await OfflineService.addToSyncQueue('create_cv', data);
          return true;
        }
        return false;
      } catch (fallbackError) {
        print('Fallback error: $fallbackError');
        return false;
      }
    }
  }

  static Future<bool> updateCv(dynamic userId, Map<String, dynamic> data) async {
    try {
      final hasConnection = await connectivityService.checkConnection();
      String? uidString;
      ObjectId? uid;

      if (userId is ObjectId) {
        uid = userId;
        uidString = userId.toHexString();
      } else if (userId is String) {
        uidString = userId;
        uid = ObjectId.fromHexString(userId);
      }

      if (uid == null) return false;

      if (!hasConnection && uidString != null) {
        print('📱 CV update: Offline. Queueing sync.');
        // Ambil data lama dulu untuk merge jika perlu, tapi di sini kita replace field utama
        await OfflineService.cacheUserCV(uidString, data);
        await OfflineService.addToSyncQueue('update_cv', {'userId': uidString, 'data': data});
        return true;
      }

      await MongoService.ensureConnected();
      
      // Verify koneksi sebelum operasi DB
      final isLive = await MongoService.verifyConnected();
      if (!isLive && uidString != null) {
        print('⚠️ CV update: DB not live. Queueing sync.');
        await OfflineService.cacheUserCV(uidString, data);
        await OfflineService.addToSyncQueue('update_cv', {'userId': uidString, 'data': data});
        return true;
      }
      
      data['updated_at'] = DateTime.now();
      
      final result = await MongoService.cvs.updateOne(
        where.eq('user_id', uid),
        modify
            .set('summary', data['summary'])
            .set('education', data['education'])
            .set('experience', data['experience'])
            .set('skills', data['skills'])
            .set('certifications', data['certifications'])
            .set('portfolio_link', data['portfolio_link'])
            .set('updated_at', data['updated_at']),
      );

      if (result.isSuccess && uidString != null) {
        await OfflineService.cacheUserCV(uidString, data);
      }

      return result.isSuccess;
    } catch (e) {
      print('❌ Error updateCv: $e');
      // Fallback: cache dan queue untuk sync nanti
      try {
        String? uidString;
        if (userId is ObjectId) {
          uidString = userId.toHexString();
        } else if (userId is String) uidString = userId;
        
        if (uidString != null) {
          await OfflineService.cacheUserCV(uidString, data);
          await OfflineService.addToSyncQueue('update_cv', {'userId': uidString, 'data': data});
          return true;
        }
        return false;
      } catch (fallbackError) {
        print('Fallback error: $fallbackError');
        return false;
      }
    }
  }

  static Future<bool> createOrUpdateCv(dynamic userId, Map<String, dynamic> data) async {
    final exists = await cvExists(userId);
    if (exists) {
      return await updateCv(userId, data);
    } else {
      return await createCv(data);
    }
  }

  static Future<bool> cvExists(dynamic userId) async {
    try {
      final cv = await getCvByUserId(userId);
      return cv != null;
    } catch (e) {
      return false;
    }
  }
}
