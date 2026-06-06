import 'package:hive_flutter/hive_flutter.dart';
import 'package:mongo_dart/mongo_dart.dart' hide Box;

class OfflineService {
  static const String jobsBoxName = 'offline_jobs';
  static const String applicationsBoxName = 'offline_applications';
  static const String userProfileBoxName = 'offline_user_profile';
  static const String userCVBoxName = 'offline_user_cv';
  static const String companyProfileBoxName = 'offline_company_profile';
  static const String companyJobsBoxName = 'offline_company_jobs';
  static const String companyApplicantsBoxName = 'offline_company_applicants';
  static const String pendingSyncBoxName = 'pending_sync';
  static const String settingsBoxName = 'app_settings';

  // Box generic untuk cache-first halaman baru.
  static const String genericCacheBoxName = 'offline_generic_cache';

  static Future<void> init() async {
    await Hive.initFlutter();

    await _openBoxIfNeeded(jobsBoxName);
    await _openBoxIfNeeded(applicationsBoxName);
    await _openBoxIfNeeded(userProfileBoxName);
    await _openBoxIfNeeded(userCVBoxName);
    await _openBoxIfNeeded(companyProfileBoxName);
    await _openBoxIfNeeded(companyJobsBoxName);
    await _openBoxIfNeeded(companyApplicantsBoxName);
    await _openBoxIfNeeded(pendingSyncBoxName);
    await _openBoxIfNeeded(settingsBoxName);
    await _openBoxIfNeeded(genericCacheBoxName);
  }

  static Future<void> _openBoxIfNeeded(String boxName) async {
    if (!Hive.isBoxOpen(boxName)) {
      await Hive.openBox(boxName);
    }
  }

  static Box get _genericCacheBox => Hive.box(genericCacheBoxName);

  // ============================================================
  // GENERIC CACHE-FIRST HELPERS
  // ============================================================

  static List<Map<String, dynamic>> getCachedList(String key) {
    try {
      if (key.isEmpty) return [];

      final data = _genericCacheBox.get(key);

      if (data == null || data is! List) {
        return [];
      }

      return data
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    } catch (e) {
      print('❌ ERROR getCachedList($key): $e');
      return [];
    }
  }

  static Future<void> putCachedList(
    String key,
    List<Map<String, dynamic>> data,
  ) async {
    try {
      if (key.isEmpty) return;

      final sanitized = data
          .map(
            (item) => Map<String, dynamic>.from(
              _sanitizeDynamicForHive(item),
            ),
          )
          .toList();

      await _genericCacheBox.put(key, sanitized);
    } catch (e) {
      print('❌ ERROR putCachedList($key): $e');
    }
  }

  static Map<String, dynamic>? getCachedMap(String key) {
    try {
      if (key.isEmpty) return null;

      final data = _genericCacheBox.get(key);

      if (data == null || data is! Map) {
        return null;
      }

      return Map<String, dynamic>.from(data);
    } catch (e) {
      print('❌ ERROR getCachedMap($key): $e');
      return null;
    }
  }

  static Future<void> putCachedMap(
    String key,
    Map<String, dynamic> data,
  ) async {
    try {
      if (key.isEmpty) return;

      await _genericCacheBox.put(key, _sanitizeForHive(data));
    } catch (e) {
      print('❌ ERROR putCachedMap($key): $e');
    }
  }

  static Future<void> deleteCached(String key) async {
    try {
      if (key.isEmpty) return;

      await _genericCacheBox.delete(key);
    } catch (e) {
      print('❌ ERROR deleteCached($key): $e');
    }
  }

  // ============================================================
  // USER PROFILE Pencaker
  // ============================================================

  static Map<String, dynamic>? getCachedUserProfile(String userId) {
    try {
      if (userId.isEmpty) return null;

      final box = Hive.box(userProfileBoxName);
      final data = box.get(userId);

      return data != null ? Map<String, dynamic>.from(data) : null;
    } catch (e) {
      print('❌ ERROR getCachedUserProfile: $e');
      return null;
    }
  }

  static Future<void> cacheUserProfile(
    String userId,
    Map<String, dynamic> profile,
  ) async {
    try {
      if (userId.isEmpty) return;

      final box = Hive.box(userProfileBoxName);
      final data = _sanitizeForHive(profile);

      await box.put(userId, data);
    } catch (e) {
      print('❌ ERROR cacheUserProfile: $e');
    }
  }

  // ============================================================
  // USER CV
  // ============================================================

  static Map<String, dynamic>? getCachedUserCV(String userId) {
    try {
      if (userId.isEmpty) return null;

      final box = Hive.box(userCVBoxName);
      final data = box.get(userId);

      return data != null ? Map<String, dynamic>.from(data) : null;
    } catch (e) {
      print('❌ ERROR getCachedUserCV: $e');
      return null;
    }
  }

  static Future<void> cacheUserCV(
    String userId,
    Map<String, dynamic> cv,
  ) async {
    try {
      if (userId.isEmpty) return;

      final box = Hive.box(userCVBoxName);
      final data = _sanitizeForHive(cv);

      await box.put(userId, data);
    } catch (e) {
      print('❌ ERROR cacheUserCV: $e');
    }
  }

