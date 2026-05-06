import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../services/mongo_service.dart';
import 'company_job_page.dart';
import 'company_global_applicants_page.dart';
import 'company_create_job_page.dart';
import 'company_profile_page.dart';
import '../notifications/notification_page.dart';

class CompanyHomePage extends StatefulWidget {
  final Map<String, dynamic> userData;
  final bool showSuccessDialog;

  const CompanyHomePage({
    super.key,
    required this.userData,
    this.showSuccessDialog = false,
  });

  static const Color navy = AppColors.primaryNavy;
  static const Color blue = Color(0xFF2C4494);
  static const Color lightBlue = Color(0xFFEAF0FF);
  static const Color lightOrange = Color(0xFFFFE9C9);
  static const Color lightGreen = Color(0xFFDDF3E4);
  static const Color skyBlue = Color(0xFF48BEEF);

  @override
  State<CompanyHomePage> createState() => _CompanyHomePageState();
}

class _CompanyHomePageState extends State<CompanyHomePage> {
  Map<String, dynamic>? company;
  List<Map<String, dynamic>> companyJobs = [];
  List<Map<String, dynamic>> applicants = [];
  bool isLoading = true;

  int _selectedIndex = 0;

  Color get blue => CompanyHomePage.blue;
  Color get lightBlue => CompanyHomePage.lightBlue;
  Color get lightOrange => CompanyHomePage.lightOrange;
  Color get lightGreen => CompanyHomePage.lightGreen;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      isLoading = true;
    });

    // Get userId from userData
    final userId = widget.userData['_id'];
    
    if (userId == null) {
      if (!mounted) return;
      setState(() {
        company = null;
        companyJobs = [];
        applicants = [];
        isLoading = false;
      });
      return;
    }

    // Fetch company using user_id
    final companyData = await MongoService.getCompanyByUserId(userId);

    if (companyData == null) {
      if (!mounted) return;
      setState(() {
        company = null;
        companyJobs = [];
        applicants = [];
        isLoading = false;
      });
      return;
    }

    final companyId = MongoService.getMongoId(companyData['_id']);
    final jobsData = await MongoService.getCompanyJobs(companyId: companyId);
    final applicantsData =
        await MongoService.getCompanyApplicants(companyId: companyId);

    if (!mounted) return;

    setState(() {
      company = companyData;
      companyJobs = jobsData;
      applicants = applicantsData;
      isLoading = false;
    });
  }

  String _getCompanyName() {
    return widget.userData['company_name']?.toString() ??
        widget.userData['companyName']?.toString() ??
        widget.userData['name']?.toString() ??
        'PT Maju Bersama';
  }

  String _formatDate(dynamic value) {
    if (value == null) return '-';

    DateTime? date;
    if (value is DateTime) {
      date = value;
    } else {
      date = DateTime.tryParse(value.toString());
    }

    if (date == null) return value.toString();

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

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty || name.trim().isEmpty) return '?';

    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }

    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  int get activeJobCount {
    return companyJobs.where((job) => job['status'] == 'active').length;
  }

  int get completedApplicantCount {
    return applicants.where((app) {
      final status = app['status']?.toString().toLowerCase() ?? '';
      return status == 'accepted' || status == 'diterima' || status == 'selesai';
    }).length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: _buildBottomNav(),
      body: SafeArea(
        child: _getCurrentPage(),
      ),
    );
  }

  Widget _getCurrentPage() {
    switch (_selectedIndex) {
      case 0:
        return _buildDashboardContent();
      case 1:
        if (company == null) {
          return _buildPlaceholderPage(
            title: 'Lowongan Saya',
            icon: Icons.business_center_outlined,
          );
        }

        return CompanyJobPage(
          companyId: MongoService.getMongoId(company!['_id']),
        );
      case 2:
        return CompanyGlobalApplicantsPage(
          applicants: applicants,
          jobs: companyJobs,
        );
      case 3:
        return CompanyProfilePage(
          companyName: company?['company_name']?.toString() ?? _getCompanyName(),
          userData: widget.userData,
        );
      default:
        return _buildDashboardContent();
    }
  }

  Widget _buildDashboardContent() {
    final companyName = company?['company_name']?.toString() ?? _getCompanyName();

    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 26),
            Text(
              'Halo, $companyName. Selamat Pagi!',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: CompanyHomePage.navy,
              ),
            ),
            const SizedBox(height: 24),
            _buildCreateJobCard(),
            const SizedBox(height: 32),
            _sectionTitle('Ringkasan'),
            const SizedBox(height: 16),
            _buildSummarySection(),
            const SizedBox(height: 34),
            _sectionHeader(
              'Lowongan Aktif',
              onSeeAll: () => setState(() => _selectedIndex = 1),
            ),
            const SizedBox(height: 16),
            _buildJobSection(),
            const SizedBox(height: 34),
            _sectionHeader(
              'Pelamar Terbaru',
              onSeeAll: () => setState(() => _selectedIndex = 2),
            ),
            const SizedBox(height: 16),
            _buildApplicantSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderPage({
    required String title,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 36),
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 56,
                    color: CompanyHomePage.navy,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: CompanyHomePage.navy,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Halaman ini akan dikembangkan selanjutnya.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.blueGrey.shade600,
                      fontWeight: FontWeight.w500,
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

  Widget _buildSummarySection() {
    if (isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            value: activeJobCount.toString(),
            label: 'Lowongan Aktif',
            color: lightBlue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryCard(
            value: applicants.length.toString(),
            label: 'Pelamar Masuk',
            color: lightOrange,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryCard(
            value: completedApplicantCount.toString(),
            label: 'Selesai',
            color: lightGreen,
          ),
        ),
      ],
    );
  }

  Widget _buildJobSection() {
    if (isLoading) return _buildLoadingCard();

    if (companyJobs.isEmpty) {
      return _buildEmptyCard('Belum ada lowongan aktif');
    }

    final latestJobs = companyJobs.take(2).toList();

    return Column(
      children: latestJobs.map((job) {
        final jobId = MongoService.getMongoId(job['_id']);
        final jobApplicants = applicants.where((app) {
          final appJobId = MongoService.getMongoId(app['job_id']);
          return appJobId == jobId;
        }).length;

        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: _buildJobCard(
            title: job['title']?.toString() ?? '-',
            date: _formatDate(job['created_at']),
            applicantCount: jobApplicants,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildApplicantSection() {
    if (isLoading) return _buildLoadingCard();

    if (applicants.isEmpty) {
      return _buildEmptyCard('Belum ada pelamar');
    }

    final latestApplicants = applicants.take(2).toList();

    return Column(
      children: latestApplicants.map((applicant) {
        final name = applicant['full_name']?.toString() ?? 'Pelamar';
        return _buildApplicantCard(
          initials: _getInitials(name),
          name: name,
          jobTitle: applicant['job_title']?.toString() ?? '-',
          date: _formatDate(applicant['created_at']),
          status: applicant['status']?.toString() ?? 'pending',
        );
      }).toList(),
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildEmptyCard(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 14,
          color: Colors.blueGrey.shade700,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final companyUserId = widget.userData['_id'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        RichText(
          text: const TextSpan(
            children: [
              TextSpan(
                text: 'Job',
                style: TextStyle(
                  fontSize: 38,
                  fontWeight: FontWeight.w900,
                  color: CompanyHomePage.navy,
                ),
              ),
              TextSpan(
                text: 'Able',
                style: TextStyle(
                  fontSize: 38,
                  fontWeight: FontWeight.w900,
                  color: CompanyHomePage.skyBlue,
                ),
              ),
            ],
          ),
        ),
        if (companyUserId != null)
          FutureBuilder<int>(
            future: MongoService.getUnreadNotificationCount(
              receiverId: companyUserId,
              receiverRole: 'company',
            ),
            builder: (context, snapshot) {
              final unreadCount = snapshot.data ?? 0;
              final hasUnread = unreadCount > 0;
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => NotificationPage(
                            currentUser: widget.userData,
                            role: 'company',
                          ),
                        ),
                      );
                      _loadDashboardData(); // Refresh unread count
                    },
                    icon: const Icon(
                      Icons.notifications,
                      color: CompanyHomePage.navy,
                      size: 32,
                    ),
                  ),
                  if (hasUnread)
                    Positioned(
                      right: 8,
                      top: 12,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Text(
                          '$unreadCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
      ],
    );
  }

  Widget _buildCreateJobCard() {
    return GestureDetector(
      onTap: () async {
        if (company == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Data perusahaan belum tersedia')),
          );
          return;
        }

        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CompanyCreateJobPage(
              companyId: MongoService.getMongoId(company!['_id']),
              companyName: company!['company_name']?.toString() ?? _getCompanyName(),
            ),
          ),
        );

        if (result == 'jobs') {
          setState(() => _selectedIndex = 1);
          await _loadDashboardData();
        } else if (result == 'home') {
          setState(() => _selectedIndex = 0);
          await _loadDashboardData();
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        decoration: BoxDecoration(
          color: blue,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.22),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 32,
              backgroundColor: Colors.white,
              child: Icon(
                Icons.add,
                size: 38,
                color: CompanyHomePage.blue,
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Buat Lowongan Baru',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Posting lowongan kerja sekarang',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w900,
        color: CompanyHomePage.navy,
      ),
    );
  }

  Widget _sectionHeader(String title, {VoidCallback? onSeeAll}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _sectionTitle(title),
        GestureDetector(
          onTap: onSeeAll,
          child: const Text(
            'Lihat semua',
            style: TextStyle(
              fontSize: 14,
              color: Colors.blue,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildJobCard({
    required String title,
    required String date,
    required int applicantCount,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
      decoration: _cardDecoration(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.headset_mic,
              size: 42,
              color: CompanyHomePage.navy,
            ),
          ),
          const SizedBox(width: 18),
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
                    color: CompanyHomePage.navy,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Dipublikasikan  $date',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.blueGrey.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Icon(
                      Icons.person,
                      size: 20,
                      color: CompanyHomePage.navy,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '$applicantCount pelamar',
                      style: const TextStyle(
                        fontSize: 13,
                        color: CompanyHomePage.navy,
                        fontWeight: FontWeight.w500,
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

  Widget _buildApplicantCard({
    required String initials,
    required String name,
    required String jobTitle,
    required String date,
    required String status,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: lightBlue,
            child: Text(
              initials,
              style: const TextStyle(
                color: CompanyHomePage.navy,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 14),
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
                    color: CompanyHomePage.navy,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  jobTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.blueGrey.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                date,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.blueGrey.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                decoration: BoxDecoration(
                  color: lightOrange,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  _statusLabel(status),
                  style: const TextStyle(
                    color: Colors.orange,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _statusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Diproses';
      case 'reviewed':
        return 'Ditinjau';
      case 'accepted':
        return 'Diterima';
      case 'rejected':
        return 'Ditolak';
      default:
        return status;
    }
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(28),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.16),
          blurRadius: 14,
          offset: const Offset(0, 7),
        ),
      ],
    );
  }

  Widget _buildBottomNav() {
    return Container(
      height: 82,
      decoration: const BoxDecoration(
        color: CompanyHomePage.navy,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _BottomItem(
            icon: Icons.home,
            label: 'Beranda',
            active: _selectedIndex == 0,
            onTap: () => setState(() => _selectedIndex = 0),
          ),
          _BottomItem(
            icon: Icons.business_center_outlined,
            label: 'Lowongan',
            active: _selectedIndex == 1,
            onTap: () async {
              setState(() => _selectedIndex = 1);
              await _loadDashboardData();
            },
          ),
          _BottomItem(
            icon: Icons.groups_outlined,
            label: 'Pelamar',
            active: _selectedIndex == 2,
            onTap: () async {
              setState(() => _selectedIndex = 2);
              await _loadDashboardData();
            },
          ),
          _BottomItem(
            icon: Icons.person_outline,
            label: 'Profil',
            active: _selectedIndex == 3,
            onTap: () => setState(() => _selectedIndex = 3),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _SummaryCard({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 102,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: CompanyHomePage.navy,
              height: 1,
            ),
          ),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              maxLines: 1,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: CompanyHomePage.navy,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _BottomItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        width: 78,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 26,
              color: active ? Colors.white : Colors.white.withOpacity(0.65),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: active ? Colors.white : Colors.white.withOpacity(0.65),
                fontSize: 12,
                fontWeight: active ? FontWeight.w900 : FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}