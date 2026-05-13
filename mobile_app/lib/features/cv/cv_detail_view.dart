import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../profile/accessibility_settings_view.dart';
import 'cv_form_view.dart';

class CvDetailView extends StatelessWidget {
  final Map<String, dynamic> cvData;
  final Map<String, dynamic> currentUser;
  final bool isReadOnly;

  const CvDetailView({super.key, required this.cvData, required this.currentUser, this.isReadOnly = false});

  @override
  Widget build(BuildContext context) {
    final List education = cvData['education'] ?? [];
    final List experience = cvData['experience'] ?? [];
    final List skills = cvData['skills'] ?? [];
    final List certifications = cvData['certifications'] ?? [];

    return ValueListenableBuilder<bool>(
      valueListenable: AccessibilityController.highContrastNotifier,
      builder: (context, isHighContrast, _) {
        final bgColor = isHighContrast ? AccessibilityTheme.black : Colors.white;
        final appBarTextColor = isHighContrast ? AccessibilityTheme.yellow : AppColors.primaryNavy;
        final titleTextColor = isHighContrast ? AccessibilityTheme.yellow : AppColors.primaryNavy;
        final bodyTextColor = isHighContrast ? Colors.white.withOpacity(0.87) : Colors.black;
        final subtextColor = isHighContrast ? Colors.white54 : Colors.grey;
        final chipBgColor = isHighContrast 
            ? AccessibilityTheme.yellow.withOpacity(0.15)
            : AppColors.primaryNavy.withOpacity(0.05);
        final chipBorderColor = isHighContrast 
            ? AccessibilityTheme.yellow.withOpacity(0.3)
            : AppColors.primaryNavy.withOpacity(0.2);
        final chipTextColor = isHighContrast ? AccessibilityTheme.yellow : AppColors.primaryNavy;
        final iconBgColor = isHighContrast 
            ? AccessibilityTheme.yellow.withOpacity(0.15)
            : Colors.grey.withOpacity(0.1);
        final iconColor = isHighContrast ? AccessibilityTheme.yellow : AppColors.primaryNavy;

        return Scaffold(
          backgroundColor: bgColor,
          appBar: AppBar(
            title: Text('Detail CV', style: TextStyle(fontWeight: FontWeight.bold, color: appBarTextColor)),
            backgroundColor: bgColor,
            elevation: 0,
            iconTheme: IconThemeData(color: appBarTextColor),
            actions: [
              if (!isReadOnly)
                TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => CvFormView(currentUser: currentUser, existingCv: cvData)),
                    );
                  },
                  icon: Icon(Icons.edit, size: 18, color: appBarTextColor),
                  label: Text('Edit', style: TextStyle(color: appBarTextColor)),
                ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSection('Ringkasan Diri', cvData['summary'] ?? '-', Icons.person_outline,
                    titleColor: titleTextColor,
                    bodyColor: bodyTextColor,
                    iconColor: iconColor,
                    iconBgColor: iconBgColor,
                ),
                const SizedBox(height: 32),
                
                _buildTitle('Pendidikan', titleTextColor),
                ...education.map((e) => _buildDetailItem(
                  e['school'] ?? '-',
                  '${e['major'] ?? '-'} (${e['year'] ?? '-'})',
                  Icons.school_outlined,
                  bodyTextColor: bodyTextColor,
                  subtextColor: subtextColor,
                  iconColor: iconColor,
                  iconBgColor: iconBgColor,
                )),
                const SizedBox(height: 32),

                _buildTitle('Pengalaman Kerja', titleTextColor),
                ...experience.map((e) => _buildDetailItem(
                  e['position'] ?? '-',
                  '${e['company'] ?? '-'} | ${e['duration'] ?? '-'}',
                  Icons.work_outline,
                  description: e['description'],
                  bodyTextColor: bodyTextColor,
                  subtextColor: subtextColor,
                  iconColor: iconColor,
                  iconBgColor: iconBgColor,
                )),
                const SizedBox(height: 32),

                _buildTitle('Keahlian', titleTextColor),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: skills.map((s) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: chipBgColor,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: chipBorderColor),
                    ),
                    child: Text(s.toString(), style: TextStyle(color: chipTextColor, fontWeight: FontWeight.w600)),
                  )).toList(),
                ),
                const SizedBox(height: 32),

                _buildTitle('Sertifikasi', titleTextColor),
                ...certifications.map((c) => _buildDetailItem(
                  c.toString(),
                  null,
                  Icons.verified_user_outlined,
                  bodyTextColor: bodyTextColor,
                  subtextColor: subtextColor,
                  iconColor: iconColor,
                  iconBgColor: iconBgColor,
                )),
                const SizedBox(height: 32),

                if (cvData['portfolio_link'] != null && cvData['portfolio_link'].toString().isNotEmpty)
                  _buildSection(
                    'Portofolio',
                    cvData['portfolio_link'],
                    Icons.link,
                    isLink: true,
                    titleColor: titleTextColor,
                    bodyColor: bodyTextColor,
                    iconColor: iconColor,
                    iconBgColor: iconBgColor,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTitle(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
    );
  }

  Widget _buildSection(
    String title,
    String content,
    IconData icon, {
    bool isLink = false,
    required Color titleColor,
    required Color bodyColor,
    required Color iconColor,
    required Color iconBgColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: 8),
            Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: titleColor)),
          ],
        ),
        const SizedBox(height: 12),
        if (isLink)
          InkWell(
            onTap: () async {
              final url = Uri.parse(content.startsWith('http') ? content : 'https://$content');
              try {
                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                }
              } catch (e) {
                // Silently fail
              }
            },
            child: Text(
              content,
              style: TextStyle(
                fontSize: 16,
                color: Colors.blue,
                decoration: TextDecoration.underline,
                height: 1.5,
              ),
            ),
          )
        else
          Text(content, style: TextStyle(fontSize: 16, color: bodyColor, height: 1.5)),
      ],
    );
  }

  Widget _buildDetailItem(
    String title,
    String? subtitle,
    IconData icon, {
    String? description,
    required Color bodyTextColor,
    required Color subtextColor,
    required Color iconColor,
    required Color iconBgColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: iconBgColor, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: bodyTextColor)),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(fontSize: 14, color: subtextColor)),
                ],
                if (description != null) ...[
                  const SizedBox(height: 8),
                  Text(description, style: TextStyle(fontSize: 14, color: subtextColor)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}