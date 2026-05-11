import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'offline_service.dart';
import 'connectivity_service.dart';

class MongoService {
  static late Db db;
  static late DbCollection users;
  static late DbCollection userDetails;
  static late DbCollection cvs;

  static bool _isConnecting = false;

  /// Tutup koneksi lama dengan paksa dan reset semua reference
  static Future<void> _forceCloseOldConnection() async {
    try {
      if (db != null) {
        try {
          await db.close();
          print('🔴 Old MongoDB connection closed');
        } catch (e) {
          print('⚠️ Error closing old connection: $e');
        }
      }
    } catch (_) {}
  }

  static Future<void> connect() async {
    final uri = dotenv.env['MONGODB_URI'];

    if (uri == null || uri.isEmpty) {
      throw Exception('MONGODB_URI tidak ditemukan');
    }

    if (_isDbOpen) return;
    if (_isConnecting) return;

    _isConnecting = true;
    try {
      // Tutup koneksi lama sebelum membuat yang baru
      await _forceCloseOldConnection();

      String finalUri = uri;
      if (!finalUri.contains('tls=')) {
        final separator = finalUri.contains('?') ? '&' : '?';
        finalUri +=
            '${separator}tls=true&safeAtlas=true&keepAlive=true&connectTimeoutMS=10000&socketTimeoutMS=45000&maxIdleTimeMS=10000';
      }

      print('🔄 Connecting to MongoDB Atlas (fresh connection)...');
      db = await Db.create(finalUri);
      await db.open();

      users = db.collection('users');
      userDetails = db.collection('user_details');
      cvs = db.collection('cvs');

      print('✅ MongoDB Connected (NEW)');
    } catch (e) {
      print('❌ Gagal koneksi ke MongoDB: $e');
      try {
        await db.close();
      } catch (_) {}
    } finally {
      _isConnecting = false;
    }
  }

  static bool get _isDbOpen {
    try {
      // ignore: unnecessary_null_comparison
      if (db == null) return false;
      return db.state == State.open;
    } catch (_) {
      return false;
    }
  }

  /// Truly verify connection by actually querying the database (not just checking state)
  static Future<bool> verifyConnected() async {
    try {
      if (!_isDbOpen) {
        print('⚠️ verifyConnected: DB state not open');
        return false;
      }

      // Coba ping dengan query minimal ke collection users
      final result = await users.findOne(where.limit(1));
      print('✅ verifyConnected: DB connection is LIVE');
      return true;
    } catch (e) {
      print('❌ verifyConnected FAILED: $e');
      return false;
    }
  }

  static Future<void> ensureConnected() async {
    final hasConnection = await connectivityService.checkConnection();
    if (!hasConnection) {
      print('DEBUG: ensureConnected skipped - No Internet');
      return; 
    }

    if (!_isDbOpen) {
      print('🔄 MongoDB disconnected. Force reconnecting...');
      
      // Reset flag koneksi yang sedang berlangsung jika terjadi stall
      if (_isConnecting) {
        print('⚠️ Previous connection attempt is still in progress. Aborting it.');
        _isConnecting = false;
        await _forceCloseOldConnection();
      }
      
      // Tunggu jangan langsung connect, beri waktu cleanup
      await Future.delayed(const Duration(milliseconds: 200));
      
      await connect();

      // Tunggu lebih lama sampai benar-benar terbuka
      int retries = 0;
      while (!_isDbOpen && retries < 15) {
        await Future.delayed(const Duration(milliseconds: 500));
        retries++;
        if (retries % 5 == 0) {
          print('⏳ Waiting for DB connection... (${retries * 500}ms)');
        }
      }

      if (!_isDbOpen) {
        print('❌ Failed to reconnect after 15 retries (7.5s)');
      } else {
        print('✅ Reconnection successful!');
      }
    }

    if (_isDbOpen) {
      users = db.collection('users');
      userDetails = db.collection('user_details');
      cvs = db.collection('cvs');
    } else {
      print('⚠️ WARNING: MongoDB still not connected. Will use cache fallback.');
    }
  }

  static Future<void> tryReconnect() async {
    if (_isConnecting) return;
    try {
      await connect();
    } catch (e) {
      print('Reconnection attempt failed: $e');
    }
  }

  static DbCollection get _jobVacanciesCollection {
    if (!_isDbOpen) throw Exception('Database not connected');
    return db.collection('job_vacancies');
  }

  static DbCollection get _savedJobsCollection {
    if (!_isDbOpen) throw Exception('Database not connected');
    return db.collection('saved_jobs');
  }

  static DbCollection get _jobApplicationsCollection {
    if (!_isDbOpen) throw Exception('Database not connected');
    return db.collection('job_applications');
  }

  static DbCollection get _companiesCollection {
    if (!_isDbOpen) throw Exception('Database not connected');
    return db.collection('companies');
  }

  static Future<bool> updateUserPassword(String email, String passwordHash) async {
    try {
      await ensureConnected();
      final result = await users.update(
        where.eq('email', email),
        modify.set('password_hash', passwordHash).set('updated_at', DateTime.now()),
      );
      
      // Log untuk debug
      print('DEBUG: Update password result: $result');
      
      // Beberapa versi driver mongo_dart mengembalikan Map kosong atau result['ok'] == 1.0
      // Kita anggap sukses jika tidak ada error yang dilempar
      return true; 
    } catch (e) {
      print('Gagal update password: $e');
      return false;
    }
  }

