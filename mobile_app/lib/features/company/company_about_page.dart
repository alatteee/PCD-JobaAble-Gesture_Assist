import 'package:flutter/material.dart';

class CompanyAboutPage extends StatelessWidget {
  const CompanyAboutPage({super.key});

  static const Color navy = Color(0xFF0B1B55);
  static const Color textDark = Color(0xFF07122F);
  static const Color subtitleColor = Color(0xFF8D94A6);
  static const Color iconBg = Color(0xFFD9E6FF);
  static const Color dividerColor = Color(0xFFE4E7EF);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),

              const SizedBox(height: 28),

              _buildAboutCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(
            Icons.arrow_back,
            color: navy,
            size: 32,
          ),
        ),

        const SizedBox(width: 16),

        const Expanded(
          child: Text(
            'Tentang Aplikasi',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: navy,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAboutCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 30, 22, 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 86,
            height: 86,
            decoration: const BoxDecoration(
              color: navy,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.business_center_rounded,
              color: Colors.white,
              size: 42,
            ),
          ),

          const SizedBox(height: 16),

          const Text(
            'JobAble',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: navy,
            ),
          ),

          const SizedBox(height: 4),

          const Text(
            'KERJA INKLUSIF UNTUK SEMUA',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              letterSpacing: 1.2,
              color: subtitleColor,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 24),

          const Text(
            'JobAble adalah aplikasi mobile yang membantu perusahaan membuat lowongan kerja, mengelola pelamar, dan mendukung proses rekrutmen yang lebih inklusif bagi penyandang disabilitas.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: subtitleColor,
              height: 1.55,
            ),
          ),

          const SizedBox(height: 26),

          const Divider(
            height: 1,
            thickness: 1,
            color: dividerColor,
          ),

          _buildInfoTile(
            icon: Icons.info_outline_rounded,
            title: 'Versi Aplikasi',
            subtitle: '1.0.0 (Build 100)',
          ),

          const Divider(
            height: 1,
            thickness: 1,
            color: dividerColor,
          ),

          _buildInfoTile(
            icon: Icons.business_rounded,
            title: 'Role Pengguna',
            subtitle: 'Perusahaan / Company',
          ),

          const Divider(
            height: 1,
            thickness: 1,
            color: dividerColor,
          ),

          _buildInfoTile(
            icon: Icons.accessibility_new_rounded,
            title: 'Fokus Aplikasi',
            subtitle: 'Rekrutmen kerja inklusif dan aksesibel',
          ),

          const Divider(
            height: 1,
            thickness: 1,
            color: dividerColor,
          ),

          _buildInfoTile(
            icon: Icons.code_rounded,
            title: 'Dikembangkan Oleh',
            subtitle: 'Azkha Nazzala | Rahma Attaya | Zahra Aldila',
          ),

          const Divider(
            height: 1,
            thickness: 1,
            color: dividerColor,
          ),

          _buildInfoTile(
            icon: Icons.copyright_rounded,
            title: 'Hak Cipta',
            subtitle: '2026 JobAble. Semua hak dilindungi',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: navy,
              size: 23,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: subtitleColor,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w900,
                    color: textDark,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}