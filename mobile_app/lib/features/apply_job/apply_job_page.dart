import 'package:flutter/material.dart';
import 'dart:convert';
import '../../core/constants/app_colors.dart';
import '../../services/mongo_service.dart';
import 'application_success_page.dart';

class ApplyJobPage extends StatefulWidget {
  final Map<String, dynamic> job;
  final Map<String, dynamic> currentUser;
  final Map<String, dynamic> userDetails;

  const ApplyJobPage({
    super.key,
    required this.job,
    this.currentUser = const {},
    this.userDetails = const {},
  });

  @override
  State<ApplyJobPage> createState() => _ApplyJobPageState();
}

class _ApplyJobPageState extends State<ApplyJobPage> {
  final TextEditingController _messageController = TextEditingController();
  bool _isSubmitting = false;
  int _messageLength = 0;

  static const int _maxMessageLength = 100;

  @override
  void initState() {
    super.initState();

    _messageController.addListener(() {
      setState(() {
        _messageLength = _messageController.text.length;
      });
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  String get _jobId => MongoService.getMongoId(widget.job['_id']);

  String get _userId {
    return widget.currentUser['_id']?.toString() ??
        widget.currentUser['id']?.toString() ??
        widget.currentUser['user_id']?.toString() ??
        widget.currentUser['email']?.toString() ??
        '';
  }

  String get _fullName {
    return widget.userDetails['nama_lengkap']?.toString() ??
        widget.currentUser['nama_lengkap']?.toString() ??
        '';
  }

  String get _email {
    return widget.userDetails['email']?.toString() ??
        widget.currentUser['email']?.toString() ??
        '-';
  }

  String get _phone {
    return widget.userDetails['phone']?.toString() ??
        widget.userDetails['no_hp']?.toString() ??
        widget.currentUser['phone']?.toString() ??
        widget.currentUser['no_hp']?.toString() ??
        '-';
  }

  String get _jobTitle => widget.job['title']?.toString() ?? '-';
  String get _companyName => widget.job['company_name']?.toString() ?? '-';
  String get _location => widget.job['location']?.toString() ?? '-';
  String get _jobType => widget.job['job_type']?.toString() ?? '-';

  void _showCustomSnackBar(String message, {IconData icon = Icons.info_outline}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? Colors.black : AppColors.primaryNavy,
        elevation: 8,
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: isDark ? const BorderSide(color: Colors.yellow) : BorderSide.none,
        ),
        content: Row(
          children: [
            Icon(icon, color: isDark ? Colors.yellow : Colors.white, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: isDark ? Colors.yellow : Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitApplication() async {
    if (_isSubmitting) return;

    final message = _messageController.text.trim();

    if (_userId.isEmpty || _jobId.isEmpty) {
      _showCustomSnackBar(
        'Data pengguna atau lowongan tidak valid',
        icon: Icons.error_outline,
      );
      return;
    }

    if (_fullName.trim().isEmpty || _email.trim().isEmpty || _phone.trim().isEmpty) {
      _showCustomSnackBar(
        'Data diri belum lengkap',
        icon: Icons.error_outline,
      );
      return;
    }

    if (message.length > _maxMessageLength) {
      _showCustomSnackBar(
        'Pesan maksimal 100 karakter',
        icon: Icons.error_outline,
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final alreadyApplied = await MongoService.hasAppliedJob(
      userId: _userId,
      jobId: _jobId,
    );

    if (!mounted) return;

    if (alreadyApplied) {
      setState(() {
        _isSubmitting = false;
      });
      _showCustomSnackBar(
        'Kamu sudah pernah melamar lowongan ini',
        icon: Icons.info_outline,
      );
      return;
    }

    final success = await MongoService.submitJobApplication(
      applicationData: {
        'user_id': _userId,
        'job_id': _jobId,
        'job_title': _jobTitle,
        'company_name': _companyName,
        'full_name': _fullName,
        'email': _email,
        'phone': _phone,
        'message': message,
        'status': 'pending',
        'job_photo': widget.job['job_photo'], // Tambahkan ini agar foto tersimpan di koleksi lamaran
        'sync_status': 'synced',
        'created_at': DateTime.now().toUtc(),
      },
    );

    if (!mounted) return;

    setState(() {
      _isSubmitting = false;
    });

    if (success) {
      // Trigger notification for company
      final jobData = widget.job;
      final companyId = jobData['company_id'];
      
      if (companyId != null) {
        await MongoService.createNotification(
          receiverId: companyId,
          receiverRole: 'company',
          senderId: _userId,
          senderRole: 'job_seeker',
          applicationId: '', // Will be updated on refresh if needed, or leave empty
          jobId: _jobId,
          title: 'Pelamar Baru',
          message: '$_fullName telah melamar untuk posisi $_jobTitle.',
          type: 'new_applicant',
        );
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ApplicationSuccessPage(currentUser: widget.currentUser),
        ),
      );
    } else {
      _showCustomSnackBar(
        'Lamaran gagal dikirim',
        icon: Icons.error_outline,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 10, 24, 0),
              child: _Header(
                title: 'Lamar Sekarang',
                onBack: () => Navigator.pop(context),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _JobSummaryCard(
                      title: _jobTitle,
                      company: _companyName,
                      location: _location,
                      jobType: _jobType,
                      jobPhoto: widget.job['job_photo'], // Tambahkan ini
                    ),
                    const SizedBox(height: 22),
                    Text(
                      'Data Diri',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Data Diambil dari profil kamu. Pastikan sudah benar.',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.yellow.withOpacity(0.7) : AppColors.textGray,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _InfoField(
                      icon: Icons.person,
                      label: 'Nama Lengkap',
                      value: _fullName.isEmpty ? '-' : _fullName,
                    ),
                    const SizedBox(height: 13),
                    _InfoField(
                      icon: Icons.email_outlined,
                      label: 'Email',
                      value: _email.isEmpty ? '-' : _email,
                    ),
                    const SizedBox(height: 13),
                    _InfoField(
                      icon: Icons.phone,
                      label: 'No. Handphone',
                      value: _phone.isEmpty ? '-' : _phone,
                    ),
                    const SizedBox(height: 26),
                    Text(
                      'Pesan untuk Perusahaan (Opsional)',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Tulis pesan singkat untuk memperkenalkan dirimu',
                      style: TextStyle(fontSize: 11, color: isDark ? Colors.yellow.withOpacity(0.7) : AppColors.textGray),
                    ),
                    const SizedBox(height: 12),
                    _MessageBox(
                      controller: _messageController,
                      maxLength: _maxMessageLength,
                      currentLength: _messageLength,
                    ),
                    const SizedBox(height: 26),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton.icon(
                        onPressed: _isSubmitting ? null : _submitApplication,
                        icon: _isSubmitting
                            ? SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(isDark ? Colors.black : Colors.white),
                                ),
                              )
                            : Icon(Icons.send_outlined, color: isDark ? Colors.black : Colors.white, size: 24),
                        label: Text(
                          _isSubmitting ? 'Mengirim...' : 'Kirim Lamaran',
                          style: TextStyle(
                            color: isDark ? Colors.black : Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          disabledBackgroundColor: theme.colorScheme.primary.withOpacity(0.65),
                          elevation: 4,
                          shadowColor: Colors.black26,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
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

class _Header extends StatelessWidget {
  final String title;
  final VoidCallback onBack;

  const _Header({required this.title, required this.onBack});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        IconButton(
          onPressed: onBack,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          icon: Icon(
            Icons.arrow_back,
            color: theme.colorScheme.primary,
            size: 28,
          ),
        ),
        const SizedBox(width: 18),
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }
}

class _JobSummaryCard extends StatelessWidget {
  final String title;
  final String company;
  final String location;
  final String jobType;
  final String? jobPhoto; // Tambahkan ini

  const _JobSummaryCard({
    required this.title,
    required this.company,
    required this.location,
    required this.jobType,
    this.jobPhoto, // Tambahkan ini
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.yellow.withOpacity(0.1) : AppColors.accentBlue.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: isDark ? Border.all(color: Colors.yellow.withOpacity(0.3)) : null,
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: isDark ? Colors.black : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: isDark ? Border.all(color: Colors.yellow) : null,
              image: jobPhoto != null
                  ? DecorationImage(
                      image: MemoryImage(base64Decode(jobPhoto!)),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: jobPhoto == null
                ? Icon(
                    Icons.business_center_rounded, // Ganti agar lebih relevan
                    color: theme.colorScheme.primary,
                    size: 40,
                  )
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  company,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.yellow.withOpacity(0.7) : AppColors.textGray,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 15, color: isDark ? Colors.yellow : AppColors.textGray),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        location,
                        style: TextStyle(fontSize: 12, color: isDark ? Colors.yellow : AppColors.textGray),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(Icons.work, size: 15, color: isDark ? Colors.yellow : AppColors.textGray),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        jobType,
                        style: TextStyle(fontSize: 12, color: isDark ? Colors.yellow : AppColors.textGray),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoField extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoField({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: isDark ? Colors.black : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.colorScheme.primary, width: 1),
      ),
      child: Row(
        children: [
          Icon(icon, color: theme.colorScheme.primary, size: 25),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: isDark ? Colors.yellow.withOpacity(0.7) : AppColors.textGray,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBox extends StatelessWidget {
  final TextEditingController controller;
  final int maxLength;
  final int currentLength;

  const _MessageBox({
    required this.controller,
    required this.maxLength,
    required this.currentLength,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      height: 93,
      decoration: BoxDecoration(
        color: isDark ? Colors.black : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.primary, width: 1),
      ),
      child: Stack(
        children: [
          TextField(
            controller: controller,
            maxLines: 4,
            maxLength: maxLength,
            style: TextStyle(fontSize: 13, color: isDark ? Colors.yellow : AppColors.primaryNavy),
            decoration: InputDecoration(
              counterText: '',
              hintText: 'Tulis pesan kamu disini...',
              hintStyle: TextStyle(color: isDark ? Colors.yellow.withOpacity(0.5) : AppColors.textGray, fontSize: 13),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.fromLTRB(16, 13, 16, 24),
            ),
          ),
          Positioned(
            right: 14,
            bottom: 8,
            child: Text(
              '$currentLength/$maxLength',
              style: TextStyle(fontSize: 11, color: isDark ? Colors.yellow.withOpacity(0.7) : AppColors.textGray),
            ),
          ),
        ],
      ),
    );
  }
}