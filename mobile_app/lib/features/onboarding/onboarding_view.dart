import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../auth/login_view.dart';
import '../auth/sign_up_view.dart';
import 'widgets/dot_indicator.dart';
import 'widgets/onboarding_page_content.dart';

class OnboardingView extends StatefulWidget {
  const OnboardingView({super.key});

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _onboardingData = [
    {
      'title': 'Welcome To JobAble',
      'description': '',
      'image': 'assets/images/onboarding1.png',
    },
    {
      'title': 'Temukan Pekerjaan yang\nSesuai untuk Anda',
      'description': 'Cari dan lamar pekerjaan dengan mudah melalui aplikasi yang inklusif dan ramah disabilitas',
      'image': 'assets/images/onboarding2.png',
    },
    {
      'title': 'Cari dan Lamar Pekerjaan\ndengan Mudah',
      'description': 'Temukan lowongan yang sesuai kebutuhan Anda dan lamar langsung dari aplikasi',
      'image': 'assets/images/onboarding3.png',
    },
    {
      'title': 'Akses Mudah Bagi\nSemua Pengguna',
      'description': 'Kami menyediakan mode aksebilitas untuk membantu anda menggunakan aplikasi ini dengan nyaman',
      'image': 'assets/images/onboarding4.png',
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onSkip() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const LoginView()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bool isLastPage = _currentPage == _onboardingData.length - 1;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _onSkip,
                child: Text(
                  'Lewati',
                  style: TextStyle(
                    color: isDark ? Colors.yellow : AppColors.primaryNavy,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _onboardingData.length,
                itemBuilder: (context, index) {
                  return OnboardingPageContent(
                    title: _onboardingData[index]['title']!,
                    description: _onboardingData[index]['description']!,
                    imagePath: _onboardingData[index]['image']!,
                    isFirstPage: index == 0,
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 30),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _onboardingData.length,
                  (index) => DotIndicator(
                    isActive: index == _currentPage,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
              child: Row(
                children: [
                  if (isLastPage)
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const LoginView()),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark ? Colors.black : AppColors.lightGrayBtn,
                          foregroundColor: isDark ? Colors.yellow : AppColors.primaryNavy,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                            side: isDark ? const BorderSide(color: Colors.yellow) : BorderSide.none,
                          ),
                        ),
                        child: const Text(
                          'Log In',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    )
                  else if (_currentPage > 0)
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          _pageController.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark ? Colors.black : AppColors.lightGrayBtn,
                          foregroundColor: isDark ? Colors.yellow : AppColors.primaryNavy,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                            side: isDark ? const BorderSide(color: Colors.yellow) : BorderSide.none,
                          ),
                        ),
                        child: const Text(
                          'Kembali',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  if (isLastPage || _currentPage > 0) const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (isLastPage) {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const SignUpView()),
                          );
                        } else {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark ? Colors.yellow : AppColors.primaryNavy,
                        foregroundColor: isDark ? Colors.black : Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: Text(
                        isLastPage ? 'Sign Up' : 'Selanjutnya',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
