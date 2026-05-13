import 'package:flutter/material.dart';
import '../../services/mongo_service.dart';
import '../profile/accessibility_settings_view.dart';

class JobSeekerNotificationDetailPage extends StatefulWidget {
  final Map<String, dynamic> notification;

  const JobSeekerNotificationDetailPage({
    super.key,
    required this.notification,
  });

  @override
  State<JobSeekerNotificationDetailPage> createState() =>
      _JobSeekerNotificationDetailPageState();
}

class _JobSeekerNotificationDetailPageState
    extends State<JobSeekerNotificationDetailPage> {
  static const Color navy = Color(0xFF0D1B55);
  static const Color textGrey = Color(0xFF4A5870);
  static const Color lightBlue = Color(0xFFEAF0FF);
  static const Color greenText = Color(0xFF18A64A);
  static const Color orangeText = Color(0xFFF59E0B);
  static const Color redText = Color(0xFFE2262C);

  Map<String, dynamic>? application;
  Map<String, dynamic>? job;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDetailData();
  }

  Future<void> _loadDetailData() async {
    try {
      final notificationId = MongoService.getMongoId(widget.notification['_id']);

      if (notificationId.isNotEmpty &&
          widget.notification['is_read'] == false) {
        await MongoService.markNotificationAsRead(
          notificationId: notificationId,
        );
      }

      final applicationId = widget.notification['application_id'];
      final jobIdFromNotification = widget.notification['job_id'];

      Map<String, dynamic>? loadedApplication;
      Map<String, dynamic>? loadedJob;

      if (applicationId != null &&
          applicationId.toString().trim().isNotEmpty) {
        loadedApplication = await MongoService.getApplicationById(
          applicationId,
        );
      }

      final effectiveJobId =
          jobIdFromNotification ?? loadedApplication?['job_id'];

      if (effectiveJobId != null &&
          effectiveJobId.toString().trim().isNotEmpty) {
        loadedJob = await MongoService.getJobById(effectiveJobId);
      }

      if (!mounted) return;

      setState(() {
        application = loadedApplication;
        job = loadedJob;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Gagal memuat detail notifikasi job seeker: $e');

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });
    }
  }

  String _text(dynamic value, {String fallback = '-'}) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  String _formatDate(dynamic value) {
    if (value == null) return '-';

    if (value is DateTime) {
      return _dateToText(value.toLocal());
    }

    final parsed = DateTime.tryParse(value.toString());
    if (parsed == null) {
      final text = value.toString().trim();
      return text.isEmpty ? '-' : text;
    }

    return _dateToText(parsed.toLocal());
  }

  String _dateToText(DateTime date) {
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

    return value.isEmpty ? 'dikirim' : value;
  }

  String _statusFromNotificationType(String type, String fallbackStatus) {
    switch (type) {
      case 'application_reviewed':
      case 'application_status':
        return 'ditinjau';

      case 'interview_schedule':
      case 'interview_call':
        return 'wawancara';

      case 'application_accepted':
        return 'diterima';

      case 'application_rejected':
        return 'ditolak';

      default:
        return fallbackStatus;
    }
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
        return status.isEmpty ? '-' : status;
    }
  }

  Color _typeColor(String type, String status, {bool isHighContrast = false}) {
    if (isHighContrast) return AccessibilityTheme.yellow;

    if (type == 'application_rejected') {
      return redText;
    }

    if (type == 'application_accepted') {
      return greenText;
    }

    if (type == 'interview_schedule' || type == 'interview_call') {
      return navy;
    }

    if (type == 'application_reviewed' || type == 'application_status') {
      return orangeText;
    }

    final normalized = _normalizeStatus(status);

    if (normalized == 'ditolak') return redText;
    if (normalized == 'diterima') return greenText;
    if (normalized == 'wawancara') return navy;
    if (normalized == 'ditinjau') return orangeText;

    return navy;
  }

  IconData _typeIcon(String type, String status) {
    if (type == 'application_rejected') {
      return Icons.cancel_rounded;
    }

    if (type == 'application_accepted') {
      return Icons.check_circle_rounded;
    }

    if (type == 'interview_schedule' || type == 'interview_call') {
      return Icons.event_available_rounded;
    }

    if (type == 'application_reviewed' || type == 'application_status') {
      return Icons.manage_search_rounded;
    }

    final normalized = _normalizeStatus(status);

    if (normalized == 'ditolak') return Icons.cancel_rounded;
    if (normalized == 'diterima') return Icons.check_circle_rounded;
    if (normalized == 'wawancara') return Icons.event_available_rounded;
    if (normalized == 'ditinjau') return Icons.manage_search_rounded;

    return Icons.notifications_rounded;
  }

  String _getInterviewDisplayFromNotification() {
    final directValue = _text(
      widget.notification['interview_display'] ??
          widget.notification['interview_date_display'],
      fallback: '',
    );

    if (directValue.isNotEmpty) return directValue;

    final message = _text(
      widget.notification['message'],
      fallback: '',
    );

    final marker = 'Jadwal:';
    final markerIndex = message.indexOf(marker);

    if (markerIndex != -1) {
      final extracted = message.substring(markerIndex + marker.length).trim();

      if (extracted.isNotEmpty) {
        return extracted.replaceAll(RegExp(r'\.$'), '');
      }
    }

    return _text(
      application?['interview_display'] ??
          _formatDate(application?['interview_date']),
    );
  }

  String _getInterviewNoteFromNotification() {
    final directValue = _text(
      widget.notification['interview_note'],
      fallback: '',
    );

    if (directValue.isNotEmpty) return directValue;

    return _text(application?['interview_note']);
  }

  @override
  Widget build(BuildContext context) {
    final title = _text(
      widget.notification['title'],
      fallback: 'Detail Notifikasi',
    );

    final message = _text(
      widget.notification['message'],
      fallback: '-',
    );

    final type = _text(
      widget.notification['type'],
      fallback: '',
    );

    final applicationStatus = _text(
      application?['status'],
      fallback: '',
    );

    final status = _statusFromNotificationType(
      type,
      applicationStatus,
    );

    final jobTitle = _text(
      application?['job_title'] ?? job?['title'],
      fallback: '-',
    );

    final companyName = _text(
      application?['company_name'] ??
          job?['company_name'] ??
          job?['company'] ??
          job?['name'],
      fallback: '-',
    );

    return ValueListenableBuilder<bool>(
      valueListenable: AccessibilityController.highContrastNotifier,
      builder: (context, isHighContrast, _) {
        final typeColor = _typeColor(type, status, isHighContrast: isHighContrast);
        final bgColor = isHighContrast ? AccessibilityTheme.black : Colors.white;
        final mainColor = isHighContrast ? AccessibilityTheme.yellow : navy;
        final textColor = isHighContrast ? AccessibilityTheme.yellow : textGrey;
        final cardColor = isHighContrast ? AccessibilityTheme.darkCard : Colors.white;

        return Scaffold(
          backgroundColor: bgColor,
          appBar: AppBar(
            backgroundColor: bgColor,
            elevation: 0,
            iconTheme: IconThemeData(color: mainColor),
            title: Text(
              'Detail Notifikasi',
              style: TextStyle(
                color: mainColor,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          body: isLoading
              ? Center(
                  child: CircularProgressIndicator(
                    color: mainColor,
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
                  children: [
                    _buildHeaderCard(
                      title: title,
                      message: message,
                      type: type,
                      status: status,
                      color: typeColor,
                      isHighContrast: isHighContrast,
                    ),
                    const SizedBox(height: 18),
                    _buildMainInfoCard(
                      jobTitle: jobTitle,
                      companyName: companyName,
                      status: status,
                      isHighContrast: isHighContrast,
                    ),
                    const SizedBox(height: 18),
                    _buildDynamicDetailCard(
                      type: type,
                      status: status,
                      message: message,
                      isHighContrast: isHighContrast,
                    ),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildHeaderCard({
    required String title,
    required String message,
    required String type,
    required String status,
    required Color color,
    required bool isHighContrast,
  }) {
    final mainColor = isHighContrast ? AccessibilityTheme.yellow : navy;
    final textColor = isHighContrast ? AccessibilityTheme.yellow : textGrey;
    final cardBgColor = isHighContrast ? AccessibilityTheme.darkCard : Colors.white;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(isHighContrast: isHighContrast),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _typeIcon(type, status),
                  color: color,
                  size: 30,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                    color: mainColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 14,
              height: 1.45,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Icon(
                Icons.access_time_rounded,
                size: 17,
                color: textColor,
              ),
              const SizedBox(width: 7),
              Text(
                _formatDate(widget.notification['created_at']),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: textColor.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMainInfoCard({
    required String jobTitle,
    required String companyName,
    required String status,
    required bool isHighContrast,
  }) {
    final mainColor = isHighContrast ? AccessibilityTheme.yellow : navy;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(isHighContrast: isHighContrast),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Informasi Lamaran',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: mainColor,
            ),
          ),
          const SizedBox(height: 14),
          _infoRow(
            icon: Icons.work_rounded,
            label: 'Posisi',
            value: jobTitle,
            isHighContrast: isHighContrast,
          ),
          _infoRow(
            icon: Icons.business_rounded,
            label: 'Perusahaan',
            value: companyName,
            isHighContrast: isHighContrast,
          ),
          _infoRow(
            icon: Icons.fact_check_rounded,
            label: 'Status Saat Notifikasi',
            value: _statusLabel(status),
            isHighContrast: isHighContrast,
          ),
        ],
      ),
    );
  }

  Widget _buildDynamicDetailCard({
    required String type,
    required String status,
    required String message,
    required bool isHighContrast,
  }) {
    final normalized = _normalizeStatus(status);

    if (type == 'interview_schedule' ||
        type == 'interview_call' ||
        normalized == 'wawancara') {
      return _sectionCard(
        title: 'Detail Wawancara',
        isHighContrast: isHighContrast,
        children: [
          _infoRow(
            icon: Icons.calendar_month_rounded,
            label: 'Jadwal',
            value: _getInterviewDisplayFromNotification(),
            isHighContrast: isHighContrast,
          ),
          _infoRow(
            icon: Icons.notes_rounded,
            label: 'Catatan',
            value: _getInterviewNoteFromNotification(),
            isHighContrast: isHighContrast,
          ),
        ],
      );
    }

    if (type == 'application_accepted' || normalized == 'diterima') {
      return _sectionCard(
        title: 'Detail Penerimaan',
        isHighContrast: isHighContrast,
        children: [
          _infoRow(
            icon: Icons.message_rounded,
            label: 'Pesan Penerimaan',
            value: _text(application?['accepted_message']),
            isHighContrast: isHighContrast,
          ),
          _infoRow(
            icon: Icons.calendar_today_rounded,
            label: 'Tanggal Mulai Kerja',
            value: _text(application?['start_work_date']),
            isHighContrast: isHighContrast,
          ),
          _infoRow(
            icon: Icons.info_rounded,
            label: 'Info Tambahan',
            value: _text(application?['work_info']),
            isHighContrast: isHighContrast,
          ),
        ],
      );
    }

    if (type == 'application_rejected' || normalized == 'ditolak') {
      return _sectionCard(
        title: 'Detail Penolakan',
        isHighContrast: isHighContrast,
        children: [
          _infoRow(
            icon: Icons.report_problem_rounded,
            label: 'Alasan Penolakan',
            value: _text(application?['rejection_reason']),
            isHighContrast: isHighContrast,
          ),
        ],
      );
    }

    return _sectionCard(
      title: 'Detail Status',
      isHighContrast: isHighContrast,
      children: [
        _infoRow(
          icon: Icons.manage_search_rounded,
          label: 'Keterangan',
          value: normalized == 'ditinjau'
              ? 'Lamaran kamu sedang ditinjau oleh perusahaan.'
              : message,
          isHighContrast: isHighContrast,
        ),
      ],
    );
  }

  Widget _sectionCard({
    required String title,
    required List<Widget> children,
    required bool isHighContrast,
  }) {
    final mainColor = isHighContrast ? AccessibilityTheme.yellow : navy;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(isHighContrast: isHighContrast),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: mainColor,
            ),
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _infoRow({
    required IconData icon,
    required String label,
    required String value,
    required bool isHighContrast,
  }) {
    final textColor = isHighContrast ? AccessibilityTheme.yellow : textGrey;
    final mainColor = isHighContrast ? AccessibilityTheme.yellow : navy;

    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: textColor.withOpacity(0.8),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: textColor.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: mainColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration({required bool isHighContrast}) {
    final cardBgColor = isHighContrast ? AccessibilityTheme.darkCard : Colors.white;
    final shadowColor = isHighContrast ? Colors.transparent : Colors.black.withOpacity(0.04);
    final borderColor = isHighContrast ? AccessibilityTheme.yellow.withOpacity(0.2) : Colors.grey.withOpacity(0.1);

    return BoxDecoration(
      color: cardBgColor,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: borderColor),
      boxShadow: [
        BoxShadow(
          color: shadowColor,
          blurRadius: 12,
          offset: const Offset(0, 5),
        ),
      ],
    );
  }
}