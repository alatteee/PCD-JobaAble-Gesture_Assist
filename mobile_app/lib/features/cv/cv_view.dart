import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
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

    return Scaffold(
      backgroundColor: Colors.white,
      body: cvData == null ? _buildEmptyState() : _buildCvCard(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primaryNavy.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.description_outlined, size: 80, color: AppColors.primaryNavy),
            ),
            const SizedBox(height: 24),
            const Text(
              'Belum ada CV',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primaryNavy),
            ),
            const SizedBox(height: 12),
            const Text(
              'Buat CV digital agar kamu dapat melamar pekerjaan dengan lebih mudah.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey, height: 1.5),
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
                  backgroundColor: AppColors.primaryNavy,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Buat CV', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCvCard() {
    final List skills = cvData!['skills'] ?? [];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
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
                const Row(
                  children: [
                    Icon(Icons.person_outline, color: AppColors.primaryNavy),
                    SizedBox(width: 8),
                    Text('Ringkasan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  cvData!['summary'] ?? '-',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 15, color: Colors.black87),
                ),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 12),
                Text(
                  '${skills.length} Keahlian ditambahkan',
                  style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.primaryNavy),
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
                          side: const BorderSide(color: AppColors.primaryNavy),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('Edit CV', style: TextStyle(color: AppColors.primaryNavy, fontWeight: FontWeight.bold)),
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
                          backgroundColor: AppColors.primaryNavy,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('Lihat CV', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
