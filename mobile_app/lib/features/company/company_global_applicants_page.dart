import 'package:flutter/material.dart';

import '../../services/mongo_service.dart';
import 'company_applicant_detail_page.dart';

class CompanyGlobalApplicantsPage extends StatefulWidget {
  final List<Map<String, dynamic>> applicants;
  final List<Map<String, dynamic>> jobs;

  const CompanyGlobalApplicantsPage({
    super.key,
    required this.applicants,
    required this.jobs,
  });

  @override
  State<CompanyGlobalApplicantsPage> createState() =>
      _CompanyGlobalApplicantsPageState();
}

class _CompanyGlobalApplicantsPageState
    extends State<CompanyGlobalApplicantsPage> {
  static const Color navy = Color(0xFF0D1B55);
  static const Color textGrey = Color(0xFF4A5870);
  static const Color lightBlue = Color(0xFFEAF0FF);

  static const Color activeGreenBg = Color(0xFFD4F0DD);
  static const Color activeGreenText = Color(0xFF18A64A);
  static const Color orangeBg = Color(0xFFFFE4B8);
  static const Color orangeText = Color(0xFFF59E0B);
  static const Color redBg = Color(0xFFF8D1D3);
  static const Color redText = Color(0xFFE2262C);
  static const Color greyBg = Color(0xFFE5E5E5);
  static const Color greyText = Color(0xFF5B6472);

  String selectedFilter = 'Semua';
  String searchQuery = '';

  final TextEditingController _searchController = TextEditingController();

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

  Color _statusBg(String status) {
    final normalized = _normalizeStatus(status);

    if (normalized == 'dikirim') return greyBg;
    if (normalized == 'ditinjau') return orangeBg;
    if (normalized == 'wawancara') return lightBlue;
    if (normalized == 'diterima') return activeGreenBg;
    if (normalized == 'ditolak') return redBg;

    return greyBg;
  }

  Color _statusText(String status) {
    final normalized = _normalizeStatus(status);

    if (normalized == 'dikirim') return greyText;
    if (normalized == 'ditinjau') return orangeText;
    if (normalized == 'wawancara') return navy;
    if (normalized == 'diterima') return activeGreenText;
    if (normalized == 'ditolak') return redText;

    return greyText;
  }

  List<Map<String, dynamic>> get filteredApplicants {
    return widget.applicants.where((applicant) {
      final name = applicant['full_name']?.toString().toLowerCase() ?? '';
      final jobTitle = applicant['job_title']?.toString().toLowerCase() ?? '';
      final status = applicant['status']?.toString().toLowerCase() ?? '';
      final query = searchQuery.toLowerCase();

      final matchSearch = name.contains(query) || jobTitle.contains(query);

      final normalizedStatus = _normalizeStatus(status);

      final matchFilter = selectedFilter == 'Semua' ||
          selectedFilter.toLowerCase() == normalizedStatus;

      return matchSearch && matchFilter;
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Map<String, dynamic> _findJobByApplicant(Map<String, dynamic> applicant) {
    final applicantJobId = applicant['job_id']?.toString() ?? '';

    return widget.jobs.firstWhere(
      (job) => MongoService.getMongoId(job['_id']) == applicantJobId,
      orElse: () => {
        'title': applicant['job_title'] ?? '-',
        'company_name': applicant['company_name'] ?? '-',
        'location': applicant['location'] ?? '-',
      },
    );
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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),

          const SizedBox(height: 24),

          _buildSearchBox(),

          const SizedBox(height: 18),

          _buildFilterButtons(),

          const SizedBox(height: 24),

          Expanded(
            child: filteredApplicants.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 24),
                    itemCount: filteredApplicants.length,
                    itemBuilder: (context, index) {
                      return _buildApplicantCard(filteredApplicants[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return const Row(
      children: [
        Text(
          'Pelamar',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: navy,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBox() {
    return Container(
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Center(
        child: TextField(
          controller: _searchController,
          onChanged: (value) => setState(() => searchQuery = value),
          textAlignVertical: TextAlignVertical.center,
          style: const TextStyle(
            fontSize: 14,
            color: navy,
            fontWeight: FontWeight.w500,
          ),
          decoration: const InputDecoration(
            prefixIcon: Icon(
              Icons.search_rounded,
              size: 28,
              color: Colors.black54,
            ),
            hintText: 'Cari Pelamar...',
            hintStyle: TextStyle(
              fontSize: 14,
              color: Colors.black45,
              fontWeight: FontWeight.w500,
            ),
            border: InputBorder.none,
            isDense: true,
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterButtons() {
    final filters = [
      'Semua',
      'Dikirim',
      'Ditinjau',
      'Wawancara',
      'Diterima',
      'Ditolak',
    ];

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = selectedFilter == filter;

          return GestureDetector(
            onTap: () => setState(() => selectedFilter = filter),
            child: Container(
              constraints: const BoxConstraints(minWidth: 96),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? navy : Colors.white,
                borderRadius: BorderRadius.circular(13),
                border: Border.all(
                  color: navy,
                  width: 1.3,
                ),
              ),
              child: Text(
                filter,
                maxLines: 1,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w900,
                  color: isSelected ? Colors.white : navy,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildApplicantCard(Map<String, dynamic> applicant) {
    final job = _findJobByApplicant(applicant);

    final name = applicant['full_name']?.toString() ?? 'Pelamar';
    final jobTitle =
        applicant['job_title']?.toString() ?? job['title']?.toString() ?? '-';
    final status = applicant['status']?.toString() ?? 'dikirim';
    final date = _formatDate(applicant['created_at']);

    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CompanyApplicantDetailPage(
              applicant: applicant,
              job: job,
            ),
          ),
        );

        if (result is String && mounted) {
          setState(() {
            applicant['status'] = result;
          });
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 18),
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.14),
              blurRadius: 14,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
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
            ),

            const SizedBox(width: 18),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
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
                    jobTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.black38,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  date,
                  style: const TextStyle(
                    fontSize: 12,
                    color: textGrey,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 10),

                Container(
                  width: 92,
                  height: 30,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _statusBg(status),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    _statusLabel(status),
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w900,
                      color: _statusText(status),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      children: const [
        SizedBox(height: 100),
        Icon(
          Icons.groups_outlined,
          size: 64,
          color: textGrey,
        ),
        SizedBox(height: 16),
        Center(
          child: Text(
            'Belum ada pelamar',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: navy,
            ),
          ),
        ),
      ],
    );
  }
}