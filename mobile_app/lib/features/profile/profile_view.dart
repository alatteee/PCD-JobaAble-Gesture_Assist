import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../auth/login_view.dart';
import 'profile_detail_view.dart';
import 'account_settings_view.dart';
import 'help_view.dart';
import 'about_view.dart';
import '../saved_jobs/saved_jobs_page.dart';
import 'profile_controller.dart';
import 'dart:convert';
import 'dart:io';
import 'accessibility_settings_view.dart';
import '../../services/offline_service.dart';

class ProfileView extends StatefulWidget {
  final Map<String, dynamic> currentUser;

  const ProfileView({
    super.key,
    required this.currentUser,
  });

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  Map<String, dynamic>? userDetails;
  bool isLoading = true;

  static const Color navy = AppColors.primaryNavy;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final userId = widget.currentUser['_id'];

    if (userId == null) {
      if (!mounted) return;

      setState(() => isLoading = false);
      return;
    }

    final profile = await ProfileController.getProfileByUserId(userId);

    if (!mounted) return;

    setState(() {
      userDetails = profile;
      isLoading = false;
    });
  }

  bool _isBase64(String str) {
    try {
      base64Decode(str);
      return str.length % 4 == 0 && !str.contains(' ');
    } catch (e) {
      return false;
    }
  }

  Widget _buildProfilePhoto(BuildContext context) {
    final theme = Theme.of(context);
    final photo = userDetails?['profile_photo']?.toString() ?? '';

    if (photo.isEmpty) {
      return Icon(
        Icons.person,
        size: 50,
        color: theme.colorScheme.primary,
      );
    }

    try {
      if (_isBase64(photo)) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image.memory(
            base64Decode(photo),
            fit: BoxFit.cover,
            width: 80,
            height: 80,
          ),
        );
      }

      if (photo.startsWith('http')) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image.network(
            photo,
            fit: BoxFit.cover,
            width: 80,
            height: 80,
            errorBuilder: (_, __, ___) {
              return Icon(
                Icons.person,
                size: 50,
                color: theme.colorScheme.primary,
              );
            },
          ),
        );
      }

      return ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Image.file(
          File(photo),
          fit: BoxFit.cover,
          width: 80,
          height: 80,
          errorBuilder: (_, __, ___) {
            return Icon(
              Icons.person,
              size: 50,
              color: theme.colorScheme.primary,
            );
          },
        ),
      );
    } catch (_) {
      return Icon(
        Icons.person,
        size: 50,
        color: theme.colorScheme.primary,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: theme.colorScheme.primary,
        ),
      );
    }

    return RefreshIndicator(
      color: theme.colorScheme.primary,
      onRefresh: _loadProfile,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(
          horizontal: 20.0,
          vertical: 8.0,
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _buildProfilePhoto(context),
                ),

                const SizedBox(width: 16),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userDetails?['nama_lengkap'] ??
                            widget.currentUser['username'] ??
                            'User',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),

                      const SizedBox(height: 2),

                      Text(
                        userDetails?['email'] ??
                            widget.currentUser['email'] ??
                            '-',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          color: theme.textTheme.bodyMedium?.color,
                        ),
                      ),

                      const SizedBox(height: 14),

                      SizedBox(
                        height: 36,
                        width: 120,
                        child: OutlinedButton(
                          onPressed: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ProfileDetailView(
                                  currentUser: widget.currentUser,
                                ),
                              ),
                            );

                            if (result == true) {
                              _loadProfile();
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.zero,
                            foregroundColor: theme.colorScheme.primary,
                            side: BorderSide(
                              color: theme.colorScheme.primary,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Lihat Profil',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            _buildMenuCard(
              icon: Icons.bookmark,
              label: 'Lowongan Tersimpan',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SavedJobsPage(
                      currentUser: widget.currentUser,
                    ),
                  ),
                );
              },
            ),

            _buildMenuCard(
              icon: Icons.settings,
              label: 'Pengaturan Akun',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AccountSettingsView(
                      currentUser: widget.currentUser,
                    ),
                  ),
                );
              },
            ),

            _buildMenuCard(
              icon: Icons.help,
              label: 'Bantuan',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const HelpView(),
                  ),
                );
              },
            ),

            _buildMenuCard(
              icon: Icons.accessibility_new,
              label: 'Pengaturan Aksesibilitas',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AccessibilitySettingsView(),
                  ),
                );
              },
            ),

            _buildMenuCard(
              icon: Icons.info,
              label: 'Tentang Aplikasi',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AboutView(),
                  ),
                );
              },
            ),

            _buildMenuCard(
              icon: Icons.logout,
              label: 'Logout',
              onTap: () => _showLogoutDialog(context),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          height: 62,
          padding: const EdgeInsets.symmetric(horizontal: 22),
          decoration: BoxDecoration(
            color: isDark ? Colors.black : Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: isDark
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.16),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Row(
            children: [
              SizedBox(
                width: 36,
                child: Icon(
                  icon,
                  color: isDark ? Colors.yellow : navy,
                  size: 27,
                ),
              ),

              const SizedBox(width: 28),

              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.yellow : navy,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: isDark
              ? const BorderSide(color: Colors.yellow)
              : BorderSide.none,
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        child: Stack(
          children: [
            Positioned(
              right: 12,
              top: 12,
              child: IconButton(
                icon: Icon(
                  Icons.close,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 40.0,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.logout_rounded,
                    size: 100,
                    color: theme.colorScheme.primary,
                  ),

                  const SizedBox(height: 24),

                  Text(
                    'Logout Account?',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    'Apakah anda yakin akan logout\ndari akun anda?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: theme.textTheme.bodyMedium?.color,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 32),

                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 54,
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isDark
                                  ? Colors.grey[900]
                                  : const Color(0xFFE5E7EB),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: isDark
                                    ? const BorderSide(color: Colors.yellow)
                                    : BorderSide.none,
                              ),
                            ),
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                color:
                                    isDark ? Colors.yellow : Colors.black87,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 16),

                      Expanded(
                        child: SizedBox(
                          height: 54,
                          child: ElevatedButton(
                            onPressed: () async {
                              await OfflineService.clearLoggedInUser();
                              if (!context.mounted) return;
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(
                                  builder: (_) => const LoginView(),
                                ),
                                (route) => false,
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.primary,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: isDark
                                    ? const BorderSide(color: Colors.yellow)
                                    : BorderSide.none,
                              ),
                            ),
                            child: Text(
                              'Logout',
                              style: TextStyle(
                                color: isDark ? Colors.black : Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
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
          ],
        ),
      ),
    );
  }
}