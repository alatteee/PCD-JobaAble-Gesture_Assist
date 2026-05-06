import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
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

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Detail CV', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryNavy)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.primaryNavy),
        actions: [
          if (!isReadOnly)
            TextButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => CvFormView(currentUser: currentUser, existingCv: cvData)),
                );
              },
              icon: const Icon(Icons.edit, size: 18),
              label: const Text('Edit'),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection('Ringkasan Diri', cvData['summary'] ?? '-', Icons.person_outline),
            const SizedBox(height: 32),
            
            _buildTitle('Pendidikan'),
            ...education.map((e) => _buildDetailItem(
              e['school'] ?? '-',
              '${e['major'] ?? '-'} (${e['year'] ?? '-'})',
              Icons.school_outlined,
            )),
            const SizedBox(height: 32),

            _buildTitle('Pengalaman Kerja'),
            ...experience.map((e) => _buildDetailItem(
              e['position'] ?? '-',
              '${e['company'] ?? '-'} | ${e['duration'] ?? '-'}',
              Icons.work_outline,
              description: e['description'],
            )),
            const SizedBox(height: 32),

            _buildTitle('Keahlian'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: skills.map((s) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primaryNavy.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.primaryNavy.withOpacity(0.2)),
                ),
                child: Text(s.toString(), style: const TextStyle(color: AppColors.primaryNavy, fontWeight: FontWeight.w600)),
              )).toList(),
            ),
            const SizedBox(height: 32),

            _buildTitle('Sertifikasi'),
            ...certifications.map((c) => _buildDetailItem(c.toString(), null, Icons.verified_user_outlined)),
            const SizedBox(height: 32),

            if (cvData['portfolio_link'] != null && cvData['portfolio_link'].toString().isNotEmpty)
              _buildSection(
                'Portofolio',
                cvData['portfolio_link'],
                Icons.link,
                isLink: true,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryNavy)),
    );
  }

  Widget _buildSection(String title, String content, IconData icon, {bool isLink = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: AppColors.primaryNavy, size: 20),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryNavy)),
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
                // Silently fail or show snackbar
              }
            },
            child: Text(
              content,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.blue,
                decoration: TextDecoration.underline,
                height: 1.5,
              ),
            ),
          )
        else
          Text(content, style: const TextStyle(fontSize: 16, color: Colors.black87, height: 1.5)),
      ],
    );
  }

  Widget _buildDetailItem(String title, String? subtitle, IconData icon, {String? description}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppColors.primaryNavy.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: AppColors.primaryNavy, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
                ],
                if (description != null) ...[
                  const SizedBox(height: 8),
                  Text(description, style: const TextStyle(fontSize: 14, color: Colors.black54)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
