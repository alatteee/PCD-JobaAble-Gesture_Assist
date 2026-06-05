import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import '../../core/constants/app_colors.dart';
import '../../services/mongo_service.dart';
import '../../services/offline_service.dart';
import '../job_detail/job_detail_page.dart';
import '../applications/applications_page.dart';
import '../profile/profile_view.dart';
import '../profile/accessibility_settings_view.dart';
import '../profile/profile_controller.dart';

import '../notifications/notification_page.dart';
import '../cv/cv_view.dart';
import '../gesture_assist/controllers/gesture_navigation_controller.dart';
import '../gesture_assist/providers/camera_provider.dart';
import '../gesture_assist/utils/gesture_navigation_guard.dart';
import '../gesture_assist/widgets/mini_camera_preview.dart';

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
  bool isLoadingProfileName = true;
  bool _isOpeningNotificationPage = false;
  bool _isUpdatingGestureMode = false;

  CameraProvider? _cameraProvider;

  String? namaLengkap;

  String selectedCategory = 'Semua';
  String searchQuery = '';

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _homeScrollController = ScrollController();
  final List<GlobalKey> _jobItemKeys = [];
  final GestureNavigationController _gestureNavigationController =
      GestureNavigationController();

  int _currentFocusedJobIndex = 0;

  @override
  void initState() {
    super.initState();

    _selectedIndex = widget.initialIndex.clamp(0, 3).toInt();

    // Set userId untuk gesture logging lokal
    _gestureNavigationController.setUserId(_currentUserId);

    // Listener feedback global dari GestureNavigationController.
    // Ini penting supaya feedback seperti cooldown/nonaktif/confidence rendah
    // bisa muncul di HomePage, bukan hanya muncul di terminal.
    _setupHomeGestureFeedbackListener();

    if (widget.showSuccessDialog) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showSuccessBottomSheet();
      });
    }

    fetchProfileName();
    fetchJobs();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _registerHomeGestureActionsIfNeeded();
      _setupHomeGestureCameraIfNeeded();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _cameraProvider ??= context.read<CameraProvider>();
  }

  @override
  void dispose() {
    GestureNavigationGuard.unregisterPageGestures(
      _gestureNavigationController,
      owner: this,
    );
    _cameraProvider?.stopGestureCamera();
    _homeScrollController.dispose();
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

  String? _textOrNull(dynamic value) {
    final text = value?.toString().trim();

    if (text == null || text.isEmpty) return null;

    return text;
  }

  String _getDisplayName() {
    return _textOrNull(namaLengkap) ??
        _textOrNull(widget.userData['nama_lengkap']) ??
        _textOrNull(widget.userData['full_name']) ??
        _textOrNull(widget.userData['username']) ??
        'User';
  }

  Future<void> fetchProfileName() async {
    final userId = widget.userData['_id'] ??
        widget.userData['id'] ??
        widget.userData['user_id'];

    if (userId == null) {
      if (!mounted) return;

      setState(() {
        isLoadingProfileName = false;
      });

      return;
    }

    try {
      final profile = await ProfileController.getProfileByUserId(userId);

      if (!mounted) return;

      setState(() {
        namaLengkap = _textOrNull(profile?['nama_lengkap']) ??
            _textOrNull(profile?['full_name']);
        isLoadingProfileName = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        isLoadingProfileName = false;
      });
    }
  }

  String _jobIdOf(Map<String, dynamic> job) {
    return MongoService.getMongoId(job['_id']);
  }

  Future<void> fetchJobs() async {
    if (mounted) {
      setState(() {
        isLoading = true;
      });
    }

    final data = await MongoService.getJobVacancies();
    final savedIds = await MongoService.getSavedJobIds(
      userId: _currentUserId,
    );

    if (!mounted) return;

    setState(() {
      jobs = data;
      savedJobIds = savedIds;
      isLoading = false;
    });

    applyFilters();
  }

  /// Force refresh jobs dari MongoDB (clear cache dan fetch fresh)
  Future<void> forceFreshFetch() async {
    if (mounted) {
      setState(() {
        isLoading = true;
      });
    }

    // DEBUG: Check cache sebelum dihapus
    print('🔍 DEBUG: Checking cache before clear...');
    OfflineService.debugCachedJobsCount();

    // Hapus cache lama
    print('🗑️ Clearing cache to force fresh fetch from MongoDB...');
    await OfflineService.clearJobsCache();

    // Fetch ulang dari MongoDB
    await fetchJobs();

    if (mounted) {
      _showCustomSnackBar(
        message: 'Data diperbarui dari server',
        icon: Icons.refresh,
        backgroundColor: Colors.grey.shade800,
        isHighContrast: AccessibilityController.highContrastNotifier.value,
      );
    }
  }

  Future<void> toggleSaveJob(
    Map<String, dynamic> job,
    bool isHighContrast,
  ) async {
    final jobId = _jobIdOf(job);

    if (_currentUserId.isEmpty || jobId.isEmpty) {
      _showCustomSnackBar(
        message: 'Data pengguna atau lowongan tidak valid',
        icon: Icons.error_outline,
        backgroundColor: Colors.grey.shade800,
        isHighContrast: isHighContrast,
      );
      return;
    }

    final alreadySaved = savedJobIds.contains(jobId);

    final success = alreadySaved
        ? await MongoService.unsaveJob(
            userId: _currentUserId,
            jobId: jobId,
          )
        : await MongoService.saveJob(
            userId: _currentUserId,
            jobId: jobId,
          );

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
        backgroundColor:
            alreadySaved ? Colors.grey.shade800 : AppColors.primaryNavy,
        isHighContrast: isHighContrast,
      );
    } else {
      _showCustomSnackBar(
        message: alreadySaved
            ? 'Gagal menghapus lowongan tersimpan'
            : 'Gagal menyimpan lowongan',
        icon: Icons.error_outline,
        backgroundColor: Colors.grey.shade800,
        isHighContrast: isHighContrast,
      );
    }
  }

  void _showCustomSnackBar({
    required String message,
    required IconData icon,
    required Color backgroundColor,
    required bool isHighContrast,
  }) {
    final snackBar = SnackBar(
      content: Row(
        children: [
          Icon(
            icon,
            color: isHighContrast ? AccessibilityTheme.black : Colors.white,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color:
                    isHighContrast ? AccessibilityTheme.black : Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      backgroundColor:
          isHighContrast ? AccessibilityTheme.yellow : backgroundColor,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.all(16),
      elevation: 4,
      duration: const Duration(seconds: 2),
    );

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(snackBar);
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

    if (!mounted) return;

    setState(() {
      filteredJobs = result;
      if (filteredJobs.isEmpty) {
        _currentFocusedJobIndex = 0;
      } else if (_currentFocusedJobIndex >= filteredJobs.length) {
        _currentFocusedJobIndex = filteredJobs.length - 1;
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _registerHomeGestureActionsIfNeeded();
      _setupHomeGestureCameraIfNeeded();
    });
  }

  void _showSuccessBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(40),
          topRight: Radius.circular(40),
        ),
      ),
      builder: (BuildContext ctx) {
        return ValueListenableBuilder<bool>(
          valueListenable: AccessibilityController.highContrastNotifier,
          builder: (context, isHighContrast, _) {
            final bgColor =
                isHighContrast ? AccessibilityTheme.darkCard : Colors.white;
            final textColor =
                isHighContrast ? AccessibilityTheme.yellow : AppColors.primaryNavy;
            final buttonBgColor =
                isHighContrast ? AccessibilityTheme.yellow : AppColors.primaryNavy;
            final buttonTextColor =
                isHighContrast ? AccessibilityTheme.black : Colors.white;

            return Container(
              height: 440,
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 32.0,
              ),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(40),
                  topRight: Radius.circular(40),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 24),
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(
                      begin: 0.0,
                      end: 1.0,
                    ),
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.elasticOut,
                    builder: (context, scale, child) {
                      return Transform.scale(
                        scale: scale,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isHighContrast
                                ? Colors.green.withOpacity(0.2)
                                : Colors.green.withOpacity(0.1),
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
                  Text(
                    'Login Berhasil !',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: buttonBgColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        'Got It',
                        style: TextStyle(
                          color: buttonTextColor,
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
      },
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;

    if (hour < 11) return 'Selamat Pagi';
    if (hour < 15) return 'Selamat Siang';
    if (hour < 18) return 'Selamat Sore';

    return 'Selamat Malam';
  }

  void _onItemTapped(int index) {
    if (_selectedIndex == index) return;

    final wasOnHome = _selectedIndex == 0;

    setState(() {
      _selectedIndex = index;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      if (_selectedIndex == 0) {
        _registerHomeGestureActionsIfNeeded();
        _setupHomeGestureCameraIfNeeded();
      } else if (wasOnHome) {
        _stopHomeGestureCameraAndActions();
      }
    });
  }

  bool _isGestureNavigationModeOn() {
    return AccessibilityController.gestureNavigationModeNotifier.value;
  }

  Future<void> _setupHomeGestureCameraIfNeeded() async {
    if (!mounted || _selectedIndex != 0) return;

    if (!_isGestureNavigationModeOn()) {
      await _stopHomeGestureCameraAndActions();
      return;
    }

    try {
      final cameraProvider = _cameraProvider ?? context.read<CameraProvider>();
      _cameraProvider = cameraProvider;

      cameraProvider.setGestureNavigationController(_gestureNavigationController);

      if (!cameraProvider.isInitialized && !cameraProvider.isLoading) {
        await cameraProvider.initializeCamera();
        if (!mounted) return;
      } else if (cameraProvider.isInitialized && !cameraProvider.isStreaming) {
        cameraProvider.startGestureStream();
      }
    } catch (e) {
      debugPrint('[HomePage] Gesture camera setup skipped: $e');
    }
  }

  Future<void> _stopHomeGestureCameraAndActions() async {
    GestureNavigationGuard.unregisterPageGestures(
      _gestureNavigationController,
      owner: this,
    );

    try {
      final cameraProvider = _cameraProvider ?? context.read<CameraProvider>();
      _cameraProvider = cameraProvider;
      await cameraProvider.stopGestureCamera();
    } catch (e) {
      debugPrint('[HomePage] Gesture camera stop skipped: $e');
    }
  }

  Future<void> _setGestureModeFromHome(bool value) async {
    if (_isUpdatingGestureMode) return;

    setState(() {
      _isUpdatingGestureMode = true;
    });

    try {
      await AccessibilityController.setGestureNavigationMode(value);

      if (!mounted) return;

      if (value) {
        _registerHomeGestureActionsIfNeeded();
        await _setupHomeGestureCameraIfNeeded();
      } else {
        await _stopHomeGestureCameraAndActions();
      }

      if (!mounted) return;

      _showCustomSnackBar(
        message: value
            ? 'Gesture Mode diaktifkan dari Beranda'
            : 'Gesture Mode dimatikan',
        icon: value ? Icons.front_hand_rounded : Icons.front_hand_outlined,
        backgroundColor: value ? const Color(0xFF16A34A) : Colors.orange,
        isHighContrast: AccessibilityController.highContrastNotifier.value,
      );
    } catch (e) {
      if (!mounted) return;

      _showCustomSnackBar(
        message: 'Gagal mengubah Gesture Mode',
        icon: Icons.error_outline_rounded,
        backgroundColor: Colors.red,
        isHighContrast: AccessibilityController.highContrastNotifier.value,
      );
    } finally {
      if (!mounted) return;

      setState(() {
        _isUpdatingGestureMode = false;
      });
    }
  }

  void _syncJobItemKeys() {
    if (_jobItemKeys.length < filteredJobs.length) {
      _jobItemKeys.addAll(
        List.generate(
          filteredJobs.length - _jobItemKeys.length,
          (_) => GlobalKey(),
        ),
      );
    } else if (_jobItemKeys.length > filteredJobs.length) {
      _jobItemKeys.removeRange(filteredJobs.length, _jobItemKeys.length);
    }
  }

  String _getJobTitle(Map<String, dynamic> job) {
    final title = job['title']?.toString().trim();
    if (title != null && title.isNotEmpty) return title;

    final jobTitle = job['job_title']?.toString().trim();
    if (jobTitle != null && jobTitle.isNotEmpty) return jobTitle;

    return 'Lowongan';
  }

  String _selectedJobMessage(Map<String, dynamic> job) {
    final title = _getJobTitle(job);

    if (title.length <= 34) {
      return 'Dipilih: $title';
    }

    return 'Dipilih: ${title.substring(0, 31)}...';
  }

  Future<void> _scrollToFocusedJob() async {
    if (!mounted) return;

    if (filteredJobs.isEmpty ||
        _currentFocusedJobIndex < 0 ||
        _currentFocusedJobIndex >= filteredJobs.length) {
      return;
    }

    _syncJobItemKeys();

    final itemContext = _currentFocusedJobIndex < _jobItemKeys.length
        ? _jobItemKeys[_currentFocusedJobIndex].currentContext
        : null;

    if (itemContext != null) {
      await Scrollable.ensureVisible(
        itemContext,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
        alignment: 0.42,
      );
      return;
    }

    if (!_homeScrollController.hasClients) return;

    const headerOffset = 520.0;
    const estimatedItemHeight = 190.0;
    final viewportHeight = _homeScrollController.position.viewportDimension;
    final itemOffset =
        headerOffset + (_currentFocusedJobIndex * estimatedItemHeight);
    final centeredOffset =
        itemOffset - (viewportHeight / 2) + (estimatedItemHeight / 2);

    final safeOffset = centeredOffset.clamp(
      0.0,
      _homeScrollController.position.maxScrollExtent,
    );

    await _homeScrollController.animateTo(
      safeOffset,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
    );
  }

  void _setupHomeGestureFeedbackListener() {
    _gestureNavigationController.onActionResult((result) {
      if (!mounted || _selectedIndex != 0) return;

      final message = result.message?.trim();

      if (message == null || message.isEmpty) return;

      final lowerMessage = message.toLowerCase();

      final isControllerFeedback = lowerMessage.contains('cooldown') ||
          lowerMessage.contains('nonaktif') ||
          lowerMessage.contains('confidence') ||
          lowerMessage.contains('belum stabil') ||
          lowerMessage.contains('diproses') ||
          lowerMessage.contains('tidak dikenali');

      // Feedback sukses seperti "Lanjut berhasil" sudah ditangani langsung
      // oleh _handleGestureNextJob(), jadi jangan ditampilkan ulang di sini.
      if (!isControllerFeedback) return;

      final isHighContrast =
          AccessibilityController.highContrastNotifier.value;

      final bool isWarning = lowerMessage.contains('cooldown') ||
          lowerMessage.contains('nonaktif') ||
          lowerMessage.contains('confidence') ||
          lowerMessage.contains('belum stabil') ||
          lowerMessage.contains('diproses');

      _showCustomSnackBar(
        message: message,
        icon: isWarning
            ? Icons.hourglass_bottom_rounded
            : Icons.warning_amber_rounded,
        backgroundColor: isWarning ? Colors.orange : Colors.red,
        isHighContrast: isHighContrast,
      );
    });
  }

  void _registerHomeGestureActionsIfNeeded() {
    if (!mounted || _selectedIndex != 0) return;

    if (!_isGestureNavigationModeOn()) {
      GestureNavigationGuard.unregisterPageGestures(
        _gestureNavigationController,
        owner: this,
      );
      return;
    }

    // Re-register listener karena controller singleton dan callback
    // onActionResult bisa ditimpa oleh halaman lain.
    _setupHomeGestureFeedbackListener();

    GestureNavigationGuard.registerPageGestures(
      controller: _gestureNavigationController,
      owner: this,
      screenContext: 'home',
      scrollController: _homeScrollController,
      onNext: _handleGestureNextJob,
      onBack: _handleGestureBackFromHome,
      onConfirm: _handleGestureOpenFocusedJob,
    );

    _gestureNavigationController.printStatus();
  }

  Future<bool> _handleGestureNextJob() async {
    if (!mounted) return false;

    if (filteredJobs.isEmpty) {
      _showGesturePageFeedback(
        'Tidak ada lowongan yang tersedia',
        isError: true,
      );
      return false;
    }

    if (_currentFocusedJobIndex >= filteredJobs.length - 1) {
      _showGesturePageFeedback(
        'Tidak ada lowongan berikutnya',
        isError: true,
      );
      return false;
    }

    setState(() {
      _currentFocusedJobIndex++;
    });

    await _scrollToFocusedJob();

    if (!mounted) return false;

    final focusedJob = Map<String, dynamic>.from(
      filteredJobs[_currentFocusedJobIndex] as Map,
    );

    _showGesturePageFeedback(
      _selectedJobMessage(focusedJob),
    );

    return true;
  }

  Future<bool> _handleGestureOpenFocusedJob() async {
    if (!mounted) return false;

    if (filteredJobs.isEmpty ||
        _currentFocusedJobIndex < 0 ||
        _currentFocusedJobIndex >= filteredJobs.length) {
      _showGesturePageFeedback(
        'Tidak ada lowongan yang sedang dipilih',
        isError: true,
      );
      return false;
    }

    final jobMap = Map<String, dynamic>.from(
      filteredJobs[_currentFocusedJobIndex] as Map,
    );

    _showGesturePageFeedback('Membuka: ${_getJobTitle(jobMap)}');

    // Jangan await Navigator.push di dalam callback gesture.
    // Kalau di-await, GestureNavigationController akan tetap berada dalam state
    // "executing" selama JobDetailPage terbuka. Akibatnya gesture di halaman
    // detail tidak langsung aktif ketika detail dibuka lewat Thumbs Up.
    Future.microtask(() {
      if (!mounted) return;
      _openJobDetailWithGestureReRegister(jobMap);
    });

    return true;
  }

  Future<bool> _handleGestureBackFromHome() async {
    if (!mounted) return false;

    if (_selectedIndex != 0) {
      setState(() {
        _selectedIndex = 0;
      });
      _registerHomeGestureActionsIfNeeded();
      return true;
    }

    final popped = await Navigator.maybePop(context);

    if (!popped && mounted) {
      _showGesturePageFeedback(
        'Sudah di halaman utama',
        isError: true,
      );
    }

    return popped;
  }

  Future<void> _openJobDetailWithGestureReRegister(
    Map<String, dynamic> jobMap,
  ) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => JobDetailPage(
          job: jobMap,
          currentUser: widget.userData,
        ),
      ),
    );

    if (!mounted) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _registerHomeGestureActionsIfNeeded();
      _setupHomeGestureCameraIfNeeded();
    });
  }

  void _showGesturePageFeedback(
    String message, {
    bool isError = false,
  }) {
    if (!mounted) return;

    _showCustomSnackBar(
      message: message,
      icon: isError ? Icons.warning_amber_rounded : Icons.check_circle_rounded,
      backgroundColor: isError ? Colors.orange : const Color(0xFF16A34A),
      isHighContrast: AccessibilityController.highContrastNotifier.value,
    );
  }

  Future<void> _openNotificationPage() async {
    if (_isOpeningNotificationPage) return;

    setState(() {
      _isOpeningNotificationPage = true;
    });

    try {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => NotificationPage(
            currentUser: widget.userData,
            role: 'job_seeker',
          ),
        ),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        _isOpeningNotificationPage = false;
      });
    }
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
      body: Stack(
        children: [
          SafeArea(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: KeyedSubtree(
                key: ValueKey<int>(_selectedIndex),
                child: pages[_selectedIndex],
              ),
            ),
          ),
          if (_selectedIndex == 0)
            ValueListenableBuilder<bool>(
              valueListenable:
                  AccessibilityController.gestureNavigationModeNotifier,
              builder: (context, isGestureModeOn, _) {
                if (!isGestureModeOn) {
                  return const SizedBox.shrink();
                }

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _setupHomeGestureCameraIfNeeded();
                });

                return const Positioned(
                  right: 16,
                  bottom: 92,
                  child: IgnorePointer(
                    child: MiniCameraPreview(
                      width: 78,
                      height: 104,
                    ),
                  ),
                );
              },
            ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: theme.brightness == Brightness.dark
              ? Colors.yellow
              : AppColors.primaryNavy,
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
            backgroundColor: theme.brightness == Brightness.dark
                ? Colors.yellow
                : AppColors.primaryNavy,
            elevation: 0,
            type: BottomNavigationBarType.fixed,
            selectedItemColor:
                theme.brightness == Brightness.dark ? Colors.black : Colors.white,
            unselectedItemColor: theme.brightness == Brightness.dark
                ? Colors.black.withOpacity(0.6)
                : Colors.white70,
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: 'Beranda',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.cases_outlined),
                label: 'Lamaran',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.description),
                label: 'CV',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: 'Profil',
              ),
            ],
          ),
        ),
      ),
    );
  }

  AppBar _buildBerandaAppBar() {
    final theme = Theme.of(context);
    final String userId = _currentUserId;

    return AppBar(
      backgroundColor: theme.appBarTheme.backgroundColor,
      elevation: 0,
      toolbarHeight: 60,
      automaticallyImplyLeading: false,
      title: RichText(
        text: TextSpan(
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
          children: [
            TextSpan(
              text: 'Job',
              style: TextStyle(
                color: theme.colorScheme.primary,
              ),
            ),
            TextSpan(
              text: 'Able',
              style: TextStyle(
                color: theme.brightness == Brightness.dark
                    ? Colors.yellow
                    : AppColors.accentBlue,
              ),
            ),
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
              final unreadCount = snapshot.data ?? 0;
              final hasUnread = unreadCount > 0;

              return Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.notifications,
                        color: theme.colorScheme.primary,
                        size: 28,
                      ),
                      onPressed: _openNotificationPage,
                    ),
                    if (hasUnread)
                      Positioned(
                        top: 12,
                        right: 10,
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: theme.appBarTheme.backgroundColor!,
                              width: 2,
                            ),
                          ),
                          child: Text(
                            '$unreadCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
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
    if (_selectedIndex == 3) title = 'Profil Saya';

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

  Widget _buildAccessibilityGestureModeRow() {
    return ValueListenableBuilder<bool>(
      valueListenable: AccessibilityController.highContrastNotifier,
      builder: (context, isHighContrast, _) {
        return Row(
          children: [
            Expanded(
              child: _buildCompactModeToggleCard(
                icon: Icons.visibility_rounded,
                title: 'Kontras Tinggi',
                value: isHighContrast,
                isHighContrast: isHighContrast,
                onChanged: (value) {
                  AccessibilityController.setHighContrast(value);

                  _showCustomSnackBar(
                    message: value
                        ? 'Mode Kontras Tinggi Diaktifkan'
                        : 'Mode Kontras Tinggi Dimatikan',
                    icon: value ? Icons.visibility : Icons.visibility_off,
                    backgroundColor:
                        value ? Colors.black : Colors.grey.shade800,
                    isHighContrast: value,
                  );
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ValueListenableBuilder<bool>(
                valueListenable:
                    AccessibilityController.gestureNavigationModeNotifier,
                builder: (context, isGestureModeOn, __) {
                  return _buildCompactModeToggleCard(
                    icon: Icons.front_hand_rounded,
                    title: 'Gesture Mode',
                    value: isGestureModeOn,
                    isHighContrast: isHighContrast,
                    isLoading: _isUpdatingGestureMode,
                    onChanged: _setGestureModeFromHome,
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCompactModeToggleCard({
    required IconData icon,
    required String title,
    required bool value,
    required bool isHighContrast,
    required ValueChanged<bool> onChanged,
    bool isLoading = false,
  }) {
    final mainColor =
        isHighContrast ? AccessibilityTheme.yellow : AppColors.primaryNavy;

    final backgroundColor = isHighContrast
        ? AccessibilityTheme.darkCard
        : AppColors.primaryNavy.withOpacity(0.05);

    final borderColor = isHighContrast
        ? AccessibilityTheme.yellow
        : AppColors.primaryNavy.withOpacity(0.10);

    return Container(
      constraints: const BoxConstraints(minHeight: 64),
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: borderColor,
          width: isHighContrast ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: mainColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
                height: 1.15,
                color: mainColor,
              ),
            ),
          ),
          const SizedBox(width: 4),
          if (isLoading)
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                color: mainColor,
              ),
            )
          else
            Transform.scale(
              scale: 0.78,
              child: Switch(
                value: value,
                activeThumbColor:
                    isHighContrast ? AccessibilityTheme.yellow : mainColor,
                activeTrackColor: isHighContrast
                    ? AccessibilityTheme.yellow.withOpacity(0.35)
                    : AppColors.primaryNavy.withOpacity(0.30),
                onChanged: onChanged,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBeranda(BuildContext context) {
    final theme = Theme.of(context);
    _syncJobItemKeys();

    return RefreshIndicator(
      color: theme.colorScheme.primary,
      onRefresh: forceFreshFetch,
      child: SingleChildScrollView(
        controller: _homeScrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isLoadingProfileName
                  ? 'Halo. ${_getGreeting()}!'
                  : 'Halo, ${_getDisplayName()}. ${_getGreeting()}!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: theme.textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                color: theme.brightness == Brightness.dark
                    ? Colors.black
                    : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.dividerColor,
                ),
              ),
              child: TextField(
                controller: _searchController,
                style: TextStyle(
                  color: theme.textTheme.bodyLarge?.color,
                ),
                onChanged: (value) {
                  searchQuery = value;
                  applyFilters();
                },
                decoration: InputDecoration(
                  hintText: 'Cari Lowongan Pekerjaan...',
                  hintStyle: TextStyle(
                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildAccessibilityGestureModeRow(),
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
                    child: _CategoryButton(
                      'Semua',
                      selectedCategory == 'Semua',
                    ),
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
                    child: _CategoryButton(
                      'Teknologi',
                      selectedCategory == 'Teknologi',
                    ),
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
                    child: _CategoryButton(
                      'Marketing',
                      selectedCategory == 'Marketing',
                    ),
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
                    child: _CategoryButton(
                      'Admin',
                      selectedCategory == 'Admin',
                    ),
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
              Center(
                child: CircularProgressIndicator(
                  color: theme.colorScheme.primary,
                ),
              )
            else if (filteredJobs.isEmpty)
              Center(
                child: Text(
                  'Tidak ada lowongan yang cocok',
                  style: TextStyle(color: theme.textTheme.bodyMedium?.color),
                ),
              )
            else
              ...filteredJobs.asMap().entries.map(
                (entry) {
                  final index = entry.key;
                  final jobMap = entry.value as Map<String, dynamic>;
                  final isFocused = index == _currentFocusedJobIndex;

                  return ValueListenableBuilder<bool>(
                    valueListenable:
                        AccessibilityController.highContrastNotifier,
                    builder: (context, isHighContrast, _) {
                      return AnimatedContainer(
                        key: index < _jobItemKeys.length
                            ? _jobItemKeys[index]
                            : null,
                        duration: const Duration(milliseconds: 220),
                        margin: EdgeInsets.only(bottom: isFocused ? 10 : 0),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          border: isFocused
                              ? Border.all(
                                  color: isHighContrast
                                      ? AccessibilityTheme.yellow
                                      : AppColors.primaryNavy,
                                  width: 2,
                                )
                              : null,
                          boxShadow: isFocused && !isHighContrast
                              ? [
                                  BoxShadow(
                                    color:
                                        AppColors.primaryNavy.withOpacity(0.12),
                                    blurRadius: 14,
                                    offset: const Offset(0, 6),
                                  ),
                                ]
                              : null,
                        ),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            _JobCard(
                              job: jobMap,
                              isSaved: savedJobIds.contains(_jobIdOf(jobMap)),
                              isHighContrast: isHighContrast,
                              onDetail: () {
                                setState(() {
                                  _currentFocusedJobIndex = index;
                                });
                                _openJobDetailWithGestureReRegister(jobMap);
                              },
                              onSave: () =>
                                  toggleSaveJob(jobMap, isHighContrast),
                            ),
                            if (isFocused)
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isHighContrast
                                        ? AccessibilityTheme.yellow
                                        : AppColors.primaryNavy,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    'Dipilih',
                                    style: TextStyle(
                                      color: isHighContrast
                                          ? AccessibilityTheme.black
                                          : Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
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
    return ProfileView(
      currentUser: widget.userData,
    );
  }
}

class _CategoryButton extends StatelessWidget {
  final String title;
  final bool isSelected;

  const _CategoryButton(
    this.title,
    this.isSelected,
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 12,
      ),
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
  final Map<String, dynamic> job;
  final bool isSaved;
  final bool isHighContrast;
  final VoidCallback? onDetail;
  final VoidCallback? onSave;

  const _JobCard({
    required this.job,
    required this.isSaved,
    required this.isHighContrast,
    this.onDetail,
    this.onSave,
  });

  Widget _buildJobPhoto(dynamic photo) {
    final photoText = photo?.toString().trim() ?? '';

    Widget placeholder() {
      return Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: isHighContrast
              ? Colors.yellow.withOpacity(0.3)
              : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.business,
          color: isHighContrast
              ? AccessibilityTheme.yellow
              : Colors.grey.shade400,
        ),
      );
    }

    if (photoText.isEmpty) {
      return placeholder();
    }

    // Untuk data stress test: job_photo berupa URL https://picsum.photos/...
    if (photoText.startsWith('http://') || photoText.startsWith('https://')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          photoText,
          width: 48,
          height: 48,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => placeholder(),
        ),
      );
    }

    // Untuk data lama/asli: job_photo berupa base64
    try {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.memory(
          base64Decode(photoText),
          width: 48,
          height: 48,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => placeholder(),
        ),
      );
    } catch (e) {
      return placeholder();
    }
  }

  String _getJobTitle() {
    return job['title']?.toString() ??
        job['job_title']?.toString() ??
        'Tanpa Judul';
  }

  String _getJobType() {
    return job['job_type']?.toString() ??
        job['type']?.toString() ??
        'Tipe tidak diketahui';
  }

  @override
  Widget build(BuildContext context) {
    final cardColor =
        isHighContrast ? AccessibilityTheme.darkCard : Colors.white;
    final textColor =
        isHighContrast ? AccessibilityTheme.yellow : AppColors.primaryNavy;
    final subTextColor = isHighContrast ? Colors.white70 : Colors.black54;
    final buttonColor =
        isHighContrast ? AccessibilityTheme.yellow : AppColors.primaryNavy;
    final buttonTextColor =
        isHighContrast ? AccessibilityTheme.black : Colors.white;
    final outlineButtonColor =
        isHighContrast ? AccessibilityTheme.yellow : AppColors.primaryNavy;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isHighContrast
              ? outlineButtonColor.withOpacity(0.5)
              : Colors.grey.withOpacity(0.1),
        ),
        boxShadow: [
          if (!isHighContrast)
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildJobPhoto(job['job_photo']),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getJobTitle(),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      job['company_name'] ?? 'Perusahaan Anonim',
                      style: TextStyle(
                        fontSize: 14,
                        color: subTextColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.location_on, color: subTextColor, size: 16),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  job['location'] ?? 'Lokasi tidak diketahui',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: subTextColor),
                ),
              ),
              const SizedBox(width: 16),
              Icon(Icons.work, color: subTextColor, size: 16),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  _getJobType(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: subTextColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            job['description'] ?? 'Tidak ada deskripsi',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: subTextColor),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onDetail,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: outlineButtonColor,
                    side: BorderSide(color: outlineButtonColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Lihat Detail'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onSave,
                  icon: Icon(
                    isSaved ? Icons.bookmark : Icons.bookmark_border,
                    color: buttonTextColor,
                  ),
                  label: Text(isSaved ? 'Tersimpan' : 'Simpan'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: buttonColor,
                    foregroundColor: buttonTextColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
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