  static DbCollection get _notificationsCollection {
    if (!_isDbOpen) throw Exception('Database not connected');
    return db.collection('notifications');
  }

  static Future<bool> createNotification({
    required dynamic receiverId,
    required String receiverRole,
    required dynamic senderId,
    required String senderRole,
    required dynamic applicationId,
    required dynamic jobId,
    required String title,
    required String message,
    required String type,
    Map<String, dynamic>? extraData,
  }) async {
    try {
      await ensureConnected();

      final rId = _tryParseObjectId(receiverId) ?? receiverId;
      final sId = _tryParseObjectId(senderId) ?? senderId;
      final aId = _tryParseObjectId(applicationId) ?? applicationId;
      final jId = _tryParseObjectId(jobId) ?? jobId;

      final notificationData = {
        'receiver_id': rId,
        'receiver_role': receiverRole,
        'sender_id': sId,
        'sender_role': senderRole,
        'application_id': aId,
        'job_id': jId,
        'title': title,
        'message': message,
        'type': type,
        'is_read': false,
        'created_at': DateTime.now().toUtc(),
        ...?extraData,
      };

      print('DEBUG: Inserting Notification: $notificationData');

      await _notificationsCollection.insertOne(notificationData);

      return true;
    } catch (e) {
      print('Gagal membuat notifikasi: $e');
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> getNotifications({
    required dynamic receiverId,
    required String receiverRole,
  }) async {
    try {
      await ensureConnected();

      final candidates = _idCandidates(receiverId);

      final notifications = await _notificationsCollection
          .find(
            where
                .oneFrom('receiver_id', candidates)
                .eq('receiver_role', receiverRole)
                .sortBy('created_at', descending: true),
          )
          .toList();

      return notifications.cast<Map<String, dynamic>>();
    } catch (e) {
      print('Gagal mengambil notifikasi: $e');
      return [];
    }
  }

  static Future<bool> markNotificationAsRead({
    required String notificationId,
  }) async {
    try {
      await ensureConnected();

      if (notificationId.isEmpty) return false;

      final candidates = _idCandidates(notificationId);
      final query = where.oneFrom('_id', candidates);

      await _notificationsCollection.updateOne(
        query,
        modify.set('is_read', true).set('read_at', DateTime.now().toUtc()),
      );

      return true;
    } catch (e) {
      print('Gagal menandai notifikasi dibaca: $e');
      return false;
    }
  }

  static Future<int> getUnreadNotificationCount({
    required dynamic receiverId,
    required String receiverRole,
  }) async {
    try {
      final hasConnection = await connectivityService.checkConnection();
      if (!hasConnection) {
        print('DEBUG: No internet for notifications count. Returning 0.');
        return 0;
      }

      await ensureConnected();

      if (MongoService.db.state != State.open) {
        print('⚠️ DB not ready for notification count. Returning 0.');
        return 0;
      }

      final candidates = _idCandidates(receiverId);

      final count = await _notificationsCollection.count(
        where
            .oneFrom('receiver_id', candidates)
            .eq('receiver_role', receiverRole)
            .eq('is_read', false),
      );

      return count;
    } catch (e) {
      print('❌ Gagal menghitung notifikasi belum dibaca: $e');
      return 0;
    }
  }

  static String getMongoId(dynamic value) {
    if (value == null) return '';
    if (value is ObjectId) return value.oid;
    
    final str = value.toString();
    
    // Handle string representation like 'ObjectId("...")'
    final hexRegExp = RegExp(r'[0-9a-fA-F]{24}');
    final match = hexRegExp.firstMatch(str);
    if (match != null) {
      return match.group(0)!; // Extract the hex string
    }
    
    // Return as-is if it's already a valid hex string
    return str;
  }

  static ObjectId? _tryParseObjectId(dynamic value) {
    if (value == null) return null;
    if (value is ObjectId) return value;

    final str = value.toString();
    final hexRegExp = RegExp(r'[0-9a-fA-F]{24}');
    final match = hexRegExp.firstMatch(str);
    if (match == null) return null;

    try {
      return ObjectId.fromHexString(match.group(0)!);
    } catch (_) {
      return null;
    }
  }

  static List<dynamic> _idCandidates(dynamic value) {
    final candidates = <dynamic>{};

    if (value == null) return [];

    if (value is ObjectId) {
      candidates.add(value);
    }

    final str = value.toString();

    if (str.isNotEmpty) {
      candidates.add(str);
    }

    final parsed = _tryParseObjectId(value);

    if (parsed != null) {
      candidates.add(parsed);
    }

    return candidates.toList();
  }

  /// Sanitize map untuk disimpan ke Hive/pending sync queue
  /// Mengkonversi ObjectId dan tipe non-Hive lainnya ke String
  static Map<String, dynamic> _sanitizeMapForSync(Map<String, dynamic> rawData) {
    final Map<String, dynamic> sanitized = {};
    rawData.forEach((key, value) {
      if (value is Map) {
        sanitized[key] = _sanitizeMapForSync(Map<String, dynamic>.from(value));
      } else if (value is List) {
        sanitized[key] = value.map((e) {
          if (e is Map) return _sanitizeMapForSync(Map<String, dynamic>.from(e));
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

  static Future<Map<String, dynamic>?> getUserById(dynamic userId) async {
    try {
      await ensureConnected();

      if (userId == null) return null;

      for (final candidate in _idCandidates(userId)) {
        final user = await users.findOne(where.id(candidate));
        if (user != null) return user;
      }

      return null;
    } catch (e) {
      print('Gagal mengambil user by id: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getUserDetailsByUserId(
    dynamic userId,
  ) async {
    try {
      await ensureConnected();

      if (userId == null) return null;

      for (final candidate in _idCandidates(userId)) {
        final details = await userDetails.findOne(
          where.eq('user_id', candidate),
        );

        if (details != null) return details;
      }

      return null;
    } catch (e) {
      print('Gagal mengambil user details: $e');
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>> enrichApplicantsWithUserDetails(
    List<Map<String, dynamic>> applicants,
  ) async {
    try {
      await ensureConnected();

      if (applicants.isEmpty) return [];

      final enrichedApplicants = <Map<String, dynamic>>[];

      for (final applicant in applicants) {
        final applicantMap = Map<String, dynamic>.from(applicant);
        final userId = applicantMap['user_id'];

        if (userId != null) {
          final details = await getUserDetailsByUserId(userId);

          if (details != null) {
            final profilePhoto = details['profile_photo'];
            final namaLengkap = details['nama_lengkap'];
            final jenisDisabilitas = details['jenis_disabilitas'];
            final skills = details['skills'];

            if (profilePhoto != null && profilePhoto.toString().isNotEmpty) {
              applicantMap['profile_photo'] = profilePhoto;
            }

            if (namaLengkap != null && namaLengkap.toString().isNotEmpty) {
              applicantMap['nama_lengkap'] = namaLengkap;
              applicantMap['full_name'] = namaLengkap;
            }

            if (jenisDisabilitas != null &&
                jenisDisabilitas.toString().isNotEmpty) {
              applicantMap['jenis_disabilitas'] = jenisDisabilitas;
            }

            if (skills != null) {
              applicantMap['skills'] = skills;
            }
          }
        }

        enrichedApplicants.add(applicantMap);
      }

      return enrichedApplicants;
    } catch (e) {
      print('Gagal enrich data pelamar dengan user details: $e');
      return applicants;
    }
  }

  static Future<Map<String, dynamic>?> getApplicationById(
    dynamic applicationId,
  ) async {
    try {
      await ensureConnected();
      if (applicationId == null) return null;

      for (final candidate in _idCandidates(applicationId)) {
        final app = await _jobApplicationsCollection.findOne(
          where.id(candidate),
        );
        if (app != null) return app;
      }
      return null;
    } catch (e) {
      print('Gagal mengambil lamaran: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getJobById(dynamic jobId) async {
    try {
      await ensureConnected();
      if (jobId == null) return null;

      for (final candidate in _idCandidates(jobId)) {
        final job = await _jobVacanciesCollection.findOne(where.id(candidate));
        if (job != null) return job;
      }
      return null;
    } catch (e) {
      print('Gagal mengambil lowongan: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getUserDetailsByEmail(
    String email,
  ) async {
    try {
      await ensureConnected();

      if (email.isEmpty) return null;

      return await userDetails.findOne(
        where.eq('email', email),
      );
    } catch (e) {
      print('Gagal mengambil user details by email: $e');
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>> getJobVacancies() async {
    return getPublishedJobs();
  }

  static Future<bool> saveJob({
    required String userId,
    required String jobId,
  }) async {
    try {
      await ensureConnected();

      if (userId.isEmpty || jobId.isEmpty) return false;

      final existing = await _savedJobsCollection.findOne({
        'user_id': userId,
        'job_id': jobId,
      });

      if (existing != null) return true;

      await _savedJobsCollection.insertOne({
        'user_id': userId,
        'job_id': jobId,
        'saved_at': DateTime.now().toUtc(),
      });

      return true;
    } catch (e) {
      print('Gagal menyimpan lowongan: $e');
      return false;
    }
  }

  static Future<bool> unsaveJob({
    required String userId,
    required String jobId,
  }) async {
    try {
      await ensureConnected();

      if (userId.isEmpty || jobId.isEmpty) return false;

      await _savedJobsCollection.deleteOne({
        'user_id': userId,
        'job_id': jobId,
      });

      return true;
    } catch (e) {
      print('Gagal menghapus lowongan tersimpan: $e');
      return false;
    }
  }

  static Future<bool> isJobSaved({
    required String userId,
    required String jobId,
  }) async {
    try {
      await ensureConnected();

      if (userId.isEmpty || jobId.isEmpty) return false;

      final savedJob = await _savedJobsCollection.findOne({
        'user_id': userId,
        'job_id': jobId,
      });

      return savedJob != null;
    } catch (e) {
      print('Gagal mengecek lowongan tersimpan: $e');
      return false;
    }
  }

  static Future<Set<String>> getSavedJobIds({
    required String userId,
  }) async {
    try {
      final hasConnection = await connectivityService.checkConnection();
      if (!hasConnection) {
        return <String>{};
      }

      await ensureConnected();

      if (userId.isEmpty) return <String>{};

      final savedJobs = await _savedJobsCollection
          .find(
            where.eq('user_id', userId),
          )
          .toList();

      return savedJobs
          .map((item) => item['job_id']?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toSet();
    } catch (e) {
      print('Gagal mengambil id lowongan tersimpan: $e');
      return <String>{};
    }
  }

  static Future<List<Map<String, dynamic>>> getSavedJobs({
    required String userId,
  }) async {
    try {
      await ensureConnected();

      if (userId.isEmpty) return [];

      final savedJobs = await _savedJobsCollection
          .find(
            where.eq('user_id', userId).sortBy(
                  'saved_at',
                  descending: true,
                ),
          )
          .toList();

      if (savedJobs.isEmpty) return [];

      final savedAtByJobId = <String, dynamic>{};
      final savedJobIds = <String>[];

      for (final savedJob in savedJobs) {
        final jobId = savedJob['job_id']?.toString() ?? '';

        if (jobId.isNotEmpty) {
          savedJobIds.add(jobId);
          savedAtByJobId[jobId] = savedJob['saved_at'];
        }
      }

      if (savedJobIds.isEmpty) return [];

      final activeJobs = await _jobVacanciesCollection
          .find(
            where.eq('status', 'active'),
          )
          .toList();

      final result = activeJobs
          .where((job) => savedJobIds.contains(getMongoId(job['_id'])))
          .map<Map<String, dynamic>>((job) {
        final jobMap = Map<String, dynamic>.from(job);
        final jobId = getMongoId(jobMap['_id']);

        jobMap['saved_at'] = savedAtByJobId[jobId];

        return jobMap;
      }).toList();

      result.sort((a, b) {
        final aIndex = savedJobIds.indexOf(getMongoId(a['_id']));
        final bIndex = savedJobIds.indexOf(getMongoId(b['_id']));

        return aIndex.compareTo(bIndex);
      });

      return result;
    } catch (e) {
      print('Gagal mengambil lowongan tersimpan: $e');
      return [];
    }
  }

  static Future<bool> hasAppliedJob({
    required dynamic userId,
    required dynamic jobId,
  }) async {
    try {
      final hasConnection = await connectivityService.checkConnection();
      if (!hasConnection) {
        print('📱 hasAppliedJob: Offline, returning false');
        return false;
      }

      // Cek dengan truly verify
      final isLive = await verifyConnected();
      if (!isLive) {
        print('⚠️ hasAppliedJob: DB not live, returning false');
        return false;
      }

      if (userId == null || jobId == null) return false;

      final userCandidates = _idCandidates(userId);
      final jobCandidates = _idCandidates(jobId);

      final existing = await _jobApplicationsCollection.findOne(
        where.oneFrom('user_id', userCandidates).oneFrom(
              'job_id',
              jobCandidates,
            ),
      );

      return existing != null;
    } catch (e) {
      print('Gagal mengecek lamaran: $e');
      return false;
    }
  }

  static Future<bool> submitJobApplication({
    required Map<String, dynamic> applicationData,
  }) async {
    try {
      // ✅ STEP 1: Cache application lokal SEGERA JADI UI LANGSUNG UPDATED
      final userId = applicationData['user_id'];
      if (userId != null) {
        final uidStr = (userId is ObjectId) ? userId.toHexString() : userId.toString();
        final cachedApps = OfflineService.getCachedApplications();
        // Masukkan data dengan timestamp agar terlihat baru
        final appToCache = Map<String, dynamic>.from(applicationData);
        appToCache['created_at'] = DateTime.now().toUtc();
        appToCache['_id'] = ObjectId(); // Generate temporary ID
        cachedApps.insert(0, appToCache);
        await OfflineService.cacheApplications(cachedApps);
        print('✅ Application cached locally immediately');
      }

      // ✅ STEP 2: Check koneksi internet
      final hasConnection = await connectivityService.checkConnection();
      if (!hasConnection) {
        print('📱 Offline: Application queued for sync');
        final dataToQueue = _sanitizeMapForSync(applicationData);
        await OfflineService.addToSyncQueue('apply_job', dataToQueue);
        return true; // UI sudah updated dari cache, safe return true
      }

      // ✅ STEP 3: Ensure connected (tapi dengan truly verify)
      await ensureConnected();
      
      // ✅ STEP 4: Truly verify koneksi sebelum proceed
      final isLive = await verifyConnected();
      if (!isLive) {
        print('⚠️ DB state.open tapi tidak bisa reach. Queueing for sync.');
        final dataToQueue = _sanitizeMapForSync(applicationData);
        await OfflineService.addToSyncQueue('apply_job', dataToQueue);
        return true; // Cache sudah ada, return true
      }

      final jobId = applicationData['job_id'];
      if (jobId == null) {
        print('DEBUG: jobId is null');
        return false;
      }

      final uId = _tryParseObjectId(userId) ?? userId;
      final jId = _tryParseObjectId(jobId) ?? jobId;

      final alreadyApplied = await hasAppliedJob(
        userId: uId,
        jobId: jId,
      );

      if (alreadyApplied) {
        print('DEBUG: User already applied to this job');
        return false;
      }

      final finalAppData = Map<String, dynamic>.from(applicationData);
      finalAppData['user_id'] = uId;
      finalAppData['job_id'] = jId;

      final result = await _jobApplicationsCollection.insertOne(finalAppData);
      final insertedId = result.id;

      print('✅ Application successfully sent to server with ID: $insertedId');

      try {
        final job = await getJobById(jId);

        if (job != null) {
          final companyId = job['company_id'];
          final companyCandidates = _idCandidates(companyId);

          final company = await _companiesCollection.findOne(
            where.oneFrom('_id', companyCandidates),
          );

          if (company != null && company['user_id'] != null) {
            final companyUserId = company['user_id'];
            final message =
                "${applicationData['full_name']} melamar posisi ${job['title']}.";

            await createNotification(
              receiverId: companyUserId,
              receiverRole: 'company',
              senderId: uId,
              senderRole: 'job_seeker',
              applicationId: insertedId,
              jobId: jId,
              title: 'Pelamar Baru',
              message: message,
              type: 'new_application',
            );
            print('✅ Notification to company created');
          }
        }
      } catch (ne) {
        print('⚠️ Error creating notification: $ne');
      }

      return true;
    } catch (e) {
      print('❌ submitJobApplication error: $e');
      // Cache sudah diupdate di step 1, jadi return true
      return true;
    }
  }

  static Future<List<Map<String, dynamic>>> getUserApplications({
    required dynamic userId,
  }) async {
    try {
      final hasConnection = await connectivityService.checkConnection();
      if (!hasConnection) {
        print('📱 Offline: getUserApplications using cache');
        return OfflineService.getCachedApplications();
      }

      await ensureConnected();

      // Truly verify koneksi
      final isLive = await verifyConnected();
      if (!isLive) {
        print('⚠️ DB not live. Using cache for applications.');
        return OfflineService.getCachedApplications();
      }

      if (userId == null) return [];

      final candidates = _idCandidates(userId);

      final applications = await _jobApplicationsCollection
          .find(
            where.oneFrom('user_id', candidates).sortBy(
                  'created_at',
                  descending: true,
                ),
          )
          .toList();

      // Update cache
      await OfflineService.cacheApplications(applications);

      // Secara otomatis melengkapi job_photo jika belum ada di data lamaran
      for (var app in applications) {
        if (app['job_photo'] == null && app['job_id'] != null) {
          final job = await getJobById(app['job_id']);
          if (job != null && job['job_photo'] != null) {
            app['job_photo'] = job['job_photo'];
          }
        }
      }

      final castedApps = applications.cast<Map<String, dynamic>>();
      OfflineService.cacheApplications(castedApps);

      return castedApps;
    } catch (e) {
      print('Gagal mengambil data lamaran: $e');
      return OfflineService.getCachedApplications();
    }
  }

  // ================= COMPANY DASHBOARD =================

  static Future<Map<String, dynamic>?> getCompanyByName(
    String companyName,
  ) async {
    try {
      final hasConnection = await connectivityService.checkConnection();
      if (!hasConnection) {
        print('📱 Company Profile (by name): Offline. Using cache.');
        try {
          final cachedCompanies = Hive.box('offline_company_profile').values;
          for (var cached in cachedCompanies) {
            if (cached is Map && cached['company_name'] == companyName) {
              return Map<String, dynamic>.from(cached);
            }
          }
        } catch (e) {
          print('Cache read error: $e');
        }
        return null;
      }

      await ensureConnected();

      // Truly verify koneksi
      final isLive = await verifyConnected();
      if (!isLive) {
        print('⚠️ Company Profile (by name): DB not live. Using cache.');
        try {
          final cachedCompanies = Hive.box('offline_company_profile').values;
          for (var cached in cachedCompanies) {
            if (cached is Map && cached['company_name'] == companyName) {
              return Map<String, dynamic>.from(cached);
            }
          }
        } catch (e) {
          print('Cache read error: $e');
        }
        return null;
      }

      if (companyName.isEmpty) return null;

      final company = await _companiesCollection.findOne(
        where.eq('company_name', companyName),
      );

      return company;
    } catch (e) {
      print('❌ Error getCompanyByName: $e');
      // Try cache fallback
      try {
        final cachedCompanies = Hive.box('offline_company_profile').values;
        for (var cached in cachedCompanies) {
          if (cached is Map && cached['company_name'] == companyName) {
            return Map<String, dynamic>.from(cached);
          }
        }
      } catch (cacheError) {
        print('Cache fallback error: $cacheError');
      }
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getCompanyByUserId(
    dynamic userId,
  ) async {
    try {
      final uIdStr = userId?.toString();
      final hasConnection = await connectivityService.checkConnection();
      if (!hasConnection && uIdStr != null) {
        print('📱 Company Profile: Offline. Using cache.');
        return OfflineService.getCachedCompanyProfile(uIdStr);
      }

      await ensureConnected();

      // Truly verify koneksi
      final isLive = await verifyConnected();
      if (!isLive && uIdStr != null) {
        print('⚠️ Company Profile: DB not live. Using cache.');
        return OfflineService.getCachedCompanyProfile(uIdStr);
      }

      if (userId == null) return null;

      for (final candidate in _idCandidates(userId)) {
        final company = await _companiesCollection.findOne(
          where.eq('user_id', candidate),
        );

        if (company != null) {
          if (uIdStr != null) {
            OfflineService.cacheCompanyProfile(uIdStr, company);
          }
          return company;
        }
      }

      // Kalau DB tidak ada tapi cache ada, gunakan cache
      if (uIdStr != null) {
        final cachedCompany = OfflineService.getCachedCompanyProfile(uIdStr);
        if (cachedCompany != null) {
          print('💾 Company Profile: Using cached profile (DB has none)');
          return cachedCompany;
        }
      }

      return null;
    } catch (e) {
      print('❌ Error getCompanyByUserId: $e');
      if (userId != null) {
        return OfflineService.getCachedCompanyProfile(userId.toString());
      }
      return null;
    }
  }

  static Future<bool> createCompany({
    required dynamic userId,
    required String companyName,
    required String email,
    required String phone,
  }) async {
    try {
      await ensureConnected();

      if (userId == null || companyName.isEmpty) return false;

      await _companiesCollection.insertOne({
        'user_id': userId,
        'company_name': companyName,
        'email': email,
        'phone': phone,
        'description': '',
        'address': '',
        'field': 'Perusahaan',
        'created_at': DateTime.now().toUtc(),
        'updated_at': DateTime.now().toUtc(),
      });

      return true;
    } catch (e) {
      print('Gagal membuat company record: $e');
      return false;
    }
  }

  static Future<bool> updateCompanyProfile({
    required String companyId,
    required Map<String, dynamic> data,
  }) async {
    try {
      final hasConnection = await connectivityService.checkConnection();
      if (!hasConnection) {
        print('📱 Company Profile Update: Offline. Queueing sync.');
        // Update local cache
        if (data['user_id'] != null) {
          await OfflineService.cacheCompanyProfile(data['user_id'].toString(), data);
        }
        // Sanitized data ada di addToSyncQueue sekarang, tapi tetap queue yang clean
        final dataToQueue = _sanitizeMapForSync(data);
        await OfflineService.addToSyncQueue('update_company_profile', {
          'companyId': companyId,
          'data': dataToQueue,
        });
        return true;
      }

      await ensureConnected();

      // Verify koneksi sebelum operasi DB
      final isLive = await verifyConnected();
      if (!isLive) {
        print('⚠️ Company Profile Update: DB not live. Queueing sync.');
        if (data['user_id'] != null) {
          await OfflineService.cacheCompanyProfile(data['user_id'].toString(), data);
        }
        final dataToQueue = _sanitizeMapForSync(data);
        await OfflineService.addToSyncQueue('update_company_profile', {
          'companyId': companyId,
          'data': dataToQueue,
        });
        return true;
      }

      if (companyId.isEmpty) return false;

      await _companiesCollection.updateOne(
        where.id(ObjectId.fromHexString(companyId)),
        modify
            .set('company_name', data['company_name'])
            .set('description', data['description'])
            .set('address', data['address'])
            .set('email', data['email'])
            .set('phone', data['phone'])
            .set('field', data['field'] ?? '')
            .set('profile_photo', data['profile_photo'])
            .set('updated_at', DateTime.now().toUtc()),
      );

      // Update cache
      if (data['user_id'] != null) {
        await OfflineService.cacheCompanyProfile(data['user_id'].toString(), data);
      }

      return true;
    } catch (e) {
      print('❌ Error updateCompanyProfile: $e');
      // Fallback: cache dan queue untuk sync nanti
      try {
        if (data['user_id'] != null) {
          await OfflineService.cacheCompanyProfile(data['user_id'].toString(), data);
          final dataToQueue = _sanitizeMapForSync(data);
          await OfflineService.addToSyncQueue('update_company_profile', {
            'companyId': companyId,
            'data': dataToQueue,
          });
          return true;
        }
        return false;
      } catch (fallbackError) {
        print('Fallback error: $fallbackError');
        return false;
      }
    }
  }

  static Future<List<Map<String, dynamic>>> getCompanyJobs({
    required dynamic companyId,
  }) async {
    try {
      final cIdStr = companyId?.toString();
      final hasConnection = await connectivityService.checkConnection();
      if (!hasConnection && cIdStr != null) {
        print('📱 Company Jobs: Offline. Using cache.');
        return OfflineService.getCachedCompanyJobs(cIdStr);
      }

      await ensureConnected();

      // Truly verify koneksi
      final isLive = await verifyConnected();
      if (!isLive && cIdStr != null) {
        print('⚠️ Company Jobs: DB not live. Using cache.');
        return OfflineService.getCachedCompanyJobs(cIdStr);
      }

      if (companyId == null) return [];

      final candidates = _idCandidates(companyId);

      final jobs = await _jobVacanciesCollection
          .find(
            where
                .oneFrom('company_id', candidates)
                .sortBy('created_at', descending: true),
          )
          .toList();

      final castedJobs = jobs.cast<Map<String, dynamic>>();
      if (cIdStr != null) {
        OfflineService.cacheCompanyJobs(cIdStr, castedJobs);
      }

      return castedJobs;
    } catch (e) {
      print('❌ Error getCompanyJobs: $e');
      if (companyId != null) {
        return OfflineService.getCachedCompanyJobs(companyId.toString());
      }
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getCompanyApplicants({
    required dynamic companyId,
  }) async {
    try {
      final cIdStr = companyId?.toString();
      final hasConnection = await connectivityService.checkConnection();
      if (!hasConnection && cIdStr != null) {
        print('📱 Company Applicants: Offline. Using cache.');
        return OfflineService.getCachedCompanyApplicants(cIdStr);
      }

      await ensureConnected();

      // Truly verify koneksi
      final isLive = await verifyConnected();
      if (!isLive && cIdStr != null) {
        print('⚠️ Company Applicants: DB not live. Using cache.');
        return OfflineService.getCachedCompanyApplicants(cIdStr);
      }

      if (companyId == null) return [];

      final jobs = await getCompanyJobs(companyId: companyId);

      final allJobCandidates = [];
      for (var job in jobs) {
        allJobCandidates.addAll(_idCandidates(job['_id']));
      }

      if (allJobCandidates.isEmpty) return [];

      final applicants = await _jobApplicationsCollection
          .find(
            where
                .oneFrom('job_id', allJobCandidates)
                .sortBy('created_at', descending: true),
          )
          .toList();

      final castedApplicants = applicants.cast<Map<String, dynamic>>();
      
      // Cache hasil
      if (cIdStr != null) {
        OfflineService.cacheCompanyApplicants(cIdStr, castedApplicants);
      }

      return castedApplicants;
    } catch (e) {
      print('❌ Error getCompanyApplicants: $e');
      if (companyId != null) {
        return OfflineService.getCachedCompanyApplicants(companyId.toString());
      }
      return [];
    }
  }

  static Future<bool> updateCompanyJob({
    required String jobId,
    required Map<String, dynamic> data,
  }) async {
    try {
      await ensureConnected();

      if (jobId.isEmpty) return false;

      await _jobVacanciesCollection.updateOne(
        where.id(ObjectId.fromHexString(jobId)),
        modify
            .set('title', data['title'])
            .set('location', data['location'])
            .set('job_type', data['job_type'])
            .set('description', data['description'])
            .set('qualification', data['qualification'])
            .set('facilities', data['facilities'])
            .set('is_disability_friendly', data['is_disability_friendly'])
            .set('job_photo', data['job_photo'])
            .set('updated_at', DateTime.now().toUtc()),
      );

      return true;
    } catch (e) {
      print('Gagal update lowongan: $e');
      return false;
    }
  }

  static Future<bool> updateJobStatus({
    required String jobId,
    required String status,
  }) async {
    try {
      await ensureConnected();

      if (jobId.isEmpty) return false;

      await _jobVacanciesCollection.updateOne(
        where.id(ObjectId.fromHexString(jobId)),
        modify.set('status', status).set(
              'updated_at',
              DateTime.now().toUtc(),
            ),
      );

      return true;
    } catch (e) {
      print('Gagal update status lowongan: $e');
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> getApplicantsByJob({
    required dynamic jobId,
  }) async {
    try {
      await ensureConnected();

      if (jobId == null) return [];

      final candidates = _idCandidates(jobId);

      final applicants = await _jobApplicationsCollection
          .find(
            where.oneFrom('job_id', candidates).sortBy(
                  'created_at',
                  descending: true,
                ),
          )
          .toList();

      return applicants.cast<Map<String, dynamic>>();
    } catch (e) {
      print('Gagal mengambil pelamar berdasarkan lowongan: $e');
      return [];
    }
  }

  static Future<bool> updateApplicationStatus({
    required dynamic applicationId,
    required String status,
    Map<String, dynamic>? extraData,
  }) async {
    try {
      await ensureConnected();

      if (applicationId == null) return false;

      final now = DateTime.now().toUtc();

      final updateData = <String, dynamic>{
        'status': status,
        'updated_at': now,
        ...?extraData,
      };

      if (status == 'ditinjau') {
        updateData['reviewed_at'] = now;
        updateData['processed_at'] = now;
      }

      if (status == 'wawancara') {
        updateData['interview_status_updated_at'] = now;
      }

      if (status == 'diterima') {
        updateData['accepted_at'] = now;
        updateData['accepted_status_updated_at'] = now;
      }

      if (status == 'ditolak') {
        updateData['rejected_at'] = now;
        updateData['rejected_status_updated_at'] = now;
      }

      final candidates = _idCandidates(applicationId);
      final query = where.oneFrom('_id', candidates);

      await _jobApplicationsCollection.updateOne(
        query,
        {
          r'$set': updateData,
        },
      );

      try {
        final application = await _jobApplicationsCollection.findOne(query);

        if (application != null) {
          final jobSeekerId = application['user_id'];
          final jobId = application['job_id'];

          Map<String, dynamic>? job;
          for (final candidate in _idCandidates(jobId)) {
            job = await _jobVacanciesCollection.findOne(where.id(candidate));
            if (job != null) break;
          }

          if (job != null) {
            final companyId = job['company_id'];

            Map<String, dynamic>? company;
            for (final candidate in _idCandidates(companyId)) {
              company = await _companiesCollection.findOne(
                where.id(candidate),
              );
              if (company != null) break;
            }

            final companyUserId = company?['user_id'];
            final companyName =
                company?['company_name'] ??
                company?['name'] ??
                job['company_name'] ??
                'perusahaan';

            String title = "";
            String message = "";
            String type = "";

            final s = status.toLowerCase();

            if (s == 'ditinjau' || s == 'diproses') {
              title = "Lamaran Ditinjau";
              message =
                  "Lamaran kamu untuk posisi ${job['title']} sedang ditinjau oleh $companyName.";
              type = "application_reviewed";
            } else if (s == 'wawancara') {
              title = "Jadwal Wawancara";

              final displayDate =
                  extraData?['interview_display'] ??
                  extraData?['interview_date'] ??
                  '-';

              message =
                  "Kamu masuk tahap wawancara untuk ${job['title']}. Jadwal: $displayDate.";
              type = "interview_schedule";
            } else if (s == 'diterima' ||
                s == 'accepted' ||
                s == 'lolos') {
              title = "Lamaran Diterima";
              message =
                  extraData?['accepted_message'] ??
                  "Selamat! Kamu diterima di $companyName untuk posisi ${job['title']}.";
              type = "application_accepted";
            } else if (s == 'ditolak' || s == 'rejected') {
              title = "Lamaran Ditolak";
              message =
                  "Terima kasih telah melamar. Saat ini lamaran kamu untuk ${job['title']} belum dapat kami lanjutkan.";
              type = "application_rejected";
            }

            if (type.isNotEmpty) {
              await createNotification(
                receiverId: jobSeekerId,
                receiverRole: 'job_seeker',
                senderId: companyUserId,
                senderRole: 'company',
                applicationId: application['_id'],
                jobId: jobId,
                title: title,
                message: message,
                type: type,
                extraData: {
                  'status_snapshot': status,
                  'job_title_snapshot': job['title'],
                  'company_name_snapshot': companyName,

                  if (extraData?['interview_date'] != null)
                    'interview_date': extraData?['interview_date'],
                  if (extraData?['interview_display'] != null)
                    'interview_display': extraData?['interview_display'],
                  if (extraData?['interview_note'] != null)
                    'interview_note': extraData?['interview_note'],

                  if (extraData?['accepted_message'] != null)
                    'accepted_message': extraData?['accepted_message'],
                  if (extraData?['start_work_date'] != null)
                    'start_work_date': extraData?['start_work_date'],
                  if (extraData?['work_info'] != null)
                    'work_info': extraData?['work_info'],

                  if (extraData?['rejection_reason'] != null)
                    'rejection_reason': extraData?['rejection_reason'],
                },
              );
            }
          }
        }
      } catch (e) {
        print('Gagal membuat notifikasi update status: $e');
      }

      return true;
    } catch (e) {
      print('Gagal update status pelamar: $e');
      return false;
    }
  }

  static Future<bool> insertJobVacancy({
    required Map<String, dynamic> data,
  }) async {
    try {
      await ensureConnected();

      final companyId = data['company_id']?.toString() ?? '';

      final jobData = Map<String, dynamic>.from(data);

      if (companyId.isNotEmpty) {
        try {
          jobData['company_id'] = ObjectId.fromHexString(companyId);
        } catch (_) {
          jobData['company_id'] = companyId;
        }
      }

      await _jobVacanciesCollection.insertOne(jobData);

      return true;
    } catch (e) {
      print('Gagal menambahkan lowongan: $e');
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> getPublishedJobs() async {
    try {
      // Periksa koneksi internet sebelum mencoba ke MongoDB
      final hasConnection = await connectivityService.checkConnection();
      if (!hasConnection) {
        print('DEBUG: Offline mode detected, fetching from Hive cache');
        return OfflineService.getCachedJobs();
      }

      await ensureConnected();

      // Proteksi tambahan: jika DB masih tidak siap, gunakan cache
      if (MongoService.db.state != State.open) {
        print('⚠️ DB not ready after ensureConnected. Using cache for jobs.');
        return OfflineService.getCachedJobs();
      }

      final jobs = await _jobVacanciesCollection
          .find(
            where.eq('status', 'active').sortBy(
                  'created_at',
                  descending: true,
                ),
          )
          .toList();

      final castedJobs = jobs.cast<Map<String, dynamic>>();
      
      // Update cache Hive di background
      OfflineService.cacheJobs(castedJobs);

      return castedJobs;
    } catch (e) {
      print('❌ Gagal mengambil lowongan terpublikasi: $e');
      // Jika gagal konek ke Mongo tapi ada internet, coba ambil dari cache sebagai fallback
      return OfflineService.getCachedJobs();
    }
  }
}