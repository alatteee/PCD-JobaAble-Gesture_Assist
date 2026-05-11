import 'package:flutter/material.dart';
import 'dart:convert';
import '../../core/constants/app_colors.dart';
import '../../services/mongo_service.dart';

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(child: _StatusButton('Dikirim', _selectedStatus == 'Dikirim', () => _setStatus('Dikirim'))),
                  const SizedBox(width: 26),
                  Expanded(child: _StatusButton('Diproses', _selectedStatus == 'Diproses', () => _setStatus('Diproses'))),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _StatusButton('Selesai', _selectedStatus == 'Selesai', () => _setStatus('Selesai'))),
                  const SizedBox(width: 26),
                  Expanded(child: _StatusButton('Ditolak', _selectedStatus == 'Ditolak', () => _setStatus('Ditolak'))),
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
                        child: CircularProgressIndicator(color: theme.colorScheme.primary),
                      ),
                    )
                  else if (_filteredApplications.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 60),
                        child: Text(
                          'Belum ada lamaran ${_selectedStatus.toLowerCase()}',
                          style: TextStyle(
                            color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6) ?? AppColors.textGray,
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
                          jobPhoto: application['job_photo']?.toString(), // Tambahkan ini
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
  }

  void _setStatus(String status) {
    setState(() => _selectedStatus = status);
  }
}

class _StatusButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _StatusButton(this.label, this.isSelected, this.onTap);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary : theme.scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: theme.colorScheme.primary, width: 1.2),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? (theme.brightness == Brightness.dark ? Colors.black : Colors.white) : theme.colorScheme.primary,
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
  final String? jobPhoto; // Tambahkan ini

  const _ApplicationCard({
    required this.title,
    required this.company,
    required this.statusLabel,
    required this.dateText,
    this.jobPhoto, // Tambahkan ini
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark ? Colors.black : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: theme.brightness == Brightness.dark ? Border.all(color: Colors.yellow, width: 1) : null,
        boxShadow: theme.brightness == Brightness.dark ? [] : [
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
            width: 52, // Atur ukuran tetap
            height: 52,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              image: jobPhoto != null
                  ? DecorationImage(
                      image: MemoryImage(base64Decode(jobPhoto!)),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: jobPhoto == null
                ? Icon(_getIcon(), color: theme.colorScheme.primary, size: 28)
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
                    color: theme.textTheme.titleLarge?.color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  company,
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatusBadge(statusLabel, theme),
                    Text(
                      dateText,
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.textTheme.bodySmall?.color,
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

  Widget _buildStatusBadge(String status, ThemeData theme) {
    Color bgColor;
    Color textColor;

    switch (status) {
      case 'Selesai':
        bgColor = const Color(0xFFD4F0DD); // Light Green
        textColor = const Color(0xFF18A64A); // Success Green
        break;
      case 'Diproses':
        bgColor = const Color(0xFFFFE4B8); // Light Orange
        textColor = const Color(0xFFF59E0B); // Middle Orange
        break;
      case 'Ditolak':
        bgColor = const Color(0xFFFFDADA); // Light Red
        textColor = const Color(0xFFE53935); // Error Red
        break;
      case 'Dikirim':
      default:
        bgColor = theme.colorScheme.primary.withOpacity(0.1);
        textColor = theme.colorScheme.primary;
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

