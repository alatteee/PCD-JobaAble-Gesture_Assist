import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

import '../../services/mongo_service.dart';
import '../cv/cv_controller.dart';
import '../cv/cv_detail_view.dart';

class CompanyApplicantDetailPage extends StatefulWidget {
  final Map<String, dynamic> applicant;
  final Map<String, dynamic> job;

  const CompanyApplicantDetailPage({
    super.key,
    required this.applicant,
    required this.job,
  });

  @override
  State<CompanyApplicantDetailPage> createState() =>
      _CompanyApplicantDetailPageState();
}

class _CompanyApplicantDetailPageState
    extends State<CompanyApplicantDetailPage> {
  Map<String, dynamic>? user;
  Map<String, dynamic>? userDetails;
  bool isLoading = true;

  static const Color navy = Color(0xFF0D1B55);
  static const Color textGrey = Color(0xFF4A5870);
  static const Color lightBlue = Color(0xFFEAF0FF);
  static const Color chipBlue = Color(0xFF91B4FF);

  static const Color greenBg = Color(0xFFD4F0DD);
  static const Color greenText = Color(0xFF18A64A);
  static const Color orangeBg = Color(0xFFFFE4B8);
  static const Color orangeText = Color(0xFFF59E0B);
  static const Color redBg = Color(0xFFF8D1D3);
  static const Color redText = Color(0xFFE2262C);
  static const Color greyBg = Color(0xFFE5E5E5);
  static const Color greyText = Color(0xFF5B6472);

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final userId = widget.applicant['user_id']?.toString() ?? '';

    if (userId.isEmpty) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
      return;
    }

    try {
      final results = await Future.wait([
        MongoService.getUserById(widget.applicant['user_id']),
        MongoService.getUserDetailsByUserId(widget.applicant['user_id']),
      ]);

      if (!mounted) return;

      final loadedUser = results[0] as Map<String, dynamic>?;
      var loadedUserDetails = results[1] as Map<String, dynamic>?;

      if (loadedUserDetails == null) {
        final applicantEmail = widget.applicant['email']?.toString() ?? '';

        if (applicantEmail.isNotEmpty) {
          loadedUserDetails = await MongoService.getUserDetailsByEmail(
            applicantEmail,
          );
        }
      }

      if (!mounted) return;

      setState(() {
        user = loadedUser;
        userDetails = loadedUserDetails;
        isLoading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  String _stringValue(dynamic value) => value?.toString() ?? '';

  String _cleanBase64Image(String value) {
    var cleaned = value.trim();

    if (cleaned.contains(',')) {
      cleaned = cleaned.split(',').last;
    }

    cleaned = cleaned.replaceAll(RegExp(r'\s+'), '');

    return cleaned;
  }

  bool _isLikelyLocalFilePath(String value) {
    return value.startsWith('/data/') ||
        value.startsWith('/storage/') ||
        value.startsWith('/sdcard/');
  }

  String _getInitials(String name) {
    final cleanName = name.trim();

    if (cleanName.isEmpty) return '?';

    final parts = cleanName.split(' ');

    if (parts.length == 1) return parts.first[0].toUpperCase();

    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  String _formatDate(dynamic value) {
    if (value == null) return '-';

    DateTime? date;

    if (value is DateTime) {
      date = value;
    } else {
      date = DateTime.tryParse(value.toString());
    }

    if (date == null) return '-';

    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatDateShort(dynamic value) {
    if (value == null) return '-';

    DateTime? date;

    if (value is DateTime) {
      date = value;
    } else {
      date = DateTime.tryParse(value.toString());
    }

    if (date == null) {
      final text = value.toString().trim();
      return text.isEmpty ? '-' : text;
    }

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _normalizeStatus(String status) {
    final value = status.toLowerCase();

    if (value == 'pending' || value == 'dikirim') return 'dikirim';

    if (value == 'reviewed' ||
        value == 'diproses' ||
        value == 'ditinjau') {
      return 'ditinjau';
    }

    if (value == 'interview' || value == 'wawancara') return 'wawancara';

    if (value == 'accepted' ||
        value == 'diterima' ||
        value == 'lolos' ||
        value == 'lolos berkas') {
      return 'diterima';
    }

    if (value == 'rejected' || value == 'ditolak') return 'ditolak';

    return 'dikirim';
  }

  String _statusLabel(String status) {
    switch (_normalizeStatus(status)) {
      case 'dikirim':
        return 'Dikirim';
      case 'ditinjau':
        return 'Ditinjau';
      case 'wawancara':
        return 'Wawancara';
      case 'diterima':
        return 'Diterima';
      case 'ditolak':
        return 'Ditolak';
      default:
        return 'Dikirim';
    }
  }

  List<String> _toStringList(dynamic value) {
    if (value == null) return [];

    if (value is List) {
      return value.map((item) => item.toString()).toList();
    }

    if (value is String && value.trim().isNotEmpty) {
      return [value];
    }

    return [];
  }

  int _statusIndex(String normalizedStatus) {
    switch (normalizedStatus) {
      case 'dikirim':
        return 0;
      case 'ditinjau':
        return 1;
      case 'wawancara':
        return 2;
      case 'diterima':
      case 'ditolak':
        return 3;
      default:
        return 0;
    }
  }

  Future<void> _updateApplicantStatus({
    required BuildContext context,
    required String status,
    Map<String, dynamic>? extraData,
  }) async {
    final applicationId = MongoService.getMongoId(widget.applicant['_id']);

    final success = await MongoService.updateApplicationStatus(
      applicationId: applicationId,
      status: status,
      extraData: extraData,
    );

    if (!context.mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Status pelamar berhasil diubah menjadi ${_statusLabel(status)}',
          ),
        ),
      );

      Navigator.pop(context, status);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal memperbarui status pelamar'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(
            color: navy,
          ),
        ),
      );
    }

    final name = _stringValue(userDetails?['nama_lengkap']).isNotEmpty
        ? _stringValue(userDetails?['nama_lengkap'])
        : _stringValue(widget.applicant['full_name']).isNotEmpty
            ? _stringValue(widget.applicant['full_name'])
            : _stringValue(user?['username']).isNotEmpty
                ? _stringValue(user?['username'])
                : 'Pelamar';

    final email = _stringValue(user?['email']).isNotEmpty
        ? _stringValue(user?['email'])
        : _stringValue(widget.applicant['email']);

    final phone = _stringValue(userDetails?['phone']).isNotEmpty
        ? _stringValue(userDetails?['phone'])
        : _stringValue(user?['phone']).isNotEmpty
            ? _stringValue(user?['phone'])
            : _stringValue(widget.applicant['phone']);

    final location = _stringValue(widget.applicant['location']).isNotEmpty
        ? _stringValue(widget.applicant['location'])
        : _stringValue(widget.job['location']).isNotEmpty
            ? _stringValue(widget.job['location'])
            : '-';

    final status = _stringValue(widget.applicant['status']).isNotEmpty
        ? _stringValue(widget.applicant['status'])
        : 'dikirim';

    final jobTitle = _stringValue(widget.applicant['job_title']).isNotEmpty
        ? _stringValue(widget.applicant['job_title'])
        : _stringValue(widget.job['title']).isNotEmpty
            ? _stringValue(widget.job['title'])
            : '-';

    final birthDateValue = userDetails?['tanggal_lahir'] ??
        userDetails?['birth_date'] ??
        widget.applicant['birth_date'] ??
        widget.applicant['tanggal_lahir'];

    final birthDate =
        birthDateValue != null && _stringValue(birthDateValue).isNotEmpty
            ? _formatDateShort(birthDateValue)
            : '-';

    final gender = _stringValue(userDetails?['jenis_kelamin']).isNotEmpty
        ? _stringValue(userDetails?['jenis_kelamin'])
        : _stringValue(widget.applicant['gender']).isNotEmpty
            ? _stringValue(widget.applicant['gender'])
            : _stringValue(widget.applicant['jenis_kelamin']);

    final disability =
        _stringValue(userDetails?['jenis_disabilitas']).isNotEmpty
            ? _stringValue(userDetails?['jenis_disabilitas'])
            : _stringValue(userDetails?['disabilitas']).isNotEmpty
                ? _stringValue(userDetails?['disabilitas'])
                : _stringValue(widget.applicant['disability']).isNotEmpty
                    ? _stringValue(widget.applicant['disability'])
                    : _stringValue(widget.applicant['disabilitas']);

    final skills = _toStringList(userDetails?['skills']).isNotEmpty
        ? _toStringList(userDetails?['skills'])
        : _toStringList(widget.applicant['skills']);

    final createdAt = widget.applicant['created_at'];
    final sentDate = _formatDateShort(createdAt);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 28),
          children: [
            _buildHeader(context),
            const SizedBox(height: 24),
            _buildProfileCard(
              name: name,
              email: email,
              phone: phone,
              location: location,
              jobTitle: jobTitle,
              status: status,
              createdAt: createdAt,
            ),
            const SizedBox(height: 18),
            _buildStatusTimelineCard(
              status: status,
              sentDate: sentDate,
            ),
            const SizedBox(height: 18),
            _buildAboutCard(
              name: name,
              birthDate: birthDate,
              gender: gender,
              disability: disability,
            ),
            const SizedBox(height: 18),
            _buildSkillsCard(skills),
            const SizedBox(height: 18),
            _buildCvDigitalCard(),
            const SizedBox(height: 24),
            _buildActionButtons(status),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(
            Icons.arrow_back,
            size: 34,
            color: navy,
          ),
        ),
        const SizedBox(width: 18),
        const Expanded(
          child: Text(
            'Detail Pelamar',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: navy,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileCard({
    required String name,
    required String email,
    required String phone,
    required String location,
    required String jobTitle,
    required String status,
    required dynamic createdAt,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: _cardDecoration(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProfileAvatar(name),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: navy,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _statusBadge(status),
                  ],
                ),
                const SizedBox(height: 6),
                RichText(
                  text: TextSpan(
                    children: [
                      const TextSpan(
                        text: 'Melamar sebagai ',
                        style: TextStyle(
                          fontSize: 14,
                          color: textGrey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      TextSpan(
                        text: jobTitle,
                        style: const TextStyle(
                          fontSize: 14,
                          color: navy,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _smallInfo(Icons.email_rounded, email),
                const SizedBox(height: 8),
                _smallInfo(Icons.phone_rounded, phone),
                const SizedBox(height: 8),
                _smallInfo(Icons.location_on_rounded, location),
                const SizedBox(height: 8),
                _smallInfo(
                  Icons.calendar_month_rounded,
                  'Melamar pada ${_formatDate(createdAt)}',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileAvatar(String name) {
    final profilePhoto = _stringValue(userDetails?['profile_photo']);

    Widget fallbackAvatar() {
      return CircleAvatar(
        radius: 34,
        backgroundColor: lightBlue,
        child: Text(
          _getInitials(name),
          style: const TextStyle(
            color: navy,
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
      );
    }

    debugPrint(
      'DEBUG FOTO DETAIL $name: '
      'isEmpty=${profilePhoto.isEmpty}, '
      'length=${profilePhoto.length}, '
      'prefix=${profilePhoto.length > 40 ? profilePhoto.substring(0, 40) : profilePhoto}',
    );

    final photo = profilePhoto.trim();

    if (photo.isEmpty) {
      return fallbackAvatar();
    }

    try {
      if (photo.startsWith('http')) {
        return ClipOval(
          child: Image.network(
            photo,
            width: 68,
            height: 68,
            fit: BoxFit.cover,
            errorBuilder: (_, error, ___) {
              debugPrint('DEBUG IMAGE NETWORK ERROR DETAIL $name: $error');
              return fallbackAvatar();
            },
          ),
        );
      }

      if (_isLikelyLocalFilePath(photo)) {
        return ClipOval(
          child: Image.file(
            File(photo),
            width: 68,
            height: 68,
            fit: BoxFit.cover,
            errorBuilder: (_, error, ___) {
              debugPrint('DEBUG IMAGE FILE ERROR DETAIL $name: $error');
              return fallbackAvatar();
            },
          ),
        );
      }

      final cleanedPhoto = _cleanBase64Image(photo);
      final bytes = base64Decode(cleanedPhoto);

      debugPrint(
        'DEBUG BASE64 OK DETAIL $name: '
        'bytesLength=${bytes.length}, '
        'firstBytes=${bytes.length >= 4 ? bytes.sublist(0, 4).toString() : bytes.toString()}',
      );

      return ClipOval(
        child: Image.memory(
          bytes,
          width: 68,
          height: 68,
          fit: BoxFit.cover,
          gaplessPlayback: true,
          errorBuilder: (_, error, ___) {
            debugPrint('DEBUG IMAGE MEMORY ERROR DETAIL $name: $error');
            return fallbackAvatar();
          },
        ),
      );
    } catch (e) {
      debugPrint('Gagal render foto detail pelamar $name: $e');
      return fallbackAvatar();
    }
  }

  Widget _buildStatusTimelineCard({
    required String status,
    required String sentDate,
  }) {
    final normalized = _normalizeStatus(status);
    final statusIndex = _statusIndex(normalized);

    final timelineItems = <Map<String, dynamic>>[
      {
        'key': 'dikirim',
        'title': 'Dikirim',
        'date': sentDate,
        'description': 'Lamaran berhasil dikirim oleh pelamar.',
        'active': true,
        'done': true,
        'color': greenText,
      },
      {
        'key': 'ditinjau',
        'title': 'Ditinjau',
        'date': widget.applicant['reviewed_at'] != null
            ? _formatDateShort(widget.applicant['reviewed_at'])
            : widget.applicant['processed_at'] != null
                ? _formatDateShort(widget.applicant['processed_at'])
                : '-',
        'description': 'Lamaran sedang ditinjau oleh perusahaan.',
        'active': statusIndex >= 1,
        'done': statusIndex >= 1,
        'color': orangeText,
      },
      {
        'key': 'wawancara',
        'title': 'Wawancara',
        'date': widget.applicant['interview_status_updated_at'] != null
            ? _formatDateShort(widget.applicant['interview_status_updated_at'])
            : widget.applicant['updated_at'] != null && normalized == 'wawancara'
                ? _formatDateShort(widget.applicant['updated_at'])
                : '-',
        'description': widget.applicant['interview_display'] != null
            ? 'Jadwal wawancara: ${_stringValue(widget.applicant['interview_display'])}'
            : _stringValue(widget.applicant['interview_note']).isNotEmpty
                ? _stringValue(widget.applicant['interview_note'])
                : 'Pelamar masuk ke tahap wawancara.',
        'active': statusIndex >= 2,
        'done': statusIndex >= 2,
        'color': navy,
      },
    ];

    if (normalized == 'diterima') {
      timelineItems.add({
        'key': 'diterima',
        'title': 'Diterima',
        'date': widget.applicant['accepted_at'] != null
            ? _formatDateShort(widget.applicant['accepted_at'])
            : widget.applicant['accepted_status_updated_at'] != null
                ? _formatDateShort(widget.applicant['accepted_status_updated_at'])
                : normalized == 'diterima' && widget.applicant['updated_at'] != null
                    ? _formatDateShort(widget.applicant['updated_at'])
                    : '-',
        'description': _stringValue(widget.applicant['accepted_message']).isNotEmpty
            ? _stringValue(widget.applicant['accepted_message'])
            : 'Pelamar diterima untuk posisi ini.',
        'active': true,
        'done': true,
        'color': greenText,
      });
    } else if (normalized == 'ditolak') {
      timelineItems.add({
        'key': 'ditolak',
        'title': 'Ditolak',
        'date': widget.applicant['rejected_at'] != null
            ? _formatDateShort(widget.applicant['rejected_at'])
            : '-',
        'description': _stringValue(widget.applicant['rejection_reason']).isNotEmpty
            ? _stringValue(widget.applicant['rejection_reason'])
            : 'Lamaran belum dapat dilanjutkan.',
        'active': true,
        'done': true,
        'color': redText,
      });
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Status Lamaran',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: navy,
            ),
          ),
          const SizedBox(height: 18),
          Column(
            children: List.generate(timelineItems.length, (index) {
              final item = timelineItems[index];
              final isLast = index == timelineItems.length - 1;

              return _timelineItem(
                title: item['title'],
                date: item['date'],
                description: item['description'],
                active: item['active'],
                done: item['done'],
                color: item['color'],
                isLast: isLast,
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _timelineItem({
    required String title,
    required String date,
    required String description,
    required bool active,
    required bool done,
    required Color color,
    required bool isLast,
  }) {
    final circleColor = active ? color : greyText;
    final lineColor = active ? color.withOpacity(0.55) : greyBg;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: active ? color.withOpacity(0.14) : greyBg,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: circleColor,
                    width: 2,
                  ),
                ),
                child: Icon(
                  done ? Icons.check_rounded : Icons.circle,
                  size: done ? 23 : 10,
                  color: circleColor,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 3,
                    margin: const EdgeInsets.symmetric(vertical: 5),
                    decoration: BoxDecoration(
                      color: lineColor,
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Container(
              margin: EdgeInsets.only(bottom: isLast ? 0 : 18),
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              decoration: BoxDecoration(
                color:
                    active ? color.withOpacity(0.08) : const Color(0xFFF7F8FB),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: active
                      ? color.withOpacity(0.20)
                      : Colors.grey.shade200,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: active ? navy : greyText,
                          ),
                        ),
                      ),
                      Text(
                        date,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: active ? textGrey : greyText,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: active ? textGrey : greyText,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutCard({
    required String name,
    required String birthDate,
    required String gender,
    required String disability,
  }) {
    return _sectionCard(
      title: 'Tentang Pelamar',
      child: Column(
        children: [
          _profileInfoRow(
            icon: Icons.person_rounded,
            label: 'Nama Lengkap',
            value: name,
          ),
          _profileInfoRow(
            icon: Icons.cake_rounded,
            label: 'Tanggal Lahir',
            value: birthDate,
          ),
          _profileInfoRow(
            icon: Icons.wc_rounded,
            label: 'Jenis Kelamin',
            value: gender,
          ),
          _profileInfoRow(
            icon: Icons.accessibility_new_rounded,
            label: 'Disabilitas',
            value: disability,
          ),
        ],
      ),
    );
  }

  Widget _buildSkillsCard(List<String> skills) {
    return _sectionCard(
      title: 'Keahlian Pelamar',
      child: skills.isEmpty
          ? const Text(
              'Belum ada keahlian yang ditambahkan.',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: textGrey,
              ),
            )
          : Wrap(
              spacing: 12,
              runSpacing: 10,
              children: skills.map((skill) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 11,
                  ),
                  decoration: BoxDecoration(
                    color: chipBlue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    skill,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: navy,
                    ),
                  ),
                );
              }).toList(),
            ),
    );
  }

  Widget _buildCvDigitalCard() {
    return _sectionCard(
      title: 'CV Digital',
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: lightBlue.withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: chipBlue.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: navy.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.description_rounded,
                color: navy,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'CV Digital Pelamar',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: navy,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Detail pengalaman dan pendidikan',
                    style: TextStyle(
                      fontSize: 11,
                      color: textGrey.withOpacity(0.8),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 36,
              child: ElevatedButton(
                onPressed: () async {
                  final userId = widget.applicant['user_id'];
                  final cvData = await CvController.getCvByUserId(userId);

                  if (!mounted) return;

                  if (cvData != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CvDetailView(
                          cvData: cvData,
                          currentUser: user ?? {},
                          isReadOnly: true,
                        ),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Pelamar belum membuat CV Digital'),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: navy,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
                child: const Text(
                  'Detail',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(String status) {
    final normalized = _normalizeStatus(status);

    if (normalized == 'dikirim') {
      return _primaryButton(
        icon: Icons.manage_search_rounded,
        text: 'Tandai Ditinjau',
        color: orangeText,
        onTap: () {
          _updateApplicantStatus(
            context: context,
            status: 'ditinjau',
          );
        },
      );
    }

    if (normalized == 'ditinjau') {
      return _primaryButton(
        icon: Icons.event_available_rounded,
        text: 'Jadwalkan Wawancara',
        color: navy,
        onTap: _showInterviewDialog,
      );
    }

    if (normalized == 'wawancara') {
      return Column(
        children: [
          _primaryButton(
            icon: Icons.check_rounded,
            text: 'Terima Pelamar',
            color: greenText,
            onTap: _showAcceptedDialog,
          ),
          const SizedBox(height: 12),
          _outlineButton(
            icon: Icons.close_rounded,
            text: 'Tolak Pelamar',
            color: redText,
            onTap: _showRejectedDialog,
          ),
        ],
      );
    }

    if (normalized == 'diterima') {
      return _primaryButton(
        icon: Icons.info_outline_rounded,
        text: 'Pelamar Sudah Diterima',
        color: greenText,
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _stringValue(widget.applicant['accepted_message']).isNotEmpty
                    ? _stringValue(widget.applicant['accepted_message'])
                    : 'Pelamar sudah berada pada status diterima',
              ),
            ),
          );
        },
      );
    }

    if (normalized == 'ditolak') {
      return _outlineButton(
        icon: Icons.info_outline_rounded,
        text: 'Pelamar Sudah Ditolak',
        color: redText,
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _stringValue(widget.applicant['rejection_reason']).isNotEmpty
                    ? _stringValue(widget.applicant['rejection_reason'])
                    : 'Pelamar sudah berada pada status ditolak',
              ),
            ),
          );
        },
      );
    }

    return const SizedBox.shrink();
  }

  void _showInterviewDialog() {
    final pageContext = context;
    final noteController = TextEditingController();

    DateTime? selectedDate;
    TimeOfDay? selectedTime;

    showDialog(
      context: pageContext,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> pickDate() async {
              final pickedDate = await showDatePicker(
                context: dialogContext,
                initialDate: selectedDate ?? DateTime.now(),
                firstDate: DateTime.now(),
                lastDate: DateTime(2100),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: const ColorScheme.light(
                        primary: navy,
                        onPrimary: Colors.white,
                        onSurface: navy,
                      ),
                    ),
                    child: child!,
                  );
                },
              );

              if (pickedDate != null) {
                setDialogState(() {
                  selectedDate = pickedDate;
                });
              }
            }

            Future<void> pickTime() async {
              final pickedTime = await showTimePicker(
                context: dialogContext,
                initialTime: selectedTime ?? TimeOfDay.now(),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: const ColorScheme.light(
                        primary: navy,
                        onPrimary: Colors.white,
                        onSurface: navy,
                      ),
                    ),
                    child: child!,
                  );
                },
              );

              if (pickedTime != null) {
                setDialogState(() {
                  selectedTime = pickedTime;
                });
              }
            }

            String formatDate(DateTime? date) {
              if (date == null) return 'Pilih tanggal';

              const months = [
                'Januari',
                'Februari',
                'Maret',
                'April',
                'Mei',
                'Juni',
                'Juli',
                'Agustus',
                'September',
                'Oktober',
                'November',
                'Desember',
              ];

              return '${date.day} ${months[date.month - 1]} ${date.year}';
            }

            String formatTime(TimeOfDay? time) {
              if (time == null) return 'Pilih jam';

              final hour = time.hour.toString().padLeft(2, '0');
              final minute = time.minute.toString().padLeft(2, '0');
              return '$hour:$minute WIB';
            }

            String combinedDateTime() {
              if (selectedDate == null || selectedTime == null) return '';

              const months = [
                'Januari',
                'Februari',
                'Maret',
                'April',
                'Mei',
                'Juni',
                'Juli',
                'Agustus',
                'September',
                'Oktober',
                'November',
                'Desember',
              ];

              final hour = selectedTime!.hour.toString().padLeft(2, '0');
              final minute = selectedTime!.minute.toString().padLeft(2, '0');

              return '${selectedDate!.day} ${months[selectedDate!.month - 1]} ${selectedDate!.year}, $hour:$minute WIB';
            }

            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(horizontal: 28),
              child: Container(
                padding: const EdgeInsets.fromLTRB(22, 22, 22, 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.event_available_rounded,
                        color: navy,
                        size: 56,
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Jadwalkan Wawancara',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                          color: navy,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Tanggal Wawancara',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: navy,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: pickDate,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F5FC),
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.calendar_month_rounded,
                                color: navy,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  formatDate(selectedDate),
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                    color: selectedDate == null
                                        ? textGrey.withOpacity(0.7)
                                        : navy,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Jam Wawancara',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: navy,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: pickTime,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F5FC),
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.access_time_rounded,
                                color: navy,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  formatTime(selectedTime),
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                    color: selectedTime == null
                                        ? textGrey.withOpacity(0.7)
                                        : navy,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      _dialogInput(
                        controller: noteController,
                        label: 'Catatan Wawancara',
                        hint: 'Contoh: Wawancara melalui Google Meet',
                        maxLines: 3,
                      ),
                      const SizedBox(height: 20),
                      _dialogButtons(
                        cancelText: 'Batal',
                        actionText: 'Simpan',
                        actionColor: navy,
                        onCancel: () => Navigator.pop(dialogContext),
                        onAction: () {
                          if (selectedDate == null || selectedTime == null) {
                            ScaffoldMessenger.of(pageContext).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Tanggal dan jam wawancara wajib dipilih',
                                ),
                              ),
                            );
                            return;
                          }

                          final interviewDateTime = DateTime(
                            selectedDate!.year,
                            selectedDate!.month,
                            selectedDate!.day,
                            selectedTime!.hour,
                            selectedTime!.minute,
                          );

                          Navigator.pop(dialogContext);

                          _updateApplicantStatus(
                            context: pageContext,
                            status: 'wawancara',
                            extraData: {
                              'interview_date':
                                  interviewDateTime.toIso8601String(),
                              'interview_display': combinedDateTime(),
                              'interview_note': noteController.text.trim(),
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showAcceptedDialog() {
    final messageController = TextEditingController();
    final startDateController = TextEditingController();
    final workInfoController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 28),
          child: Container(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: greenText,
                    size: 56,
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Terima Pelamar',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                      color: navy,
                    ),
                  ),
                  const SizedBox(height: 18),
                  _dialogInput(
                    controller: messageController,
                    label: 'Pesan untuk Pelamar',
                    hint: 'Contoh: Selamat, Anda diterima untuk posisi ini.',
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),
                  _dialogInput(
                    controller: startDateController,
                    label: 'Tanggal Mulai Kerja',
                    hint: 'Contoh: 20 Mei 2026',
                  ),
                  const SizedBox(height: 12),
                  _dialogInput(
                    controller: workInfoController,
                    label: 'Informasi Tambahan',
                    hint: 'Contoh: Gunakan kemeja putih dan celana hitam.',
                    maxLines: 3,
                  ),
                  const SizedBox(height: 20),
                  _dialogButtons(
                    cancelText: 'Batal',
                    actionText: 'Terima',
                    actionColor: greenText,
                    onCancel: () => Navigator.pop(dialogContext),
                    onAction: () {
                      if (messageController.text.trim().isEmpty ||
                          startDateController.text.trim().isEmpty ||
                          workInfoController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Semua informasi penerimaan wajib diisi',
                            ),
                          ),
                        );
                        return;
                      }

                      Navigator.pop(dialogContext);

                      _updateApplicantStatus(
                        context: context,
                        status: 'diterima',
                        extraData: {
                          'accepted_message': messageController.text.trim(),
                          'start_work_date': startDateController.text.trim(),
                          'work_info': workInfoController.text.trim(),
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showRejectedDialog() {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 28),
          child: Container(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.cancel_rounded,
                  color: redText,
                  size: 56,
                ),
                const SizedBox(height: 14),
                const Text(
                  'Tolak Pelamar',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    color: navy,
                  ),
                ),
                const SizedBox(height: 18),
                _dialogInput(
                  controller: reasonController,
                  label: 'Alasan Penolakan',
                  hint:
                      'Contoh: Kualifikasi belum sesuai dengan kebutuhan posisi.',
                  maxLines: 4,
                ),
                const SizedBox(height: 20),
                _dialogButtons(
                  cancelText: 'Batal',
                  actionText: 'Tolak',
                  actionColor: redText,
                  onCancel: () => Navigator.pop(dialogContext),
                  onAction: () {
                    if (reasonController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Alasan penolakan wajib diisi'),
                        ),
                      );
                      return;
                    }

                    Navigator.pop(dialogContext);

                    _updateApplicantStatus(
                      context: context,
                      status: 'ditolak',
                      extraData: {
                        'rejection_reason': reasonController.text.trim(),
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _dialogInput({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: navy,
          ),
        ),
        const SizedBox(height: 7),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: navy,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              fontSize: 13,
              color: textGrey.withOpacity(0.65),
              fontWeight: FontWeight.w500,
            ),
            filled: true,
            fillColor: const Color(0xFFF3F5FC),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _dialogButtons({
    required String cancelText,
    required String actionText,
    required Color actionColor,
    required VoidCallback onCancel,
    required VoidCallback onAction,
  }) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 44,
            child: ElevatedButton(
              onPressed: onCancel,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE5E7EB),
                foregroundColor: navy,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
              child: Text(
                cancelText,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SizedBox(
            height: 44,
            child: ElevatedButton(
              onPressed: onAction,
              style: ElevatedButton.styleFrom(
                backgroundColor: actionColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
              child: Text(
                actionText,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _profileInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: textGrey),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: textGrey,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: textGrey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _smallInfo(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 17, color: textGrey),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text.isEmpty ? '-' : text,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: textGrey,
            ),
          ),
        ),
      ],
    );
  }

  Widget _statusBadge(String status) {
    final normalized = _normalizeStatus(status);

    Color bgColor;
    Color textColor;

    if (normalized == 'diterima') {
      bgColor = greenBg;
      textColor = greenText;
    } else if (normalized == 'ditolak') {
      bgColor = redBg;
      textColor = redText;
    } else if (normalized == 'wawancara') {
      bgColor = lightBlue;
      textColor = navy;
    } else if (normalized == 'ditinjau') {
      bgColor = orangeBg;
      textColor = orangeText;
    } else {
      bgColor = greyBg;
      textColor = greyText;
    }

    return Container(
      width: 92,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _statusLabel(status),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w900,
          color: textColor,
        ),
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: navy,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _primaryButton({
    required IconData icon,
    required String text,
    required Color color,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      height: 52,
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 24),
        label: Text(text),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 5,
          shadowColor: Colors.black.withOpacity(0.25),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

  Widget _outlineButton({
    required IconData icon,
    required String text,
    required Color color,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      height: 52,
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 24, color: color),
        label: Text(text),
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color, width: 1.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.14),
          blurRadius: 11,
          offset: const Offset(0, 5),
        ),
      ],
    );
  }
}