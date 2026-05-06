import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../onboarding/onboarding_view.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> {
  @override
  void initState() {
    super.initState();
    _navigateToOnboarding();
  }

  Future<void> _navigateToOnboarding() async {
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const OnboardingView()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 120,
              width: 120,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryNavy,
              ),
              child: const Icon(
                Icons.work_outline,
                size: 60,
                color: AppColors.accentBlue,
              ),
            ),
            const SizedBox(height: 24),
            RichText(
              text: const TextSpan(
                style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
                children: [
                  TextSpan(text: 'Job', style: TextStyle(color: AppColors.primaryNavy)),
                  TextSpan(text: 'Able', style: TextStyle(color: AppColors.accentBlue)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'KERJA INKLUSIF UNTUK SEMUA',
              style: TextStyle(
                fontSize: 12,
                letterSpacing: 2.0,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
