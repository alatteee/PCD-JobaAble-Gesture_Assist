import 'package:mongo_dart/mongo_dart.dart';
import '../../services/mongo_service.dart';
import '../auth/auth_controller.dart';

class ProfileController {
  
  static Future<Map<String, dynamic>?> getProfileByUserId(ObjectId userId) async {
    if (MongoService.db.state == State.closed) {
      await MongoService.connect();
    }
    try {
      final profile = await MongoService.userDetails.findOne(where.eq('user_id', userId));
      return profile;
    } catch (e) {
      print('Error getProfileByUserId: $e');
      return null;
    }
  }

  static Future<bool> profileExists(ObjectId userId) async {
    try {
      final profile = await getProfileByUserId(userId);
      return profile != null;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> updatePassword(ObjectId userId, String oldPassword, String newPassword) async {
    if (MongoService.db.state == State.closed) {
      await MongoService.connect();
    }
    try {
      // 1. Hash input password lama & baru menggunakan method dari AuthController
      final oldPasswordHash = AuthController.hashPassword(oldPassword.trim());
      final newPasswordHash = AuthController.hashPassword(newPassword.trim());

      // 2. Cari user dengan ID dan SHA-256 hash password lama yang sesuai
      final user = await MongoService.users.findOne(
        where.id(userId).eq('password_hash', oldPasswordHash)
      );
      
      if (user == null) {
        print('Verifikasi Gagal: Password lama (setelah dihash) tidak cocok dengan password_hash di DB');
        return false;
      }

      // 3. Update field password_hash dengan hash baru
      await MongoService.users.update(
        where.id(userId),
        modify.set('password_hash', newPasswordHash).set('updated_at', DateTime.now())
      );
      
      print('Update Password Berhasil');
      return true;
    } catch (e) {
      print('Error detail updatePassword: $e');
      return false;
    }
  }

  static Future<bool> createOrUpdateProfile(Map<String, dynamic> data) async {
    try {
      final userId = data['user_id'];
      
      if (await profileExists(userId)) {
        data['updated_at'] = DateTime.now();
        await MongoService.userDetails.update(where.eq('user_id', userId), { r'$set': data });
      } else {
        data['created_at'] = DateTime.now();
        data['updated_at'] = DateTime.now();
        await MongoService.userDetails.insert(data);
      }
      return true;
    } catch (e) {
      print('Error createOrUpdateProfile: $e');
      return false;
    }
  }
}

