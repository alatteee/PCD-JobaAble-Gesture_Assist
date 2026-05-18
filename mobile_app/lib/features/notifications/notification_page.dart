import 'package:flutter/material.dart';
import '../../services/mongo_service.dart';
import '../company/company_applicant_detail_page.dart';
import 'job_seeker_notification_detail_page.dart';
import '../profile/accessibility_settings_view.dart';

class NotificationPage extends StatefulWidget {
  final Map<String, dynamic> currentUser;
  final String role; // "company" atau "job_seeker"

  const NotificationPage({
    super.key,
    required this.currentUser,
    required this.role,
  });

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    try {
      final userId = widget.currentUser['_id'];
      final results = await MongoService.getNotifications(
        receiverId: userId,
        receiverRole: widget.role,
      );
      if (mounted) {
        setState(() {
          _notifications = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Future<void> _handleNotificationClick(Map<String, dynamic> notification) async {
    if (notification['is_read'] == false) {
      final notificationId = MongoService.getMongoId(notification['_id']);

      await MongoService.markNotificationAsRead(
        notificationId: notificationId,
      );

      if (mounted) {
        setState(() {
          final index = _notifications.indexWhere(
            (n) => MongoService.getMongoId(n['_id']) == notificationId,
          );

          if (index != -1) {
            _notifications[index]['is_read'] = true;
          }
        });
      }
    }

    if (!mounted) return;

    final type = notification['type']?.toString() ?? '';
    final role = widget.role;

    if (role == 'company' && type == 'new_application') {
      _navigateToApplicantDetail(
        notification['application_id'],
        notification['job_id'],
      );
    } else if (role == 'job_seeker' &&
        (type.startsWith('application_') ||
            type == 'interview_schedule' ||
            type == 'interview_call' ||
            type == 'application_status')) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => JobSeekerNotificationDetailPage(
            notification: notification,
          ),
        ),
      );
    }
  }

  Future<void> _navigateToApplicationStatus(dynamic applicationId) async {
    if (applicationId == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final application = await MongoService.getApplicationById(applicationId);
      
      if (!mounted) return;
      Navigator.pop(context);

      if (application != null) {
        // Here we could navigate to ApplicationDetailPage for Job Seeker 
        // if you have that page. For now, showing a simple message or 
        // we can implement the navigation if the page exists.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Membuka status lamaran...')),
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
    }
  }

  Future<void> _navigateToApplicantDetail(dynamic applicationId, dynamic jobId) async {
    if (applicationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ID Lamaran tidak ditemukan di notifikasi.')),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final application = await MongoService.getApplicationById(applicationId);
      
      // If jobId is null in notification, we can try to get it from the application
      final effectiveJobId = jobId ?? application?['job_id'];
      final job = await MongoService.getJobById(effectiveJobId);

      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      if (application != null && job != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CompanyApplicantDetailPage(
              applicant: application,
              job: job,
            ),
          ),
        );
      } else {
        String missing = "";
        if (application == null) missing += "Data Pelamar ";
        if (job == null) missing += "Data Lowongan ";
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat: $missing tidak ditemukan.'),
            duration: const Duration(seconds: 4),
          ),
        );
        // Refresh notifications list if data is missing, it might be outdated
        _loadNotifications();
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Terjadi kesalahan: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AccessibilityController.highContrastNotifier,
      builder: (context, isHighContrast, _) {
        final bgColor = isHighContrast ? AccessibilityTheme.black : Colors.white;
        final mainColor = isHighContrast ? AccessibilityTheme.yellow : const Color(0xFF0D1B55);
        final textColor = isHighContrast ? AccessibilityTheme.yellow : const Color(0xFF4A5870);
        final cardBgColor = isHighContrast ? AccessibilityTheme.darkCard : Colors.white;
        final unreadCardBgColor = isHighContrast ? const Color(0xFF1A1A00) : const Color(0xFFF0F5FF);
        final emptyStateColor = isHighContrast ? AccessibilityTheme.yellow.withOpacity(0.6) : Colors.grey[300];

        return Scaffold(
          backgroundColor: bgColor,
          appBar: AppBar(
            title: Text(
              'Notifikasi',
              style: TextStyle(fontWeight: FontWeight.bold, color: mainColor),
            ),
            backgroundColor: bgColor,
            elevation: 0,
            iconTheme: IconThemeData(color: mainColor),
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _notifications.isEmpty
                  ? _buildEmptyState(emptyStateColor)
                  : RefreshIndicator(
                      onRefresh: _loadNotifications,
                      color: mainColor,
                      backgroundColor: bgColor,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _notifications.length,
                        itemBuilder: (context, index) {
                          final notif = _notifications[index];
                          final isRead = notif['is_read'] ?? false;
                          final date = (notif['created_at'] as DateTime).toLocal();

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: isRead ? cardBgColor : unreadCardBgColor,
                              borderRadius: BorderRadius.circular(16),
                              border: isRead
                                  ? Border.all(color: mainColor.withOpacity(0.2))
                                  : Border.all(color: mainColor.withOpacity(0.5), width: 1.5),
                              boxShadow: [
                                BoxShadow(
                                  color: isRead
                                      ? Colors.black.withOpacity(isHighContrast ? 0 : 0.03)
                                      : mainColor.withOpacity(isHighContrast ? 0.1 : 0.06),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () => _handleNotificationClick(notif),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: isRead
                                              ? (isHighContrast ? mainColor.withOpacity(0.2) : const Color(0xFFEAF0FF))
                                              : mainColor,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          isRead ? Icons.notifications_none_rounded : Icons.notifications_active_rounded,
                                          color: isRead
                                              ? mainColor
                                              : (isHighContrast ? AccessibilityTheme.black : Colors.white),
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    notif['title'] ?? 'Notifikasi',
                                                    style: TextStyle(
                                                      fontWeight: isRead ? FontWeight.w600 : FontWeight.w900,
                                                      fontSize: 16,
                                                      color: mainColor,
                                                    ),
                                                  ),
                                                ),
                                                if (!isRead)
                                                  Container(
                                                    width: 12,
                                                    height: 12,
                                                    decoration: const BoxDecoration(
                                                      color: Colors.orange,
                                                      shape: BoxShape.circle,
                                                      boxShadow: [
                                                        BoxShadow(color: Colors.orangeAccent, blurRadius: 4)
                                                      ],
                                                    ),
                                                  ),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              notif['message'] ?? '',
                                              style: TextStyle(
                                                color: textColor,
                                                fontSize: 14,
                                                fontWeight: isRead ? FontWeight.normal : FontWeight.w600,
                                              ),
                                            ),
                                            const SizedBox(height: 10),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                  _formatDate(date),
                                                  style: TextStyle(
                                                    color: textColor.withOpacity(0.7),
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                if (!isRead)
                                                  Text(
                                                    'Baru',
                                                    style: TextStyle(
                                                      color: mainColor,
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
        );
      },
    );
  }

  Widget _buildEmptyState(Color? iconColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off_outlined, size: 80, color: iconColor),
          const SizedBox(height: 16),
          const Text(
            'Belum ada notifikasi',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
