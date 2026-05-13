import 'package:flutter/material.dart';
import 'dart:convert';
import '../../core/constants/app_colors.dart';
import '../../services/mongo_service.dart';
import '../profile/accessibility_settings_view.dart';

class ApplicationsPage extends StatefulWidget {
  final Map<String, dynamic> currentUser;

  const ApplicationsPage({
    super.key,
    required this.currentUser,
  });

  @override
  State<ApplicationsPage> createState() => _ApplicationsPageState();
}

class _ApplicationsPageState extends State<ApplicationsPage> {
  bool _isLoading = true;
  String _selectedStatus = 'Dikirim';
  List<Map<String, dynamic>> _applications = [];


  @override
  void initState() {
    super.initState();
    _loadApplications();
  }

  String get _currentUserId {
    return widget.currentUser['_id']?.toString() ??
        widget.currentUser['id']?.toString() ??
        widget.currentUser['user_id']?.toString() ??
        widget.currentUser['email']?.toString() ??
        '';
  }

  Future<void> _loadApplications() async {
    if (_applications.isEmpty) {
      setState(() => _isLoading = true);
    }
    final data = await MongoService.getUserApplications(userId: _currentUserId);

    if (!mounted) return;

    setState(() {
      _applications = data;
      _isLoading = false;
    });
  }

  String _statusToFilter(String? status) {
    final s = (status ?? '').toLowerCase();
    
    // Status 'ditinjau' (Reviewed) seharusnya masuk ke tab 'Diproses'
    if (s == 'ditinjau' || s == 'reviewed' || s == 'diproses' || s == 'processed' || s == 'review') {
      return 'Diproses';
    }
    
    // Status akhir
    if (s == 'diterima' || s == 'accepted' || s == 'wawancara' || s == 'interview' || s == 'lolos' || s == 'selesai') {
      return 'Selesai';
    }
    
    if (s == 'rejected' || s == 'ditolak') {
      return 'Ditolak';
    }

    // Default untuk lamaran yang baru dikirim
    return 'Dikirim';
  }

  String _formatDate(dynamic value) {
    DateTime? date;

    if (value is DateTime) {
      date = value;
    } else if (value != null) {
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

    final localDate = date.toLocal();
    return '${localDate.day} ${months[localDate.month - 1]} ${localDate.year}';
  }

  List<Map<String, dynamic>> get _filteredApplications {
    return _applications
        .where((application) => _statusToFilter(application['status']?.toString()) == _selectedStatus)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ValueListenableBuilder<bool>(
      valueListenable: AccessibilityController.highContrastNotifier,
      builder: (context, isHighContrast, _) {
        final bgColor = isHighContrast ? AccessibilityTheme.black : theme.scaffoldBackgroundColor;
        final textColor = isHighContrast ? AccessibilityTheme.yellow : theme.textTheme.bodyLarge?.color;
        final buttonColor = isHighContrast ? AccessibilityTheme.yellow : theme.colorScheme.primary;
        final buttonTextColor = isHighContrast ? AccessibilityTheme.black : Colors.white;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: _StatusButton('Dikirim', _selectedStatus == 'Dikirim', () => _setStatus('Dikirim'), isHighContrast)),
                      const SizedBox(width: 26),
                      Expanded(child: _StatusButton('Diproses', _selectedStatus == 'Diproses', () => _setStatus('Diproses'), isHighContrast)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _StatusButton('Selesai', _selectedStatus == 'Selesai', () => _setStatus('Selesai'), isHighContrast)),
                      const SizedBox(width: 26),
                      Expanded(child: _StatusButton('Ditolak', _selectedStatus == 'Ditolak', () => _setStatus('Ditolak'), isHighContrast)),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadApplications,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_isLoading)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 60),
                            child: CircularProgressIndicator(color: buttonColor),
                          ),
                        )
                      else if (_filteredApplications.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 60),
                            child: Text(
                              'Belum ada lamaran ${_selectedStatus.toLowerCase()}',
                              style: TextStyle(
                                color: isHighContrast ? Colors.white70 : theme.textTheme.bodyMedium?.color?.withOpacity(0.6) ?? AppColors.textGray,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        )
                      else
                        ..._filteredApplications.map((application) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 20),
                            child: _ApplicationCard(
                              title: application['job_title']?.toString() ?? '-',
                              company: application['company_name']?.toString() ?? '-',
                              statusLabel: _statusToFilter(application['status']?.toString()),
                              dateText: _formatDate(application['created_at']),
                              jobPhoto: application['job_photo']?.toString(),
                              isHighContrast: isHighContrast,
                            ),
                          );
                        }),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _setStatus(String status) {
    setState(() => _selectedStatus = status);
  }
}