  // ============================================================
  // COMPANY PROFILE
  // ============================================================

  static Map<String, dynamic>? getCachedCompanyProfile(String userId) {
    try {
      if (userId.isEmpty) return null;

      final box = Hive.box(companyProfileBoxName);
      final data = box.get(userId);

      return data != null ? Map<String, dynamic>.from(data) : null;
    } catch (e) {
      print('❌ ERROR getCachedCompanyProfile: $e');
      return null;
    }
  }

  static Future<void> cacheCompanyProfile(
    String userId,
    Map<String, dynamic> profile,
  ) async {
    try {
      if (userId.isEmpty) return;

      final box = Hive.box(companyProfileBoxName);
      final data = _sanitizeForHive(Map<String, dynamic>.from(profile));

      await box.put(userId, data);

      print('✅ cacheCompanyProfile: Cached profile for user=$userId');
    } catch (e) {
      print('❌ ERROR cacheCompanyProfile: $e');
    }
  }

  // ============================================================
  // COMPANY JOBS
  // ============================================================

  static List<Map<String, dynamic>> getCachedCompanyJobs(String userId) {
    try {
      if (userId.isEmpty) return [];

      final box = Hive.box(companyJobsBoxName);
      final data = box.get(userId);

      if (data == null || data is! List) return [];

      return data
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    } catch (e) {
      print('❌ ERROR getCachedCompanyJobs: $e');
      return [];
    }
  }

  static Future<void> cacheCompanyJobs(
    String userId,
    List<Map<String, dynamic>> jobs,
  ) async {
    try {
      if (userId.isEmpty) return;

      final box = Hive.box(companyJobsBoxName);

      final castedJobs = jobs
          .map(
            (job) => _sanitizeForHive(Map<String, dynamic>.from(job)),
          )
          .toList();

      await box.put(userId, castedJobs);

      print(
        '✅ cacheCompanyJobs: Cached ${castedJobs.length} jobs for user=$userId',
      );
    } catch (e) {
      print('❌ ERROR cacheCompanyJobs: $e');
    }
  }

  // ============================================================
  // COMPANY APPLICANTS
  // ============================================================

  static List<Map<String, dynamic>> getCachedCompanyApplicants(String userId) {
    try {
      if (userId.isEmpty) return [];

      final box = Hive.box(companyApplicantsBoxName);
      final data = box.get(userId);

      if (data == null || data is! List) return [];

      return data
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    } catch (e) {
      print('❌ ERROR getCachedCompanyApplicants: $e');
      return [];
    }
  }

  static Future<void> cacheCompanyApplicants(
    String userId,
    List<Map<String, dynamic>> applicants,
  ) async {
    try {
      if (userId.isEmpty) return;

      final box = Hive.box(companyApplicantsBoxName);

      final sanitized = applicants
          .map(
            (applicant) => _sanitizeForHive(
              Map<String, dynamic>.from(applicant),
            ),
          )
          .toList();

      await box.put(userId, sanitized);

      print(
        '✅ cacheCompanyApplicants: Cached ${sanitized.length} applicants for user=$userId',
      );
    } catch (e) {
      print('❌ ERROR cacheCompanyApplicants: $e');
    }
  }

  // ============================================================
  // JOBS
  // ============================================================

  static List<Map<String, dynamic>> getCachedJobs() {
    try {
      final box = Hive.box(jobsBoxName);

      return box.values
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    } catch (e) {
      print('❌ ERROR getCachedJobs: $e');
      return [];
    }
  }

  static Future<void> cacheJobs(List<Map<String, dynamic>> jobs) async {
    try {
      final box = Hive.box(jobsBoxName);

      await box.clear();

      for (final job in jobs) {
        final data = _sanitizeForHive(Map<String, dynamic>.from(job));
        await box.add(data);
      }

      // Mirror ke generic cache supaya halaman baru bisa pakai cache-first key.
      await putCachedList('home_active_jobs', jobs);
    } catch (e) {
      print('❌ ERROR cacheJobs: $e');
    }
  }

  // ============================================================
  // APPLICATIONS
  // ============================================================

  static List<Map<String, dynamic>> getCachedApplications() {
    try {
      final box = Hive.box(applicationsBoxName);

      return box.values
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    } catch (e) {
      print('❌ ERROR getCachedApplications: $e');
      return [];
    }
  }

  static Future<void> cacheApplications(
    List<Map<String, dynamic>> applications,
  ) async {
    try {
      final box = Hive.box(applicationsBoxName);

      await box.clear();

      for (final app in applications) {
        final data = _sanitizeForHive(Map<String, dynamic>.from(app));
        await box.add(data);
      }

      await putCachedList('user_applications', applications);
    } catch (e) {
      print('❌ ERROR cacheApplications: $e');
    }
  }

  // ============================================================
  // SANITIZER
  // ============================================================

  static Map<String, dynamic> _sanitizeForHive(Map<String, dynamic> rawData) {
    return Map<String, dynamic>.from(_sanitizeDynamicForHive(rawData));
  }

