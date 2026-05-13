import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../profile/accessibility_settings_view.dart';
import 'cv_controller.dart';
import 'cv_form_view.dart';
import 'cv_detail_view.dart';

class CvView extends StatefulWidget {
  final Map<String, dynamic> currentUser;

  const CvView({super.key, required this.currentUser});

  @override
  State<CvView> createState() => _CvViewState();
}

class _CvViewState extends State<CvView> {
  Map<String, dynamic>? cvData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCv();
  }

  Future<void> _fetchCv() async {
    setState(() => isLoading = true);
    final data = await CvController.getCvByUserId(widget.currentUser['_id']);
    if (mounted) {
      setState(() {
        cvData = data;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.primaryNavy)),
      );
    }

    return ValueListenableBuilder<bool>(
      valueListenable: AccessibilityController.highContrastNotifier,
      builder: (context, isHighContrast, _) {
        final bgColor = isHighContrast ? AccessibilityTheme.black : Colors.white;
        return Scaffold(
          backgroundColor: bgColor,
          body: cvData == null ? _buildEmptyState(context, isHighContrast) : _buildCvCard(context, isHighContrast),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isHighContrast) {
    final bgColor = isHighContrast ? AccessibilityTheme.black : Colors.white;
    final textColor = isHighContrast ? AccessibilityTheme.yellow : AppColors.primaryNavy;
    final subtextColor = isHighContrast ? Colors.white70 : Colors.grey;
    final buttonBgColor = isHighContrast ? AccessibilityTheme.yellow : AppColors.primaryNavy;
    final buttonTextColor = isHighContrast ? AccessibilityTheme.black : Colors.white;
    final circleBgColor = isHighContrast 
        ? AccessibilityTheme.yellow.withOpacity(0.1) 
        : AppColors.primaryNavy.withOpacity(0.05);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: circleBgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.description_outlined, size: 80, color: textColor),
            ),
            const SizedBox(height: 24),
            Text(
              'Belum ada CV',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor),
            ),
            const SizedBox(height: 12),
            Text(
              'Buat CV digital agar kamu dapat melamar pekerjaan dengan lebih mudah.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: subtextColor, height: 1.5),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => CvFormView(currentUser: widget.currentUser)),
                  );
                  if (result == true) _fetchCv();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: buttonBgColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text('Buat CV', style: TextStyle(color: buttonTextColor, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCvCard(BuildContext context, bool isHighContrast) {
    final List skills = cvData!['skills'] ?? [];
    final cardBgColor = isHighContrast ? AccessibilityTheme.darkCard : Colors.white;
    final textColor = isHighContrast ? AccessibilityTheme.yellow : AppColors.primaryNavy;
    final bodyTextColor = isHighContrast ? Colors.white.withOpacity(0.87) : Colors.black87;
    final buttonColor = isHighContrast ? AccessibilityTheme.yellow : AppColors.primaryNavy;
    final buttonBgColor = isHighContrast ? AccessibilityTheme.black : Colors.white;
    final outlineBorderColor = isHighContrast ? AccessibilityTheme.yellow : AppColors.primaryNavy;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: cardBgColor,
              borderRadius: BorderRadius.circular(24),
              border: isHighContrast ? Border.all(color: AccessibilityTheme.yellow, width: 1) : null,
              boxShadow: isHighContrast ? [] : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.person_outline, color: textColor),
                    const SizedBox(width: 8),
                    Text('Ringkasan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor)),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  cvData!['summary'] ?? '-',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 15, color: bodyTextColor),
                ),
                const SizedBox(height: 20),
                Divider(color: isHighContrast ? Colors.white24 : null),
                const SizedBox(height: 12),
                Text(
                  '${skills.length} Keahlian ditambahkan',
                  style: TextStyle(fontWeight: FontWeight.w600, color: textColor),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => CvFormView(currentUser: widget.currentUser, existingCv: cvData)),
                          );
                          if (result == true) _fetchCv();
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: outlineBorderColor,
                          side: BorderSide(color: outlineBorderColor),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('Edit CV', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => CvDetailView(cvData: cvData!, currentUser: widget.currentUser)),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: buttonColor,
                          foregroundColor: isHighContrast ? AccessibilityTheme.black : Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text('Lihat CV', style: TextStyle(color: isHighContrast ? AccessibilityTheme.black : Colors.white, fontWeight: FontWeight.bold)),
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
}
