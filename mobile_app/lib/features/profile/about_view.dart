import 'package:flutter/material.dart';

class AboutView extends StatelessWidget {
  const AboutView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Tentang Aplikasi',
          style: TextStyle(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: isDark ? Colors.black : Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: isDark
                ? []
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
            border:
                Border.all(color: isDark ? Colors.yellow : Colors.grey.shade100),
          ),
          child: Column(
            children: [
              const SizedBox(height: 40),
              // Logo
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    Icons.people_alt,
                    color: isDark ? Colors.black : Colors.white,
                    size: 50,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'JobAble',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              Text(
                'KERJA INKLUSIF UNTUK SEMUA',
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 1.5,
                  color: theme.textTheme.bodySmall?.color,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 32),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Text(
                  'JobAble adalah aplikasi mobile yang dirancang untuk membantu penyandang disabilitas dalam mencari lowongan pekerjaan dan melamar secara mudah, inklusif dan aksesibel',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                    height: 1.6,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Divider(
                  height: 1,
                  indent: 24,
                  endIndent: 24,
                  color: isDark ? Colors.yellow : null),

              _buildInfoTile(
                context,
                icon: Icons.info_outline,
                title: 'Versi Aplikasi',
                subtitle: '1.0.0 (Build 100)',
              ),
              Divider(
                  height: 1,
                  indent: 24,
                  endIndent: 24,
                  color: isDark ? Colors.yellow : null),

              _buildInfoTile(
                context,
                icon: Icons.code,
                title: 'Dikembangkan Oleh',
                subtitle: 'Azkha Nazzala | Rahma Attaya | Zahra Aldila',
              ),
              Divider(
                  height: 1,
                  indent: 24,
                  endIndent: 24,
                  color: isDark ? Colors.yellow : null),

              _buildInfoTile(
                context,
                icon: Icons.copyright,
                title: 'Hak Cipta',
                subtitle: '2026 JobAble. Semua hak dilindungi',
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: theme.colorScheme.primary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.textTheme.bodySmall?.color,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.titleMedium?.color,
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
