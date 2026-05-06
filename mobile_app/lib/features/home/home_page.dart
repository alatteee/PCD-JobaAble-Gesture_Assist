import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../services/mongo_service.dart';
import '../job_detail/job_detail_page.dart';
import '../applications/applications_page.dart';
import '../profile/profile_view.dart';
import '../profile/accessibility_settings_view.dart';

import '../notifications/notification_page.dart';
import '../cv/cv_view.dart';

class HomePage extends StatefulWidget {
  final Map<String, dynamic> userData;
  final bool showSuccessDialog;
  final int initialIndex;

  const HomePage({
    super.key,
    required this.userData,
    this.showSuccessDialog = false,
    this.initialIndex = 0,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late int _selectedIndex;
  List jobs = [];
  List filteredJobs = [];
  Set<String> savedJobIds = {};
  bool isLoading = true;
  String selectedCategory = 'Semua';
  String searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex.clamp(0, 2).toInt();
    if (widget.showSuccessDialog) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showSuccessBottomSheet();
      });
    }
    fetchJobs();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String get _currentUserId {
    return widget.userData['_id']?.toString() ??
        widget.userData['id']?.toString() ??
        widget.userData['user_id']?.toString() ??
        widget.userData['email']?.toString() ??
        '';
  }

  String _jobIdOf(Map<String, dynamic> job) {
    return MongoService.getMongoId(job['_id']);
  }

  Future<void> fetchJobs() async {
      setState(() {
      isLoading = true;
    });

    final data = await MongoService.getJobVacancies();
    final savedIds = await MongoService.getSavedJobIds(userId: _currentUserId);

    if (!mounted) return;

    setState(() {
      jobs = data;
      savedJobIds = savedIds;
      isLoading = false;
    });
    applyFilters();
  }

  void _showCustomSnackBar({
    required String message,
    required IconData icon,
    Color backgroundColor = AppColors.primaryNavy,
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: backgroundColor,
        elevation: 8,
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
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

  Future<void> toggleSaveJob(Map<String, dynamic> job) async {
    final jobId = _jobIdOf(job);

    if (_currentUserId.isEmpty || jobId.isEmpty) {
      _showCustomSnackBar(
        message: 'Data pengguna atau lowongan tidak valid',
        icon: Icons.error_outline,
        backgroundColor: Colors.grey.shade800,
      );
      return;
    }

    final alreadySaved = savedJobIds.contains(jobId);
    final success = alreadySaved
        ? await MongoService.unsaveJob(userId: _currentUserId, jobId: jobId)
        : await MongoService.saveJob(userId: _currentUserId, jobId: jobId);

    if (!mounted) return;

    if (success) {
      setState(() {
        if (alreadySaved) {
          savedJobIds.remove(jobId);
        } else {
          savedJobIds.add(jobId);
        }
      });

      _showCustomSnackBar(
        message: alreadySaved
            ? 'Lowongan dihapus dari tersimpan'
            : 'Lowongan berhasil disimpan',
        icon: alreadySaved ? Icons.bookmark_border : Icons.bookmark,
        backgroundColor: alreadySaved ? Colors.grey.shade800 : AppColors.primaryNavy,
      );
    } else {
      _showCustomSnackBar(
        message: alreadySaved
            ? 'Gagal menghapus lowongan tersimpan'
            : 'Gagal menyimpan lowongan',
        icon: Icons.error_outline,
        backgroundColor: Colors.grey.shade800,
      );
    }
  }

  void applyFilters() {
    List result = jobs;

    if (selectedCategory != 'Semua') {
      result = result
          .where(
            (job) =>
                (job['category'] ?? '').toString().toLowerCase() ==
                selectedCategory.toLowerCase(),
          )
          .toList();
    }

    if (searchQuery.isNotEmpty) {
      result = result
          .where(
            (job) =>
                (job['title'] ?? '')
                    .toString()
                    .toLowerCase()
                    .contains(searchQuery.toLowerCase()) ||
                (job['company_name'] ?? '')
                    .toString()
                    .toLowerCase()
                    .contains(searchQuery.toLowerCase()),
          )
          .toList();
    }

    setState(() {
      filteredJobs = result;
    });
  }

  void _showSuccessBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(40),
          topRight: Radius.circular(40),
        ),
      ),
      builder: (BuildContext ctx) {
        return Container(
          height: 440,
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 24),
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 700),
                curve: Curves.elasticOut,
                builder: (context, scale, child) {
                  return Transform.scale(
                    scale: scale,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.green.withOpacity(0.1),
                      ),
                      padding: const EdgeInsets.all(20),
                      child: const Icon(
                        Icons.check_circle_rounded,
                        color: Colors.green,
                        size: 110,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),
              const Text(
                'Login Berhasil !',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryNavy,
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryNavy,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Got It',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  String _getGreeting() {
    var hour = DateTime.now().hour;
    if (hour < 11) return 'Selamat Pagi';
    if (hour < 15) return 'Selamat Siang';
    if (hour < 18) return 'Selamat Sore';
    return 'Selamat Malam';
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final List<Widget> pages = [
      _buildBeranda(context),
      ApplicationsPage(currentUser: widget.userData),
      CvView(currentUser: widget.userData),
      _buildProfil(context),
    ];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: _selectedIndex == 0 ? _buildBerandaAppBar() : _buildOtherAppBar(),
      body: SafeArea(
        child: pages[_selectedIndex],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: theme.brightness == Brightness.dark ? Colors.yellow : AppColors.primaryNavy,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          child: BottomNavigationBar(
            backgroundColor: theme.brightness == Brightness.dark ? Colors.yellow : AppColors.primaryNavy,
            elevation: 0,
            type: BottomNavigationBarType.fixed,
            selectedItemColor: theme.brightness == Brightness.dark ? Colors.black : Colors.white,
            unselectedItemColor: theme.brightness == Brightness.dark ? Colors.black.withOpacity(0.6) : Colors.white70,
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Beranda'),
              BottomNavigationBarItem(icon: Icon(Icons.cases_outlined), label: 'Lamaran'),
              BottomNavigationBarItem(icon: Icon(Icons.description), label: 'CV'),
              BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
            ],
          ),
        ),
      ),
    );
  }

  AppBar _buildBerandaAppBar() {
    final theme = Theme.of(context);
    final String userId = _currentUserId; // Cache local variable
    
    return AppBar(
      backgroundColor: theme.appBarTheme.backgroundColor,
      elevation: 0,
      toolbarHeight: 60,
      automaticallyImplyLeading: false,
      title: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
          children: [
            TextSpan(text: 'Job', style: TextStyle(color: theme.colorScheme.primary)),
            TextSpan(text: 'Able', style: TextStyle(color: theme.brightness == Brightness.dark ? Colors.yellow : AppColors.accentBlue)),
          ],
        ),
      ),
      actions: [
        if (userId.isNotEmpty)
          FutureBuilder<int>(
            future: MongoService.getUnreadNotificationCount(
              receiverId: userId,
              receiverRole: 'job_seeker',
            ),
            builder: (context, snapshot) {
              final hasUnread = (snapshot.data ?? 0) > 0;
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
                            role: 'job_seeker',
                          ),
                        ),
                      );
                      setState(() {}); // Refresh to update unread indicator
                    },
                    icon: Icon(
                      Icons.notifications,
                      color: theme.colorScheme.primary,
                      size: 30,
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
                          border: Border.all(color: theme.scaffoldBackgroundColor, width: 2),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Text(
                          '${snapshot.data}',
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
        const SizedBox(width: 8),
      ],
    );
  }

  AppBar _buildOtherAppBar() {
    final theme = Theme.of(context);
    String title = 'Profil Saya';
    if (_selectedIndex == 1) title = 'Lamaran Saya';
    if (_selectedIndex == 2) title = 'CV Digital';
    
    return AppBar(
      backgroundColor: theme.appBarTheme.backgroundColor,
      elevation: 0,
      automaticallyImplyLeading: false,
      title: Container(
        margin: const EdgeInsets.only(left: 8),
        child: Text(
          title,
          style: TextStyle(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
      ),
      centerTitle: false,
    );
  }

  Widget _buildBeranda(BuildContext context) {
    final theme = Theme.of(context);
    return RefreshIndicator(
      color: theme.colorScheme.primary,
      onRefresh: fetchJobs,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Halo, ${widget.userData['username'] ?? 'User'}. ${_getGreeting()}!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: theme.textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                color: theme.brightness == Brightness.dark ? Colors.black : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.dividerColor),
              ),
              child: TextField(
                controller: _searchController,
                style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                onChanged: (value) {
                  searchQuery = value;
                  applyFilters();
                },
                decoration: InputDecoration(
                  hintText: 'Cari Lowongan Pekerjaan...',
                  hintStyle: TextStyle(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6)),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Accessibility Toggle Below Search Bar
            ValueListenableBuilder<bool>(
              valueListenable: AccessibilityController.highContrastNotifier,
              builder: (context, isHighContrast, _) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: isHighContrast ? Colors.black : AppColors.primaryNavy.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: isHighContrast ? Border.all(color: Colors.yellow, width: 2) : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.visibility,
                            size: 20,
                            color: isHighContrast ? Colors.yellow : AppColors.primaryNavy,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Mode Kontras Tinggi',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isHighContrast ? Colors.yellow : AppColors.primaryNavy,
                            ),
                          ),
                        ],
                      ),
                      Switch(
                        value: isHighContrast,
                        activeColor: Colors.yellow,
                        activeTrackColor: Colors.grey.shade800,
                        onChanged: (value) {
                          AccessibilityController.setHighContrast(value);
                          _showCustomSnackBar(
                            message: value
                                ? 'Mode Kontras Tinggi Diaktifkan'
                                : 'Mode Kontras Tinggi Dimatikan',
                            icon: value ? Icons.visibility : Icons.visibility_off,
                            backgroundColor: value ? Colors.black : Colors.grey.shade800,
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedCategory = 'Semua';
                      });
                      applyFilters();
                    },
                    child: _CategoryButton('Semua', selectedCategory == 'Semua'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedCategory = 'Teknologi';
                      });
                      applyFilters();
                    },
                    child: _CategoryButton('Teknologi', selectedCategory == 'Teknologi'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedCategory = 'Marketing';
                      });
                      applyFilters();
                    },
                    child: _CategoryButton('Marketing', selectedCategory == 'Marketing'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedCategory = 'Admin';
                      });
                      applyFilters();
                    },
                    child: _CategoryButton('Admin', selectedCategory == 'Admin'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Text(
              'Lowongan Terbaru',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: theme.textTheme.titleLarge?.color,
              ),
            ),
            const SizedBox(height: 16),
            if (isLoading)
              Center(child: CircularProgressIndicator(color: theme.colorScheme.primary))
            else if (filteredJobs.isEmpty)
              Center(child: Text('Belum ada lowongan', style: TextStyle(color: theme.textTheme.bodyMedium?.color)))
            else
              ...filteredJobs.map(
                (job) {
                  final jobMap = Map<String, dynamic>.from(job);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _JobCard(
                      title: jobMap['title'] ?? '-',
                      company: jobMap['company_name'] ?? '-',
                      location: jobMap['location'] ?? '-',
                      type: jobMap['job_type'] ?? '-',
                      desc: jobMap['description'] ?? '-',
                      isSaved: savedJobIds.contains(_jobIdOf(jobMap)),
                      onSave: () => toggleSaveJob(jobMap),
                      onDetail: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => JobDetailPage(
                              job: jobMap,
                              currentUser: widget.userData,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildProfil(BuildContext context) {
    return ProfileView(currentUser: widget.userData);
  }
}

class _CategoryButton extends StatelessWidget {
  final String title;
  final bool isSelected;

  const _CategoryButton(this.title, this.isSelected);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: isSelected
            ? theme.colorScheme.primary
            : (isDark ? Colors.black : Colors.transparent),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected
              ? theme.colorScheme.primary
              : (isDark ? Colors.yellow : Colors.grey.shade400),
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        title,
        style: TextStyle(
          color: isSelected
              ? (isDark ? Colors.black : Colors.white)
              : (isDark ? Colors.yellow : Colors.black87),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _JobCard extends StatelessWidget {
  final String title;
  final String company;
  final String location;
  final String type;
  final String desc;
  final bool isSaved;
  final VoidCallback? onDetail;
  final VoidCallback? onSave;

  const _JobCard({
    required this.title,
    required this.company,
    required this.location,
    required this.type,
    required this.desc,
    required this.isSaved,
    this.onDetail,
    this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.black : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.yellow : Colors.grey.shade200),
        boxShadow: isDark
            ? null
            : const [
                BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4)),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.yellow : Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            company,
            style: TextStyle(
              color: isDark ? Colors.yellow.withOpacity(0.7) : AppColors.textGray,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.location_on,
                  size: 16, color: isDark ? Colors.yellow : AppColors.textGray),
              const SizedBox(width: 4),
              Text(
                location,
                style: TextStyle(
                  color: isDark ? Colors.yellow : AppColors.textGray,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 16),
              Icon(Icons.work,
                  size: 16, color: isDark ? Colors.yellow : AppColors.textGray),
              const SizedBox(width: 4),
              Text(
                type,
                style: TextStyle(
                  color: isDark ? Colors.yellow : AppColors.textGray,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            desc,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isDark ? Colors.yellow.withOpacity(0.8) : AppColors.textGray,
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onDetail,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    foregroundColor: isDark ? Colors.yellow : Colors.black87,
                    side: BorderSide(color: isDark ? Colors.yellow : Colors.black87),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Lihat Detail',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onSave,
                  icon: Icon(
                    isSaved ? Icons.bookmark : Icons.bookmark_border,
                    size: 16,
                    color: isSaved
                        ? (isDark ? Colors.black : Colors.white)
                        : (isDark ? Colors.yellow : Colors.black87),
                  ),
                  label: Flexible(
                    child: Text(
                      isSaved ? 'Lowongan Tersimpan' : 'Simpan Lowongan',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isSaved
                            ? (isDark ? Colors.black : Colors.white)
                            : (isDark ? Colors.yellow : Colors.black87),
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                    elevation: 0,
                    backgroundColor: isSaved
                        ? (isDark ? Colors.yellow : AppColors.primaryNavy)
                        : Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                        color: isDark ? Colors.yellow : (isSaved ? AppColors.primaryNavy : Colors.black87),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}