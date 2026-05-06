import 'package:flutter/material.dart';
import '../../services/mongo_service.dart';
import 'company_profile_detail_page.dart';
import 'package:mobile_app/features/auth/login_view.dart';
import 'company_account_settings_page.dart';
import 'company_help_page.dart';
import 'company_about_page.dart';

class CompanyProfilePage extends StatefulWidget {
  final String companyName;
  final Map<String, dynamic> userData;

  const CompanyProfilePage({
    super.key,
    required this.companyName,
    required this.userData,
  });

  @override
  State<CompanyProfilePage> createState() => _CompanyProfilePageState();
}

class _CompanyProfilePageState extends State<CompanyProfilePage> {
  Map<String, dynamic>? companyData;
  bool isLoading = true;

  static const Color navy = Color(0xFF0B1B55);
  static const Color textDark = Color(0xFF07122F);
  static const Color subtitle = Color(0xFF5B6475);
  static const Color iconBg = Color(0xFF8FAEF7);

  @override
  void initState() {
    super.initState();
    _loadCompanyProfile();
  }

  Future<void> _loadCompanyProfile() async {
    setState(() {
      isLoading = true;
    });

    // Get userId from userData
    final userId = widget.userData['_id'];
    
    // Fetch company using user_id instead of company name
    final data = userId != null 
        ? await MongoService.getCompanyByUserId(userId)
        : await MongoService.getCompanyByName(widget.companyName);

    if (!mounted) return;

    setState(() {
      companyData = data;
      isLoading = false;
    });
  }

  Future<void> _goToProfileDetail() async {
    if (companyData == null) {
      _showSnackBar('Data perusahaan belum tersedia');
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CompanyProfileDetailPage(
          companyData: companyData!,
        ),
      ),
    );

    if (result == true) {
      await _loadCompanyProfile();
    }
  }

  void _goToAccountSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CompanyAccountSettingsPage(
          currentUser: widget.userData,
        ),
      ),
    );
  }

  void _goToHelpPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const CompanyHelpPage(),
      ),
    );
  }

  void _goToAboutPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const CompanyAboutPage(),
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _handleLogout() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 42),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(22, 16, 22, 26),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.16),
                  blurRadius: 16,
                  offset: const Offset(0, 7),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(dialogContext),
                    child: const Icon(
                      Icons.close,
                      color: navy,
                      size: 24,
                    ),
                  ),
                ),

                const SizedBox(height: 6),

                const Icon(
                  Icons.logout_rounded,
                  color: navy,
                  size: 78,
                ),

                const SizedBox(height: 18),

                const Text(
                  'Logout Account?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    color: textDark,
                  ),
                ),

                const SizedBox(height: 12),

                Text(
                  'Apakah anda yakin akan logout\ndari akun anda?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade400,
                    height: 1.35,
                  ),
                ),

                const SizedBox(height: 28),

                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE0E0E0),
                            foregroundColor: textDark,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 16),

                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(dialogContext);

                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(
                                builder: (_) => const LoginView(),
                              ),
                              (route) => false,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: navy,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            'Logout',
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w900,
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

  @override
  Widget build(BuildContext context) {
    final companyName =
        companyData?['company_name']?.toString() ?? widget.companyName;
    final email = companyData?['email']?.toString() ?? '-';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: navy,
                ),
              )
            : RefreshIndicator(
                onRefresh: _loadCompanyProfile,
                color: navy,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(24, 22, 24, 115),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),

                      const SizedBox(height: 24),

                      _buildTopProfile(
                        companyName: companyName,
                        email: email,
                      ),

                      const SizedBox(height: 30),

                      _buildMenuCard(
                        icon: Icons.settings,
                        title: 'Pengaturan Akun',
                        onTap: _goToAccountSettings,
                      ),

                      const SizedBox(height: 14),

                      _buildMenuCard(
                        icon: Icons.question_mark_rounded,
                        title: 'Bantuan',
                        onTap: _goToHelpPage,
                      ),

                      const SizedBox(height: 14),

                      _buildMenuCard(
                        icon: Icons.info_rounded,
                        title: 'Tentang Aplikasi',
                        onTap: _goToAboutPage,
                      ),

                      const SizedBox(height: 14),

                      _buildMenuCard(
                        icon: Icons.logout_rounded,
                        title: 'Logout',
                        onTap: _handleLogout,
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildHeader() {
    return const Row(
      children: [
        Expanded(
          child: Text(
            'Profil Perusahaan',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.w900,
              color: navy,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopProfile({
    required String companyName,
    required String email,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildCompanyLogo(),

        const SizedBox(width: 18),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                companyName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: textDark,
                ),
              ),

              const SizedBox(height: 5),

              Text(
                email,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: subtitle,
                ),
              ),

              const SizedBox(height: 12),

              SizedBox(
                width: 135,
                height: 34,
                child: OutlinedButton(
                  onPressed: _goToProfileDetail,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: navy,
                    side: const BorderSide(
                      color: navy,
                      width: 1.5,
                    ),
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                  ),
                  child: const Text(
                    'Lihat Profil',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCompanyLogo() {
    return Container(
      width: 82,
      height: 82,
      decoration: BoxDecoration(
        color: iconBg,
        borderRadius: BorderRadius.circular(19),
      ),
      child: const Icon(
        Icons.apartment_rounded,
        color: navy,
        size: 52,
      ),
    );
  }

  Widget _buildMenuCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        height: 62,
        padding: const EdgeInsets.symmetric(horizontal: 22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
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
                color: navy,
                size: 27,
              ),
            ),

            const SizedBox(width: 28),

            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w900,
                  color: textDark,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}