class _StatusButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isHighContrast;

  const _StatusButton(this.label, this.isSelected, this.onTap, this.isHighContrast);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedBgColor = isHighContrast ? AccessibilityTheme.yellow : theme.colorScheme.primary;
    final selectedTextColor = isHighContrast ? AccessibilityTheme.black : (theme.brightness == Brightness.dark ? Colors.black : Colors.white);
    final unselectedBgColor = isHighContrast ? AccessibilityTheme.black : theme.scaffoldBackgroundColor;
    final unselectedBorderColor = isHighContrast ? AccessibilityTheme.yellow : theme.colorScheme.primary;
    final unselectedTextColor = isHighContrast ? AccessibilityTheme.yellow : theme.colorScheme.primary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? selectedBgColor : unselectedBgColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: unselectedBorderColor, width: 1.2),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? selectedTextColor : unselectedTextColor,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _ApplicationCard extends StatelessWidget {
  final String title;
  final String company;
  final String statusLabel;
  final String dateText;
  final String? jobPhoto;
  final bool isHighContrast;

  const _ApplicationCard({
    required this.title,
    required this.company,
    required this.statusLabel,
    required this.dateText,
    this.jobPhoto,
    required this.isHighContrast,
  });

  IconData _getIcon() {
    final lower = title.toLowerCase();
    if (lower.contains('admin')) return Icons.desktop_windows_rounded;
    if (lower.contains('writer') || lower.contains('content')) return Icons.edit_rounded;
    return Icons.headset_mic_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = isHighContrast ? AccessibilityTheme.darkCard : (theme.brightness == Brightness.dark ? Colors.black : Colors.white);
    final textColor = isHighContrast ? AccessibilityTheme.yellow : theme.textTheme.titleLarge?.color;
    final subtextColor = isHighContrast ? Colors.white70 : theme.textTheme.bodyMedium?.color?.withOpacity(0.7);
    final iconBgColor = isHighContrast ? AccessibilityTheme.yellow.withOpacity(0.2) : theme.colorScheme.primary.withOpacity(0.1);
    final iconColor = isHighContrast ? AccessibilityTheme.yellow : theme.colorScheme.primary;
    final borderColor = isHighContrast ? AccessibilityTheme.yellow.withOpacity(0.3) : null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(18),
        border: isHighContrast ? Border.all(color: AccessibilityTheme.yellow, width: 1) : null,
        boxShadow: isHighContrast ? [] : [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(12),
              image: jobPhoto != null
                  ? DecorationImage(
                      image: MemoryImage(base64Decode(jobPhoto!)),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: jobPhoto == null
                ? Icon(_getIcon(), color: iconColor, size: 28)
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
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  company,
                  style: TextStyle(
                    fontSize: 14,
                    color: subtextColor,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatusBadge(statusLabel, theme, isHighContrast),
                    Text(
                      dateText,
                      style: TextStyle(
                        fontSize: 12,
                        color: isHighContrast ? Colors.white54 : theme.textTheme.bodySmall?.color,
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

  Widget _buildStatusBadge(String status, ThemeData theme, bool isHighContrast) {
    Color bgColor;
    Color textColor;

    if (isHighContrast) {
      switch (status) {
        case 'Selesai':
          bgColor = Colors.green.withOpacity(0.3);
          textColor = Colors.green;
          break;
        case 'Diproses':
          bgColor = Colors.orange.withOpacity(0.3);
          textColor = Colors.orange;
          break;
        case 'Ditolak':
          bgColor = Colors.red.withOpacity(0.3);
          textColor = Colors.red;
          break;
        case 'Dikirim':
        default:
          bgColor = AccessibilityTheme.yellow.withOpacity(0.2);
          textColor = AccessibilityTheme.yellow;
      }
    } else {
      switch (status) {
        case 'Selesai':
          bgColor = const Color(0xFFD4F0DD);
          textColor = const Color(0xFF18A64A);
          break;
        case 'Diproses':
          bgColor = const Color(0xFFFFE4B8);
          textColor = const Color(0xFFF59E0B);
          break;
        case 'Ditolak':
          bgColor = const Color(0xFFFFDADA);
          textColor = const Color(0xFFE53935);
          break;
        case 'Dikirim':
        default:
          bgColor = theme.colorScheme.primary.withOpacity(0.1);
          textColor = theme.colorScheme.primary;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 12,
          color: textColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