  static dynamic _sanitizeDynamicForHive(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is ObjectId) {
      return value.oid;
    }

    if (value is Map) {
      final sanitized = <String, dynamic>{};

      value.forEach((key, mapValue) {
        sanitized[key.toString()] = _sanitizeDynamicForHive(mapValue);
      });

      return sanitized;
    }

    if (value is Iterable && value is! String) {
      return value.map(_sanitizeDynamicForHive).toList();
    }

    if (value.runtimeType.toString().contains('ObjectId')) {
      return value.toString();
    }

    return value;
  }

  // ============================================================
  // SYNC QUEUE
  // ============================================================

  static Future<void> addToSyncQueue(
    String action,
    Map<String, dynamic> data,
  ) async {
    try {
      final box = Hive.box(pendingSyncBoxName);

      final sanitizedData = _sanitizeForHive(data);

      await box.add({
        'action': action,
        'data': sanitizedData,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('❌ ERROR addToSyncQueue: $e');
    }
  }

  static List<Map<String, dynamic>> getSyncQueue() {
    try {
      final box = Hive.box(pendingSyncBoxName);

      return box.values
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    } catch (e) {
      print('❌ ERROR getSyncQueue: $e');
      return [];
    }
  }

  static Future<void> clearSyncQueue() async {
    try {
      await Hive.box(pendingSyncBoxName).clear();
    } catch (e) {
      print('❌ ERROR clearSyncQueue: $e');
    }
  }

  // ============================================================
  // APP SETTINGS & AUTH
  // ============================================================

  static bool get hasSeenOnboarding {
    try {
      final box = Hive.box(settingsBoxName);

      return box.get('hasSeenOnboarding', defaultValue: false);
    } catch (e) {
      print('❌ ERROR hasSeenOnboarding: $e');
      return false;
    }
  }

  static Future<void> setHasSeenOnboarding(bool value) async {
    try {
      final box = Hive.box(settingsBoxName);

      await box.put('hasSeenOnboarding', value);
    } catch (e) {
      print('❌ ERROR setHasSeenOnboarding: $e');
    }
  }

  static Map<String, dynamic>? getLoggedInUser() {
    try {
      final box = Hive.box(settingsBoxName);
      final data = box.get('loggedInUser');

      return data != null ? Map<String, dynamic>.from(data) : null;
    } catch (e) {
      print('❌ ERROR getLoggedInUser: $e');
      return null;
    }
  }

  static Future<void> setLoggedInUser(Map<String, dynamic> user) async {
    try {
      final box = Hive.box(settingsBoxName);

      await box.put('loggedInUser', _sanitizeForHive(user));
    } catch (e) {
      print('❌ ERROR setLoggedInUser: $e');
    }
  }

  static Future<void> clearLoggedInUser() async {
    try {
      final box = Hive.box(settingsBoxName);

      await box.delete('loggedInUser');
    } catch (e) {
      print('❌ ERROR clearLoggedInUser: $e');
    }
  }

  // ============================================================
  // CACHE MANAGEMENT & DEBUGGING
  // ============================================================

  static Future<void> clearJobsCache() async {
    try {
      final box = Hive.box(jobsBoxName);

      await box.clear();
      await deleteCached('home_active_jobs');

      print('✅ Jobs cache cleared successfully');
    } catch (e) {
      print('❌ Error clearing jobs cache: $e');
    }
  }

  static Future<void> clearGenericCache() async {
    try {
      await Hive.box(genericCacheBoxName).clear();

      print('✅ Generic cache cleared successfully');
    } catch (e) {
      print('❌ Error clearing generic cache: $e');
    }
  }

  static Future<void> clearAllCache() async {
    try {
      await Hive.box(jobsBoxName).clear();
      await Hive.box(applicationsBoxName).clear();
      await Hive.box(userProfileBoxName).clear();
      await Hive.box(userCVBoxName).clear();
      await Hive.box(companyProfileBoxName).clear();
      await Hive.box(companyJobsBoxName).clear();
      await Hive.box(companyApplicantsBoxName).clear();
      await Hive.box(pendingSyncBoxName).clear();
      await Hive.box(genericCacheBoxName).clear();

      print('✅ All cache cleared successfully');
    } catch (e) {
      print('❌ Error clearing all cache: $e');
    }
  }

  static void debugCachedJobsCount() {
    try {
      final box = Hive.box(jobsBoxName);

      print('📊 DEBUG: Total cached jobs: ${box.length}');

      if (box.isNotEmpty) {
        final firstJob = Map<String, dynamic>.from(box.values.first as Map);

        print(
          '📊 DEBUG: First job has job_photo: ${firstJob.containsKey('job_photo')}',
        );

        if (firstJob.containsKey('job_photo')) {
          final photoLength = firstJob['job_photo']?.toString().length ?? 0;

          print('📊 DEBUG: job_photo field size: $photoLength bytes');
        }
      }
    } catch (e) {
      print('❌ ERROR debugCachedJobsCount: $e');
    }
  }
}