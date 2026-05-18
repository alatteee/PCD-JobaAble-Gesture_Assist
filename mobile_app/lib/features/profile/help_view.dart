import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpView extends StatelessWidget {
  const HelpView({super.key});

  Future<void> _launchEmail() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'azkha.nazzala.tif24@polban.ac.id',
      query: 'subject=Bantuan Aplikasi JobAble',
    );
    if (!await launchUrl(emailLaunchUri)) {
      throw Exception('Could not launch $emailLaunchUri');
    }
  }

  Future<void> _launchWhatsApp() async {
    final Uri whatsappUri = Uri.parse("https://wa.me/6282119765944");
    if (!await launchUrl(whatsappUri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $whatsappUri');
    }
  }

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
          'Bantuan',
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Temukan informasi dan bantuan untuk menggunakan aplikasi JobAble',
              style: TextStyle(
                fontSize: 16,
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            _buildHelpCard(
              context,
              icon: Icons.help_outline,
              title: 'Cara Menggunakan',
              subtitle: 'Ikuti langkah - langkah berikut untuk menggunakan aplikasi JobAble',
              isExpanded: true,
              children: [
                _buildStepItem(context, '1.', 'Login atau daftar akun'),
                _buildStepItem(context, '2.', 'Lengkapi profil anda'),
                _buildStepItem(context, '3.', 'Cari lowongan pekerjaan'),
                _buildStepItem(context, '4.', 'Kirim lamaran pekerjaan'),
              ],
            ),
            const SizedBox(height: 16),
            _buildHelpCard(
              context,
              icon: Icons.description_outlined,
              title: 'Cara Melamar Pekerjaan',
              subtitle: 'Pelajari langkah-langkah melamar pekerjaan melalui aplikasi',
              children: [
                _buildStepItem(context, '1.', 'Buka tab Beranda atau Cari Lowongan'),
                _buildStepItem(context, '2.', 'Pilih lowongan yang sesuai minat Anda'),
                _buildStepItem(context, '3.', 'Klik tombol "Lamar Sekarang"'),
                _buildStepItem(context, '4.', 'Tunggu konfirmasi dari pihak perusahaan'),
              ],
            ),
            const SizedBox(height: 16),
            _buildHelpCard(
              context,
              icon: Icons.accessibility_new_outlined,
              title: 'Pengaturan Aksesibilitas',
              subtitle: 'Sesuaikan aplikasi agar lebih mudah digunakan sesuai kebutuhan anda.',
              children: [
                _buildStepItem(context, '•', 'Gunakan fitur Screen Reader untuk tunanetra'),
                _buildStepItem(context, '•', 'Aktifkan High Contrast untuk penglihatan rendah'),
                _buildStepItem(context, '•', 'Sesuaikan ukuran font di Pengaturan Akun'),
              ],
            ),
            const SizedBox(height: 16),
            _buildHelpCard(
              context,
              icon: Icons.phone_in_talk_outlined,
              title: 'Hubungi Kami',
              subtitle: 'Butuh bantuan lebih lanjut? Hubungi tim kami melalui kontak berikut.',
              children: [
                _buildStepItem(context, 'Email', 'azkha.nazzala.tif24@polban.ac.id'),
                _buildStepItem(context, 'WA', '082119765944'),
              ],
            ),
            const SizedBox(height: 32),
            
            // Footer Contact Section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? Colors.black : const Color(0xFFF3F6FF),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: isDark ? Colors.yellow : const Color(0xFFE0E7FF)),
              ),
              child: Column(
                children: [
                  Text(
                    'Masih butuh bantuan?',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tim kami siap membantu Anda kapan saja melalui email atau formulir kontak.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: theme.textTheme.bodySmall?.color, height: 1.4),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _launchEmail,
                          icon: const Icon(Icons.email_outlined, size: 18),
                          label: const Text('Email Kami', style: TextStyle(fontSize: 12)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: theme.colorScheme.primary,
                            side: BorderSide(color: theme.colorScheme.primary),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _launchWhatsApp,
                          icon: const Icon(Icons.chat_bubble_outline, size: 18),
                          label: const Text('Formulir Kontak', style: TextStyle(fontSize: 12)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: isDark ? Colors.black : Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    bool isExpanded = false,
    List<Widget>? children,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.black : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDark ? [] : [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: isDark ? Colors.yellow : Colors.grey.shade100),
      ),
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: isExpanded,
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: theme.colorScheme.primary),
          ),
          title: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
              fontSize: 16,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: TextStyle(
              fontSize: 13,
              color: theme.textTheme.bodySmall?.color,
              height: 1.4,
            ),
          ),
          trailing: Icon(
            isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
            color: theme.colorScheme.primary,
          ),
          children: children ?? [],
        ),
      ),
    );
  }

  Widget _buildStepItem(BuildContext context, String number, String text) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 72, right: 24, bottom: 16),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  number,
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.textTheme.bodyMedium?.color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
