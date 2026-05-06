import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class CompanyHelpPage extends StatefulWidget {
  const CompanyHelpPage({super.key});

  @override
  State<CompanyHelpPage> createState() => _CompanyHelpPageState();
}

class _CompanyHelpPageState extends State<CompanyHelpPage> {
  int expandedIndex = 0;

  static const Color navy = Color(0xFF0B1B55);
  static const Color textDark = Color(0xFF07122F);
  static const Color subtitleColor = Color(0xFF8D94A6);
  static const Color iconBg = Color(0xFFD9E6FF);
  static const Color dividerColor = Color(0xFFBFC5D2);
  static const Color contentTextColor = Color(0xFF303B63);

  Future<void> _launchEmail() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'azkha.nazzala.tif24@polban.ac.id',
      query: 'subject=Bantuan Aplikasi JobAble - Perusahaan',
    );

    if (!await launchUrl(emailLaunchUri)) {
      throw Exception('Could not launch $emailLaunchUri');
    }
  }

  Future<void> _launchWhatsApp() async {
    final Uri whatsappUri = Uri.parse('https://wa.me/6282119765944');

    if (!await launchUrl(
      whatsappUri,
      mode: LaunchMode.externalApplication,
    )) {
      throw Exception('Could not launch $whatsappUri');
    }
  }

  void _toggleCard(int index) {
    setState(() {
      expandedIndex = expandedIndex == index ? -1 : index;
    });
  }

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
              _buildHeader(),
              const SizedBox(height: 28),

              const Text(
                'Temukan informasi dan bantuan untuk menggunakan aplikasi JobAble sebagai perusahaan',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: subtitleColor,
                  height: 1.25,
                ),
              ),

              const SizedBox(height: 24),

              _buildHelpCard(
                index: 0,
                icon: Icons.help_outline_rounded,
                title: 'Cara Menggunakan',
                subtitle:
                    'Ikuti langkah-langkah berikut untuk menggunakan akun perusahaan',
                children: [
                  _buildStepItem('1.', 'Login atau daftar sebagai perusahaan'),
                  _buildStepItem('2.', 'Lengkapi profil perusahaan'),
                  _buildStepItem('3.', 'Buat dan publikasikan lowongan'),
                  _buildStepItem('4.', 'Kelola pelamar yang masuk'),
                ],
              ),

              const SizedBox(height: 16),

              _buildHelpCard(
                index: 1,
                icon: Icons.work_outline_rounded,
                title: 'Cara Membuat Lowongan',
                subtitle:
                    'Pelajari langkah-langkah membuat lowongan pekerjaan',
                children: [
                  _buildStepItem('1.', 'Buka menu Lowongan'),
                  _buildStepItem('2.', 'Tekan tombol tambah lowongan'),
                  _buildStepItem(
                    '3.',
                    'Isi judul, lokasi, tipe kerja, dan deskripsi',
                  ),
                  _buildStepItem('4.', 'Simpan agar lowongan tampil di aplikasi'),
                ],
              ),

              const SizedBox(height: 16),

              _buildHelpCard(
                index: 2,
                icon: Icons.groups_rounded,
                title: 'Mengelola Pelamar',
                subtitle:
                    'Lihat dan kelola daftar pelamar yang mendaftar ke lowongan',
                children: [
                  _buildStepItem('1.', 'Buka menu Pelamar'),
                  _buildStepItem('2.', 'Pilih pelamar yang ingin dilihat'),
                  _buildStepItem('3.', 'Periksa detail data dan lamaran pelamar'),
                  _buildStepItem('4.', 'Ubah status pelamar jika diperlukan'),
                ],
              ),

              const SizedBox(height: 16),

              _buildHelpCard(
                index: 3,
                icon: Icons.business_rounded,
                title: 'Profil Perusahaan',
                subtitle:
                    'Atur informasi perusahaan agar pelamar lebih percaya',
                children: [
                  _buildStepItem('•', 'Tambahkan nama dan email perusahaan'),
                  _buildStepItem('•', 'Lengkapi alamat dan nomor telepon'),
                  _buildStepItem('•', 'Tulis deskripsi singkat perusahaan'),
                  _buildStepItem('•', 'Pastikan data selalu terbaru'),
                ],
              ),

              const SizedBox(height: 16),

              _buildHelpCard(
                index: 4,
                icon: Icons.accessibility_new_rounded,
                title: 'Aksesibilitas',
                subtitle:
                    'Gunakan aplikasi dengan tampilan yang ramah aksesibilitas',
                children: [
                  _buildStepItem('•', 'Gunakan teks yang jelas dan mudah dibaca'),
                  _buildStepItem('•', 'Pastikan informasi lowongan tidak ambigu'),
                  _buildStepItem('•', 'Cantumkan fasilitas ramah disabilitas'),
                  _buildStepItem('•', 'Gunakan bahasa yang inklusif'),
                ],
              ),

              const SizedBox(height: 16),

              _buildHelpCard(
                index: 5,
                icon: Icons.phone_in_talk_rounded,
                title: 'Hubungi Kami',
                subtitle:
                    'Butuh bantuan lebih lanjut? Hubungi tim kami melalui kontak berikut.',
                children: [
                  _buildContactItem(
                    label: 'Email',
                    value: 'azkha.nazzala.tif24@polban.ac.id',
                    onTap: _launchEmail,
                  ),
                  _buildContactItem(
                    label: 'WA',
                    value: '082119765944',
                    onTap: _launchWhatsApp,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
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
            'Bantuan',
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

  Widget _buildHelpCard({
    required int index,
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Widget> children,
  }) {
    final bool isExpanded = expandedIndex == index;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _toggleCard(index),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: iconBg,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      color: navy,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),

                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: navy,
                              height: 1.25,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            subtitle,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: subtitleColor,
                              height: 1.25,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Icon(
                      isExpanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: navy,
                      size: 30,
                    ),
                  ),
                ],
              ),

              if (isExpanded) ...[
                const SizedBox(height: 18),
                Padding(
                  padding: const EdgeInsets.only(left: 70, right: 4),
                  child: Column(
                    children: children,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepItem(String number, String text) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: iconBg,
                shape: BoxShape.circle,
              ),
              child: Text(
                number,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: navy,
                ),
              ),
            ),
            const SizedBox(width: 12),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  text,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: contentTextColor,
                    height: 1.3,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          margin: const EdgeInsets.only(left: 42),
          height: 1,
          color: dividerColor,
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildContactItem({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: navy,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: contentTextColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}