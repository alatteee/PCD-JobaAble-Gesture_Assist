import 'package:hive_flutter/hive_flutter.dart';

class OfflineService {
  static const String jobsBoxName = 'offline_jobs';
  static const String applicationsBoxName = 'offline_applications';
  static const String userProfileBoxName = 'offline_user_profile';       // Profil pencaker
  static const String userCVBoxName = 'offline_user_cv';                 // CV pencaker
  static const String companyProfileBoxName = 'offline_company_profile'; // Profil company
  static const String companyJobsBoxName = 'offline_company_jobs';       
  static const String companyApplicantsBoxName = 'offline_company_applicants'; // Pelamar untuk company
  static const String pendingSyncBoxName = 'pending_sync';
  static const String settingsBoxName = 'app_settings';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(jobsBoxName);
    await Hive.openBox(applicationsBoxName);
    await Hive.openBox(userProfileBoxName);
    await Hive.openBox(userCVBoxName);
    await Hive.openBox(companyProfileBoxName);
    await Hive.openBox(companyJobsBoxName);
    await Hive.openBox(companyApplicantsBoxName);
    await Hive.openBox(pendingSyncBoxName);
    await Hive.openBox(settingsBoxName);
  }

  // --- User Profile (Pencaker) ---
  static Map<String, dynamic>? getCachedUserProfile(String userId) {
    if (userId.isEmpty) return null;
    final box = Hive.box(userProfileBoxName);
    final data = box.get(userId);
    return data != null ? Map<String, dynamic>.from(data) : null;
  }

  static Future<void> cacheUserProfile(String userId, Map<String, dynamic> profile) async {
    if (userId.isEmpty) return;
    final box = Hive.box(userProfileBoxName);
    final data = _sanitizeForHive(profile);
    await box.put(userId, data);
  }

  // --- User CV ---
  static Map<String, dynamic>? getCachedUserCV(String userId) {
    if (userId.isEmpty) return null;
    final box = Hive.box(userCVBoxName);
    final data = box.get(userId);
    return data != null ? Map<String, dynamic>.from(data) : null;
  }

  static Future<void> cacheUserCV(String userId, Map<String, dynamic> cv) async {
    if (userId.isEmpty) return;
    final box = Hive.box(userCVBoxName);
    final data = _sanitizeForHive(cv);
    await box.put(userId, data);
  }

  // --- Company Profile ---
  static Map<String, dynamic>? getCachedCompanyProfile(String userId) {
    final box = Hive.box(companyProfileBoxName);
    final data = box.get(userId);
    return data != null ? Map<String, dynamic>.from(data) : null;
  }

  static Future<void> cacheCompanyProfile(String userId, Map<String, dynamic> profile) async {
    try {
      final box = Hive.box(companyProfileBoxName);
      final data = _sanitizeForHive(Map<String, dynamic>.from(profile));
      await box.put(userId, data);
      print('✅ cacheCompanyProfile: Cached profile for user=$userId');
    } catch (e) {
      print('❌ ERROR cacheCompanyProfile: $e');
    }
  }

  // --- Company Jobs ---
  static List<Map<String, dynamic>> getCachedCompanyJobs(String userId) {
    final box = Hive.box(companyJobsBoxName);
    final data = box.get(userId);
    if (data == null) return [];
    return (data as List).map((e) => Map<String, dynamic>.from(e)).toList();
  }

  static Future<void> cacheCompanyJobs(String userId, List<Map<String, dynamic>> jobs) async {
    try {
      final box = Hive.box(companyJobsBoxName);
      final castedJobs = jobs.map((job) => _sanitizeForHive(Map<String, dynamic>.from(job))).toList();
      await box.put(userId, castedJobs);
      print('✅ cacheCompanyJobs: Cached ${castedJobs.length} jobs for user=$userId');
    } catch (e) {
      print('❌ ERROR cacheCompanyJobs: $e');
    }
  }

  // --- Company Applicants ---
  static List<Map<String, dynamic>> getCachedCompanyApplicants(String userId) {
    final box = Hive.box(companyApplicantsBoxName);
    final data = box.get(userId);
    if (data == null) return [];
    return (data as List).map((e) => Map<String, dynamic>.from(e)).toList();
  }

  static Future<void> cacheCompanyApplicants(String userId, List<Map<String, dynamic>> applicants) async {
    try {
      final box = Hive.box(companyApplicantsBoxName);
      final sanitized = applicants.map((applicant) => _sanitizeForHive(applicant)).toList();
      await box.put(userId, sanitized);
      print('✅ cacheCompanyApplicants: Cached ${sanitized.length} applicants for user=$userId');
    } catch (e) {
      print('❌ ERROR cacheCompanyApplicants: $e');
    }
  }

  // --- Jobs ---
  static List<Map<String, dynamic>> getCachedJobs() {
    final box = Hive.box(jobsBoxName);
    return box.values.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  static Future<void> cacheJobs(List<Map<String, dynamic>> jobs) async {
    final box = Hive.box(jobsBoxName);
    await box.clear();
    for (var job in jobs) {
      final data = _sanitizeForHive(job);
      await box.add(data);
    }
  }

  // --- Applications ---
  static List<Map<String, dynamic>> getCachedApplications() {
    final box = Hive.box(applicationsBoxName);
    return box.values.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  static Future<void> cacheApplications(List<Map<String, dynamic>> applications) async {
    final box = Hive.box(applicationsBoxName);
    await box.clear();
    for (var app in applications) {
      final data = _sanitizeForHive(app);
      await box.add(data);
    }
  }

  // Helper untuk membersihkan data dari tipe data MongoDB (ObjectId) yang tidak didukung Hive
  static Map<String, dynamic> _sanitizeForHive(Map<String, dynamic> rawData) {
    final Map<String, dynamic> sanitized = {};
    rawData.forEach((key, value) {
      if (value is Map) {
        sanitized[key] = _sanitizeForHive(Map<String, dynamic>.from(value));
      } else if (value is List) {
        sanitized[key] = value.map((e) {
          if (e is Map) return _sanitizeForHive(Map<String, dynamic>.from(e));
          if (e.runtimeType.toString().contains('ObjectId')) return e.toString();
          return e;
        }).toList();
      } else if (value.runtimeType.toString().contains('ObjectId')) {
        sanitized[key] = value.toString();
      } else {
        sanitized[key] = value;
      }
    });
    return sanitized;
  }

  // --- Sync Queue ---
  static Future<void> addToSyncQueue(String action, Map<String, dynamic> data) async {
    final box = Hive.box(pendingSyncBoxName);
    // Sanitize data sebelum masuk queue agar tidak ada ObjectId
    final sanitizedData = _sanitizeForHive(data);
    await box.add({
      'action': action,
      'data': sanitizedData,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  static List<Map<String, dynamic>> getSyncQueue() {
    final box = Hive.box(pendingSyncBoxName);
    return box.values.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  static Future<void> clearSyncQueue() async {
    await Hive.box(pendingSyncBoxName).clear();
  }

  // --- App Settings & Auth ---
  static bool get hasSeenOnboarding {
    final box = Hive.box(settingsBoxName);
    return box.get('hasSeenOnboarding', defaultValue: false);
  }

  static Future<void> setHasSeenOnboarding(bool value) async {
    final box = Hive.box(settingsBoxName);
    await box.put('hasSeenOnboarding', value);
  }

  static Map<String, dynamic>? getLoggedInUser() {
    final box = Hive.box(settingsBoxName);
    final data = box.get('loggedInUser');
    return data != null ? Map<String, dynamic>.from(data) : null;
  }

  static Future<void> setLoggedInUser(Map<String, dynamic> user) async {
    final box = Hive.box(settingsBoxName);
    await box.put('loggedInUser', _sanitizeForHive(user));
  }

  static Future<void> clearLoggedInUser() async {
    final box = Hive.box(settingsBoxName);
    await box.delete('loggedInUser');
  }
}
