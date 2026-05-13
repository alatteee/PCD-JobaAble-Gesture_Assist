import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../../services/mongo_service.dart';
import '../../services/offline_service.dart';

class AuthController {
  
  // Method untuk Hash Password
  static String hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Cek apakah Email sudah terdaftar
  static Future<bool> isEmailExists(String email) async {
    try {
      final user = await MongoService.users.findOne({'email': email});
      return user != null;
    } catch (e) {
      return false;
    }
  }

  // Cek apakah Phone sudah terdaftar
  static Future<bool> isPhoneExists(String phone) async {
    try {
      final user = await MongoService.users.findOne({'phone': phone});
      return user != null;
    } catch (e) {
      return false;
    }
  }

  // Logic Sign Up
  static Future<Map<String, dynamic>?> signUp({
    required String username,
    required String email,
    required String phone,
    required String password,
    required String role,
  }) async {
    try {
      // 1. Cek Email & Phone duplication
      if (await isEmailExists(email)) {
        return {'error': 'Email sudah terdaftar. Gunakan email lain.'};
      }
      if (await isPhoneExists(phone)) {
        return {'error': 'Nomor HP sudah terdaftar. Gunakan nomor lain.'};
      }

      // 2. Hash Password
      final passwordHash = hashPassword(password);
      
      // 3. Insert User to Database
      final result = await MongoService.users.insertOne({
        "username": username,
        "email": email,
        "phone": phone,
        "password_hash": passwordHash,
        "role": role,
        "created_at": DateTime.now(),
        "updated_at": DateTime.now()
      });

      // 4. Get the inserted user ID
      final userId = result.id;

      // 5. If company, create company record
      if (role == 'company') {
        await MongoService.createCompany(
          userId: userId,
          companyName: username,
          email: email,
          phone: phone,
        );
      }

      // 6. Return user data with ID
      return {
        '_id': userId,
        'username': username,
        'email': email,
        'phone': phone,
        'role': role,
      };
    } catch (e) {
      return {'error': 'Gagal melakukan pendaftaran: \'$e\''};
    } 
  }

  // Logic Login
  static Future<Map<String, dynamic>?> login({
    required String email,
    required String password,
  }) async {
    try {
      final passwordHash = hashPassword(password);
      final user = await MongoService.users.findOne({
        'email': email,
        'password_hash': passwordHash,
      });
      if (user != null) {
        await OfflineService.setLoggedInUser(user);
      }
      return user; // Return map data user jika ada, null jika salah
    } catch (e) {
      return null;
    }
  }
}
