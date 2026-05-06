import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../home/home_page.dart';

class ApplicationSuccessPage extends StatelessWidget {
  final Map<String, dynamic> currentUser;

  const ApplicationSuccessPage({
    super.key,
    this.currentUser = const {},
  });

  void _goToHomeTab(BuildContext context, int tabIndex) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => HomePage(
          userData: currentUser,
          initialIndex: tabIndex,
        ),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 10, 24, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(
                      Icons.arrow_back,
                      color: AppColors.primaryNavy,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 18),
                  const Text(
                    'Lamaran Terkirim',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryNavy,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 70),
              Center(
                child: Container(
                  width: 190,
                  height: 190,
                  decoration: BoxDecoration(
                    color: AppColors.accentBlue.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.assignment_turned_in_outlined,
                    size: 128,
                    color: AppColors.primaryNavy,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: AppColors.primaryNavy.withOpacity(0.45)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          color: AppColors.primaryNavy,
                          size: 18,
                        ),
                        SizedBox(width: 7),
                        Text(
                          'Apa Selanjutnya?',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryNavy,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Padding(
                      padding: EdgeInsets.only(left: 25),
                      child: Text(
                        'Kamu akan mendapatkan notifikasi\njika ada update mengenai lamaran\nkamu',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textGray,
                          height: 1.25,
                        ),
                      ),
                    ),
                    const SizedBox(height: 26),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: () => _goToHomeTab(context, 1),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryNavy,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Lihat Lamaran Saya',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 13),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: OutlinedButton(
                        onPressed: () => _goToHomeTab(context, 0),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primaryNavy,
                          side: const BorderSide(color: AppColors.primaryNavy, width: 1.2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Kembali ke Beranda',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 44),
            ],
          ),
        ),
      ),
    );
  }
}
