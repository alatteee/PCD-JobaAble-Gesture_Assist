import 'package:flutter/material.dart';
import '../../services/mongo_service.dart';
import 'company_job_detail_page.dart';
import 'dart:convert';

class CompanyJobPage extends StatefulWidget {
  final String companyId;

  const CompanyJobPage({
    super.key,
    required this.companyId,
  });

  @override
  State<CompanyJobPage> createState() => _CompanyJobPageState();
}

class _CompanyJobPageState extends State<CompanyJobPage> {
  static const Color navy = Color(0xFF0D1B55);
  static const Color textGrey = Color(0xFF4A5870);
  static const Color lightGrey = Color(0xFFE7E7E7);
  static const Color activeGreenBg = Color(0xFFD4F0DD);
  static const Color activeGreenText = Color(0xFF18A64A);
  static const Color inactiveRedBg = Color(0xFFF8D1D3);
  static const Color inactiveRedText = Color(0xFFE2262C);

  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> jobs = [];
  List<Map<String, dynamic>> applicants = [];

  bool isLoading = true;
  String selectedFilter = 'Semua';
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadJobs();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadJobs() async {
    setState(() => isLoading = true);

    final jobsData =
        await MongoService.getCompanyJobs(companyId: widget.companyId);
    final applicantsData =
        await MongoService.getCompanyApplicants(companyId: widget.companyId);

    if (!mounted) return;

    setState(() {
      jobs = jobsData;
      applicants = applicantsData;
      isLoading = false;
    });
  }

  List<Map<String, dynamic>> get filteredJobs {
    return jobs.where((job) {
      final title = job['title']?.toString().toLowerCase() ?? '';
      final location = job['location']?.toString().toLowerCase() ?? '';
      final status = job['status']?.toString().toLowerCase() ?? '';
      final query = searchQuery.toLowerCase();

      final matchSearch = title.contains(query) || location.contains(query);

      final matchFilter = selectedFilter == 'Semua' ||
          (selectedFilter == 'Aktif' && status == 'active') ||
          (selectedFilter == 'Nonaktif' && status == 'inactive');

      return matchSearch && matchFilter;
    }).toList();
  }

  int _getApplicantCount(String jobId) {
    if (jobId.isEmpty) return 0;
    return applicants.where((app) {
      final appJobId = MongoService.getMongoId(app['job_id']);
      return appJobId == jobId;
    }).length;
  }

  int _getProcessedCount(String jobId) {
    if (jobId.isEmpty) return 0;
    return applicants.where((app) {
      final appJobId = MongoService.getMongoId(app['job_id']);
      final sameJob = appJobId == jobId;
      final status = app['status']?.toString().toLowerCase() ?? '';
      return sameJob && (status == 'pending' || status == 'reviewed' || status == 'diproses' || status == 'ditinjau');
    }).length;
  }

  int _getAcceptedCount(String jobId) {
    if (jobId.isEmpty) return 0;
    return applicants.where((app) {
      final appJobId = MongoService.getMongoId(app['job_id']);
      final sameJob = appJobId == jobId;
      final status = app['status']?.toString().toLowerCase() ?? '';
      return sameJob && (status == 'accepted' || status == 'diterima' || status == 'lolos');
    }).length;
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

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadJobs,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTopBar(context),
            const SizedBox(height: 24),
            _buildSearchBox(),
            const SizedBox(height: 20),
            _buildFilterButtons(),
            const SizedBox(height: 24),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filteredJobs.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.only(bottom: 24),
                          itemCount: filteredJobs.length,
                          itemBuilder: (context, index) {
                            final job = filteredJobs[index];
                            final jobId = MongoService.getMongoId(job['_id']);

                            return _buildJobCard(
                              job: job,
                              applicantCount: _getApplicantCount(jobId),
                              processedCount: _getProcessedCount(jobId),
                              acceptedCount: _getAcceptedCount(jobId),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return const Row(
      children: [
        Text(
          'Lowongan Saya',
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.13),
            blurRadius: 7,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => searchQuery = value),
        style: const TextStyle(
          fontSize: 14,
          color: navy,
          fontWeight: FontWeight.w500,
        ),
        decoration: const InputDecoration(
          prefixIcon: Padding(
            padding: EdgeInsets.only(left: 16, right: 8),
            child: Icon(
              Icons.search_rounded,
              size: 28,
              color: textGrey,
            ),
          ),
          hintText: 'Cari Lowongan Pekerjaan...',
          hintStyle: TextStyle(
            fontSize: 14,
            color: textGrey,
            fontWeight: FontWeight.w500,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 17),
        ),
      ),
    );
  }

  Widget _buildFilterButtons() {
    final filters = ['Semua', 'Aktif', 'Nonaktif'];

    return Row(
      children: filters.map((filter) {
        final isSelected = selectedFilter == filter;

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: filter == 'Nonaktif' ? 0 : 12,
            ),
            child: GestureDetector(
              onTap: () => setState(() => selectedFilter = filter),
              child: Container(
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? navy : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: navy,
                    width: 1.4,
                  ),
                ),
                child: Text(
                  filter,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: isSelected ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildJobCard({
    required Map<String, dynamic> job,
    required int applicantCount,
    required int processedCount,
    required int acceptedCount,
  }) {
    final title = job['title']?.toString() ?? '-';
    final location = job['location']?.toString() ?? '-';
    final jobType = job['job_type']?.toString() ?? '-';
    final status = job['status']?.toString() ?? '-';
    final String? jobPhoto = job['job_photo'];

    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CompanyJobDetailPage(
              job: job,
              applicantCount: applicantCount,
              processedCount: processedCount,
              acceptedCount: acceptedCount,
            ),
          ),
        );

        if (result == true) {
          _loadJobs(); // 🔥 refresh data setelah edit
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
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
                  child: Padding(
                    padding: const EdgeInsets.only(top: 2),
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
                          'Dipublikasikan ${_formatDate(job['created_at'])}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: textGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _buildStatusBadge(status),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    icon: Icons.person_rounded,
                    text: '$applicantCount pelamar',
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    icon: Icons.location_on_rounded,
                    text: location,
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    icon: Icons.business_center_rounded,
                    text: jobType,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
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

  Widget _buildInfoItem({
    required IconData icon,
    required String text,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: textGrey),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: textGrey,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: const [
        SizedBox(height: 100),
        Icon(Icons.work_off_outlined, size: 60, color: textGrey),
        SizedBox(height: 16),
        Center(
          child: Text(
            'Belum ada lowongan',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: navy,
            ),
          ),
        ),
        SizedBox(height: 8),
        Center(
          child: Text(
            'Lowongan yang dibuat perusahaan akan tampil di sini.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: textGrey),
          ),
        ),
      ],
    );
  }
}