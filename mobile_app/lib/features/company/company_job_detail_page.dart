import 'package:flutter/material.dart';
import 'company_edit_job_page.dart';
import 'company_job_applicants_page.dart';
import '../../services/mongo_service.dart';
import 'dart:convert';

class CompanyJobDetailPage extends StatelessWidget {
  final Map<String, dynamic> job;
  final int applicantCount;
  final int processedCount;
  final int acceptedCount;

  const CompanyJobDetailPage({
    super.key,
    required this.job,
    required this.applicantCount,
    required this.processedCount,
    required this.acceptedCount,
  });

  static const Color navy = Color(0xFF0D1B55);
  static const Color textGrey = Color(0xFF4A5870);
  static const Color lightGrey = Color(0xFFE7E7E7);
  static const Color activeGreenBg = Color(0xFFD4F0DD);
  static const Color activeGreenText = Color(0xFF18A64A);
  static const Color inactiveRedBg = Color(0xFFF8D1D3);
  static const Color inactiveRedText = Color(0xFFE2262C);
  static const Color blueChip = Color(0xFF91B4FF);

  bool get isJobActive {
    final status = job['status']?.toString().toLowerCase() ?? '';
    return status == 'active';
  }

  void _showStatusDialog(BuildContext context) {
    final nextStatus = isJobActive ? 'inactive' : 'active';
    final actionText = isJobActive ? 'Nonaktifkan' : 'Aktifkan';
    final titleText =
        isJobActive ? 'Nonaktifkan Lowongan' : 'Aktifkan Lowongan';
    final messageText = isJobActive
        ? 'Apakah anda yakin\nmenonaktifkan lowongan?'
        : 'Apakah anda yakin\nmengaktifkan lowongan?';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(dialogContext),
                    child: const Icon(
                      Icons.close,
                      size: 30,
                      color: navy,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Icon(
                  isJobActive ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  size: 110,
                  color: isJobActive ? Colors.red : activeGreenText,
                ),
                const SizedBox(height: 14),
                Text(
                  titleText,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: navy,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  messageText,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade300,
                          foregroundColor: navy,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: const Text(
                          'Batal',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 6,
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () async {
                          final jobId = MongoService.getMongoId(job['_id']);

                          final success = await MongoService.updateJobStatus(
                            jobId: jobId,
                            status: nextStatus,
                          );

                          if (!dialogContext.mounted) return;

                          Navigator.pop(dialogContext);

                          if (success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  isJobActive
                                      ? 'Lowongan berhasil dinonaktifkan'
                                      : 'Lowongan berhasil diaktifkan',
                                ),
                              ),
                            );

                            Navigator.pop(context, true);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Gagal mengubah status lowongan'),
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isJobActive ? Colors.red : activeGreenText,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            actionText,
                            maxLines: 1,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              ],
            ),
          ),
        );
      },
    );
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

  String _statusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return 'Aktif';
      case 'inactive':
        return 'Nonaktif';
      default:
        return status;
    }
  }

  bool _isActive(String status) {
    return status.toLowerCase() == 'active';
  }

  IconData _getJobIcon(String title) {
    final lowerTitle = title.toLowerCase();

    if (lowerTitle.contains('customer')) return Icons.headset_mic_rounded;
    if (lowerTitle.contains('admin')) return Icons.desktop_windows_rounded;
    if (lowerTitle.contains('writer')) return Icons.edit_document;
    if (lowerTitle.contains('developer') || lowerTitle.contains('programmer')) {
      return Icons.code_rounded;
    }

    return Icons.business_center_rounded;
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

  @override
  Widget build(BuildContext context) {
    final title = job['title']?.toString() ?? '-';
    final companyName = job['company_name']?.toString() ?? '-';
    final location = job['location']?.toString() ?? '-';
    final jobType = job['job_type']?.toString() ?? '-';
    final status = job['status']?.toString() ?? '-';
    final description = job['description']?.toString() ?? '-';
    final qualifications = _toStringList(job['qualification']);
    final facilities = _toStringList(job['facilities']);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 28),
          children: [
            _buildHeader(context),
            const SizedBox(height: 22),
            _buildMainInfoCard(
              title: title,
              companyName: companyName,
              location: location,
              jobType: jobType,
              status: status,
            ),
            const SizedBox(height: 18),
            _buildDescriptionCard(description),
            const SizedBox(height: 18),
            _buildQualificationCard(qualifications),
            const SizedBox(height: 18),
            _buildFacilitiesCard(facilities),
            const SizedBox(height: 22),
            _buildPrimaryButton(
              icon: Icons.groups_outlined,
              text: 'Lihat Pelamar ($applicantCount)',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CompanyJobApplicantsPage(job: job),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            _buildOutlineButton(
              icon: Icons.edit_outlined,
              text: 'Edit Lowongan',
              color: navy,
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CompanyEditJobPage(job: job),
                  ),
                );

                if (result == true && context.mounted) {
                  Navigator.pop(context, true);
                }
              },
            ),
            const SizedBox(height: 12),
            _buildOutlineButton(
              icon: isJobActive ? Icons.pause_rounded : Icons.play_arrow_rounded,
              text: isJobActive ? 'Nonaktifkan Lowongan' : 'Aktifkan Lowongan',
              color: isJobActive ? Colors.red : activeGreenText,
              onTap: () => _showStatusDialog(context),
            ),
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
          child: const Icon(Icons.arrow_back, size: 34, color: navy),
        ),
        const SizedBox(width: 18),
        const Text(
          'Detail Lowongan',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: navy,
          ),
        ),
      ],
    );
  }

  Widget _buildMainInfoCard({
    required String title,
    required String companyName,
    required String location,
    required String jobType,
    required String status,
  }) {
    final String? jobPhoto = job['job_photo'];

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: lightGrey,
                  borderRadius: BorderRadius.circular(12),
                  image: jobPhoto != null
                      ? DecorationImage(
                          image: MemoryImage(base64Decode(jobPhoto)),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: jobPhoto == null
                    ? Icon(
                        _getJobIcon(title),
                        size: 38,
                        color: navy,
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: navy,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      companyName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: textGrey,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _infoLine(Icons.location_on_rounded, location),
                    const SizedBox(height: 8),
                    _infoLine(Icons.business_center_rounded, jobType),
                    const SizedBox(height: 8),
                    _infoLine(
                      Icons.calendar_month_rounded,
                      'Dipublikasikan ${_formatDate(job['created_at'])}',
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _statusBadge(status),
            ],
          ),
          const SizedBox(height: 18),
          Divider(color: Colors.grey.shade300, height: 1),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(
                width: 92,
                child: _statItem(
                  icon: Icons.person_rounded,
                  iconBg: const Color(0xFFCFE0FF),
                  iconColor: const Color(0xFF2267F2),
                  value: applicantCount.toString(),
                  label: 'Pelamar',
                ),
              ),
              SizedBox(
                width: 92,
                child: _statItem(
                  icon: Icons.hourglass_bottom_rounded,
                  iconBg: const Color(0xFFFFE4B8),
                  iconColor: const Color(0xFFF59E0B),
                  value: processedCount.toString(),
                  label: 'Diproses',
                ),
              ),
              SizedBox(
                width: 92,
                child: _statItem(
                  icon: Icons.check_rounded,
                  iconBg: activeGreenBg,
                  iconColor: activeGreenText,
                  value: acceptedCount.toString(),
                  label: 'Lolos',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoLine(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: textGrey),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.visible,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: textGrey,
            ),
          ),
        ),
      ],
    );
  }

  Widget _statusBadge(String status) {
    final active = _isActive(status);

    return Container(
      width: 82,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: active ? activeGreenBg : inactiveRedBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _statusLabel(status),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w900,
          color: active ? activeGreenText : inactiveRedText,
        ),
      ),
    );
  }

  Widget _statItem({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(7),
          ),
          child: Icon(icon, size: 24, color: iconColor),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: navy,
                height: 1,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: textGrey,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDescriptionCard(String description) {
    return _sectionCard(
      title: 'Deskripsi Pekerjaan',
      child: Text(
        description,
        style: const TextStyle(
          fontSize: 14,
          height: 1.35,
          fontWeight: FontWeight.w400,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildQualificationCard(List<String> qualifications) {
    final data = qualifications.isEmpty
        ? ['Kualifikasi pekerjaan belum tersedia.']
        : qualifications;

    return _sectionCard(
      title: 'Kualifikasi Pekerjaan',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: data.map((item) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              '• $item',
              style: const TextStyle(
                fontSize: 14,
                height: 1.25,
                color: Colors.black87,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFacilitiesCard(List<String> facilities) {
    final data = facilities.isEmpty ? ['Aksesibilitas'] : facilities;

    return _sectionCard(
      title: 'Fasilitas',
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: data.map((item) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              color: blueChip,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              item,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: navy,
              ),
            ),
          );
        }).toList(),
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
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  Widget _buildPrimaryButton({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      height: 52,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 24),
        label: Text(text),
        style: ElevatedButton.styleFrom(
          backgroundColor: navy,
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

  Widget _buildOutlineButton({
    required IconData icon,
    required String text,
    required Color color,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      height: 52,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 24, color: color),
        label: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            text,
            maxLines: 1,
          ),
        ),
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
      borderRadius: BorderRadius.circular(24),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.18),
          blurRadius: 13,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }
}