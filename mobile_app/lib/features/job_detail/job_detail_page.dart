import 'package:flutter/material.dart';
import 'dart:convert';
import '../../core/constants/app_colors.dart';
import '../apply_job/apply_job_page.dart';
import '../profile/profile_controller.dart';

class JobDetailPage extends StatefulWidget {
  final Map<String, dynamic> job;
  final Map<String, dynamic> currentUser;

  const JobDetailPage({
    super.key,
    required this.job,
    this.currentUser = const {},
  });

  @override
  State<JobDetailPage> createState() => _JobDetailPageState();
}

class _JobDetailPageState extends State<JobDetailPage> {
  Map<String, dynamic>? userDetails;

  @override
  void initState() {
    super.initState();
    _loadUserDetails();
  }

  Future<void> _loadUserDetails() async {
    final userId = widget.currentUser['_id'];

    if (userId == null) return;

    final profile = await ProfileController.getProfileByUserId(userId);

    if (!mounted) return;

    setState(() {
      userDetails = profile;
    });
  }

  @override
  Widget build(BuildContext context) {
    final String title = widget.job['title'] ?? '-';
    final String company = widget.job['company_name'] ?? '-';
    final String location = widget.job['location'] ?? '-';
    final String jobType = widget.job['job_type'] ?? '-';
    final String description =
        widget.job['description'] ?? 'Tidak ada deskripsi.';
    final String? jobPhoto = widget.job['job_photo'];

    final List qualifications = (widget.job['qualification'] is List)
        ? widget.job['qualification']
        : (widget.job['qualification'] is String &&
                widget.job['qualification'].isNotEmpty)
            ? widget.job['qualification'].split('\n')
            : [];

    final List facilities = (widget.job['facilities'] is List)
        ? widget.job['facilities']
        : (widget.job['facilities'] is String &&
                widget.job['facilities'].isNotEmpty)
            ? widget.job['facilities'].split(',')
            : [];

    IconData getFacilityIcon(String name) {
      final lower = name.toLowerCase();
      if (lower.contains('akses')) return Icons.accessible;
      if (lower.contains('asuransi') || lower.contains('kesehat')) {
        return Icons.health_and_safety;
      }
      return Icons.check_circle_outline;
    }

    Widget jobHeader() {
      final theme = Theme.of(context);
      final isDark = theme.brightness == Brightness.dark;
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 56,
            width: 56,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.yellow.withOpacity(0.1)
                  : AppColors.primaryNavy.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              image: jobPhoto != null
                  ? DecorationImage(
                      image: MemoryImage(base64Decode(jobPhoto)),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: jobPhoto == null
                ? Icon(
                    Icons.business_center_rounded,
                    color: theme.colorScheme.primary,
                    size: 36,
                  )
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.titleLarge?.color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  company,
                  style: TextStyle(
                    fontSize: 15,
                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 16,
                      color: isDark ? Colors.yellow : AppColors.textGray,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      location,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.yellow : AppColors.textGray,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.work,
                      size: 16,
                      color: isDark ? Colors.yellow : AppColors.textGray,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      jobType,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.yellow : AppColors.textGray,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      );
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Detail Lowongan',
          style: TextStyle(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: jobHeader(),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Deskripsi Pekerjaan',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: theme.textTheme.bodyMedium?.color,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Kualifikasi Pekerjaan',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (qualifications.isEmpty)
                      Text(
                        'Tidak ada kualifikasi.',
                        style: TextStyle(
                          color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
                          fontSize: 14,
                        ),
                      )
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: qualifications
                            .map<Widget>(
                              (q) => Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '• ',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      q.toString(),
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: theme.textTheme.bodyMedium?.color,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                            .toList(),
                      ),
                    const SizedBox(height: 24),
                    Text(
                      'Fasilitas',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (facilities.isEmpty)
                      Text(
                        'Tidak ada fasilitas.',
                        style: TextStyle(
                          color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
                          fontSize: 14,
                        ),
                      )
                    else
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: facilities
                            .map<Widget>(
                              (f) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(12),
                                  border: isDark ? Border.all(color: Colors.yellow.withOpacity(0.3)) : null,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      getFacilityIcon(f.toString()),
                                      color: theme.colorScheme.primary,
                                      size: 22,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      f.toString(),
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: theme.colorScheme.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ApplyJobPage(
                                job: widget.job,
                                currentUser: widget.currentUser,
                                userDetails: userDetails ?? {},
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: isDark ? Colors.black : Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: isDark
                                ? const BorderSide(color: Colors.yellow)
                                : BorderSide.none,
                          ),
                        ),
                        child: const Text(
                          'Lamar Sekarang',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
