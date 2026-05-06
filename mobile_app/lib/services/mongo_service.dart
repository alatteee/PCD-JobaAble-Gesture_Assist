import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mongo_dart/mongo_dart.dart';

class MongoService {
  static late Db db;
  static late DbCollection users;
  static late DbCollection userDetails;
  static late DbCollection cvs;

  static bool _isConnecting = false;

  static Future<void> connect() async {
    final uri = dotenv.env['MONGODB_URI'];

    if (uri == null || uri.isEmpty) {
      throw Exception('MONGODB_URI tidak ditemukan');
    }

    if (_isDbOpen) return;
    if (_isConnecting) return; // Prevent multiple simultaneous connection attempts

    _isConnecting = true;
    try {
      // Tambahkan parameter untuk stabilitas Atlas
      String finalUri = uri;
      if (!finalUri.contains('tls=')) {
        final separator = finalUri.contains('?') ? '&' : '?';
        finalUri += '${separator}tls=true&safeAtlas=true&keepAlive=true&connectTimeoutMS=10000&socketTimeoutMS=45000&maxIdleTimeMS=10000';
      }

      print('🔄 Connecting to MongoDB Atlas...');
      db = await Db.create(finalUri);
      await db.open();

      // Ensure all shared collection references are fresh
      users = db.collection('users');
      userDetails = db.collection('user_details');
      cvs = db.collection('cvs');

      print('✅ MongoDB Connected');
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

  static Future<void> ensureConnected() async {
    if (!_isDbOpen) {
      print('🔄 Membuka kembali koneksi MongoDB yang terputus...');
      await connect();
      
      // Wait a bit if we just started connecting
      int retries = 0;
      while (!_isDbOpen && retries < 5) {
        await Future.delayed(const Duration(milliseconds: 500));
        retries++;
      }
    }
    
    // Always sync critical collections after ensuring connection
    if (_isDbOpen) {
      users = db.collection('users');
      userDetails = db.collection('user_details');
      cvs = db.collection('cvs');
    } else {
      throw Exception('MongoDart Error: No master connection (Reconnection failed)');
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
  }) async {
    try {
      await ensureConnected();

      // Ensure IDs are processed to stay consistent with Atlas storage patterns
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

      // Use candidates for notification ID just in case
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
      await ensureConnected();

      final candidates = _idCandidates(receiverId);

      final count = await _notificationsCollection.count(
        where
            .oneFrom('receiver_id', candidates)
            .eq('receiver_role', receiverRole)
            .eq('is_read', false),
      );

      return count;
    } catch (e) {
      print('Gagal menghitung notifikasi belum dibaca: $e');
      return 0;
    }
  }

  static String getMongoId(dynamic value) {
    if (value == null) return '';
    if (value is ObjectId) return value.oid;
    return value.toString();
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

  static Future<Map<String, dynamic>?> getApplicationById(dynamic applicationId) async {
    try {
      await ensureConnected();
      if (applicationId == null) return null;

      for (final candidate in _idCandidates(applicationId)) {
        final app = await _jobApplicationsCollection.findOne(where.id(candidate));
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
      await ensureConnected();

      if (userId == null || jobId == null) return false;

      final userCandidates = _idCandidates(userId);
      final jobCandidates = _idCandidates(jobId);

      final existing = await _jobApplicationsCollection.findOne(
        where.oneFrom('user_id', userCandidates).oneFrom('job_id', jobCandidates),
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
      await ensureConnected();

      final userId = applicationData['user_id'];
      final jobId = applicationData['job_id'];

      if (userId == null || jobId == null) {
        print('DEBUG: userId or jobId is null');
        return false;
      }

      // Convert critical IDs to handle potential type mismatches in queries
      final uId = _tryParseObjectId(userId) ?? userId;
      final jId = _tryParseObjectId(jobId) ?? jobId;

      // 1. Check if already applied using flexible ID candidates
      final alreadyApplied = await hasAppliedJob(
        userId: uId,
        jobId: jId,
      );

      if (alreadyApplied) {
        print('DEBUG: User already applied to this job');
        return false;
      }

      // 2. Prepare data for insertion (ensure consistent ObjectId format for searching later)
      final finalAppData = Map<String, dynamic>.from(applicationData);
      finalAppData['user_id'] = uId;
      finalAppData['job_id'] = jId;

      final result = await _jobApplicationsCollection.insertOne(finalAppData);
      final insertedId = result.id;

      print('DEBUG: Application inserted with ID: $insertedId');

      // 3. Create Notification for Company
      try {
        // Find the job to get the company_id
        final job = await getJobById(jId);
        
        if (job != null) {
          final companyId = job['company_id'];
          final companyCandidates = _idCandidates(companyId);
          
          final company = await _companiesCollection.findOne(
            where.oneFrom('_id', companyCandidates)
          );
          
          if (company != null && company['user_id'] != null) {
            final companyUserId = company['user_id'];
            final message = "${applicationData['full_name']} melamar posisi ${job['title']}.";
            
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
            print('DEBUG: Notification to company created');
          } else {
            print('DEBUG: Company or Company User ID not found');
          }
        } else {
          print('DEBUG: Job not found for ID: $jId');
        }
      } catch (ne) {
        print('DEBUG Error creating notification: $ne');
      }

      return true;
    } catch (e) {
      print('Gagal mengirim lamaran: $e');
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> getUserApplications({
    required dynamic userId,
  }) async {
    try {
      await ensureConnected();

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

      return applications.cast<Map<String, dynamic>>();
    } catch (e) {
      print('Gagal mengambil data lamaran: $e');
      return [];
    }
  }

  // ================= COMPANY DASHBOARD =================

  static Future<Map<String, dynamic>?> getCompanyByName(
    String companyName,
  ) async {
    try {
      await ensureConnected();

      if (companyName.isEmpty) return null;

      final company = await _companiesCollection.findOne(
        where.eq('company_name', companyName),
      );

      return company;
    } catch (e) {
      print('Gagal mengambil data company: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getCompanyByUserId(
    dynamic userId,
  ) async {
    try {
      await ensureConnected();

      if (userId == null) return null;

      for (final candidate in _idCandidates(userId)) {
        final company = await _companiesCollection.findOne(
          where.eq('user_id', candidate),
        );

        if (company != null) return company;
      }

      return null;
    } catch (e) {
      print('Gagal mengambil data company by user id: $e');
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
      await ensureConnected();

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
            .set('updated_at', DateTime.now().toUtc()),
      );

      return true;
    } catch (e) {
      print('Gagal update profil company: $e');
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> getCompanyJobs({
    required dynamic companyId,
  }) async {
    try {
      await ensureConnected();

      if (companyId == null) return [];

      final candidates = _idCandidates(companyId);

      final jobs = await _jobVacanciesCollection
          .find(
            where
                .oneFrom('company_id', candidates)
                .sortBy('created_at', descending: true),
          )
          .toList();

      return jobs.cast<Map<String, dynamic>>();
    } catch (e) {
      print('Gagal mengambil lowongan company: $e');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getCompanyApplicants({
    required dynamic companyId,
  }) async {
    try {
      await ensureConnected();

      if (companyId == null) return [];

      final jobs = await getCompanyJobs(companyId: companyId);

      // Collect all possible ID formats for these jobs
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

      return applicants.cast<Map<String, dynamic>>();
    } catch (e) {
      print('Gagal mengambil pelamar company: $e');
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

      // Create Notification for Job Seeker
      try {
        final application = await _jobApplicationsCollection.findOne(query);
        if (application != null) {
          final jobSeekerId = application['user_id'];
          final jobId = application['job_id'];

          // Handle Job lookup
          Map<String, dynamic>? job;
          for (final candidate in _idCandidates(jobId)) {
            job = await _jobVacanciesCollection.findOne(where.id(candidate));
            if (job != null) break;
          }
          
          if (job != null) {
            final companyId = job['company_id'];
            
            // Handle Company lookup
            Map<String, dynamic>? company;
            for (final candidate in _idCandidates(companyId)) {
              company = await _companiesCollection.findOne(where.id(candidate));
              if (company != null) break;
            }
            
            final companyUserId = company?['user_id'];

            String title = "";
            String message = "";
            String type = "";

            final s = status.toLowerCase();
            if (s == 'ditinjau' || s == 'diproses') {
              title = "Lamaran Ditinjau";
              message = "Lamaran kamu untuk posisi ${job['title']} sedang ditinjau oleh ${company?['name'] ?? 'perusahaan'}.";
              type = "application_reviewed";
            } else if (s == 'wawancara') {
              title = "Jadwal Wawancara";
              final displayDate = extraData?['interview_display'] ?? extraData?['interview_date'] ?? '-';
              message = "Kamu masuk tahap wawancara untuk ${job['title']}. Jadwal: $displayDate.";
              type = "interview_schedule";
            } else if (s == 'diterima' || s == 'accepted' || s == 'lolos') {
              title = "Lamaran Diterima";
              message = extraData?['accepted_message'] ?? "Selamat! Kamu diterima di ${company?['name'] ?? 'perusahaan'} untuk posisi ${job['title']}.";
              type = "application_accepted";
            } else if (s == 'ditolak' || s == 'rejected') {
              title = "Lamaran Ditolak";
              message = "Terima kasih telah melamar. Saat ini lamaran kamu untuk ${job['title']} belum dapat kami lanjutkan.";
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
      await ensureConnected();

      final jobs = await _jobVacanciesCollection
          .find(
            where.eq('status', 'active').sortBy(
                  'created_at',
                  descending: true,
                ),
          )
          .toList();

      return jobs.cast<Map<String, dynamic>>();
    } catch (e) {
      print('Gagal mengambil lowongan terpublikasi: $e');
      return [];
    }
  }
}