import 'package:mongo_dart/mongo_dart.dart';
import '../../services/mongo_service.dart';

class CvController {
  static Future<Map<String, dynamic>?> getCvByUserId(dynamic userId) async {
    try {
      await MongoService.ensureConnected();
      ObjectId? uid;
      if (userId is ObjectId) {
        uid = userId;
      } else if (userId is String) {
        // Handle case where String is "ObjectId('...')"
        if (userId.startsWith('ObjectId("') && userId.endsWith('")')) {
          uid = ObjectId.fromHexString(userId.substring(10, userId.length - 2));
        } else {
          uid = ObjectId.fromHexString(userId);
        }
      }

      if (uid == null) return null;

      final cv = await MongoService.cvs.findOne(where.eq('user_id', uid));
      return cv;
    } catch (e) {
      print('Error getCvByUserId: $e');
      return null;
    }
  }

  static Future<bool> createCv(Map<String, dynamic> data) async {
    try {
      await MongoService.ensureConnected();
      data['created_at'] = DateTime.now();
      data['updated_at'] = DateTime.now();
      
      final result = await MongoService.cvs.insertOne(data);
      return result.isSuccess;
    } catch (e) {
      print('Error createCv: $e');
      return false;
    }
  }

  static Future<bool> updateCv(dynamic userId, Map<String, dynamic> data) async {
    try {
      await MongoService.ensureConnected();
      ObjectId? uid;
      if (userId is ObjectId) {
        uid = userId;
      } else if (userId is String) {
        uid = ObjectId.fromHexString(userId);
      }

      if (uid == null) return false;

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
      return result.isSuccess;
    } catch (e) {
      print('Error updateCv: $e');
      return false;
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
      await MongoService.ensureConnected();
      ObjectId? uid;
      if (userId is ObjectId) {
        uid = userId;
      } else if (userId is String) {
        // Handle case where String is "ObjectId('...')"
        if (userId.startsWith('ObjectId("') && userId.endsWith('")')) {
          uid = ObjectId.fromHexString(userId.substring(10, userId.length - 2));
        } else {
          uid = ObjectId.fromHexString(userId);
        }
      }

      if (uid == null) return false;

      final count = await MongoService.cvs.count(where.eq('user_id', uid));
      return count > 0;
    } catch (e) {
      print('Error cvExists: $e');
      return false;
    }
  }
}
