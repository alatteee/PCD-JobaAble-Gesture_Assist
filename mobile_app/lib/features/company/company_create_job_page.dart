import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../services/mongo_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';

class CompanyCreateJobPage extends StatefulWidget {
  final String companyId;
  final String companyName;

  const CompanyCreateJobPage({
    super.key,
    required this.companyId,
    required this.companyName,
  });

  @override
  State<CompanyCreateJobPage> createState() => _CompanyCreateJobPageState();
}

class _CompanyCreateJobPageState extends State<CompanyCreateJobPage> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _qualificationController = TextEditingController();

  String? _selectedJobType;
  bool _openForDisability = true;
  bool _isLoading = false;
  String? _jobPhotoBase64;

  final List<String> _facilities = [];

  static const Color navy = AppColors.primaryNavy;
  static const Color blue = Color(0xFF2C4494);
  static const Color textGrey = AppColors.textGray;

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _qualificationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (pickedFile == null) return;

      final bytes = await pickedFile.readAsBytes();
      final base64String = base64Encode(bytes);

      setState(() {
        _jobPhotoBase64 = base64String;
      });
    } catch (e) {
      if (mounted) {
        _showSnackBar('Gagal memilih gambar: $e');
      }
    }
  }

  Future<void> _publishJob() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedJobType == null) {
      _showSnackBar('Pilih jenis pekerjaan terlebih dahulu');
      return;
    }

    setState(() => _isLoading = true);

    final now = DateTime.now().toUtc();

    final success = await MongoService.insertJobVacancy(
      data: {
        'company_id': widget.companyId,
        'company_name': widget.companyName,
        'title': _titleController.text.trim(),
        'location': _locationController.text.trim(),
        'job_type': _selectedJobType,
        'category': _selectedJobType,
        'description': _descriptionController.text.trim(),
        'qualification': _qualificationController.text.trim(),
        'facilities': _facilities,
        'is_disability_friendly': _openForDisability,
        'open_for_disability': _openForDisability,
        'job_photo': _jobPhotoBase64,
        'status': 'active',
        'applicant_count': 0,
        'created_at': now,
        'updated_at': now,
      },
    );

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (success) {
      final result = await Navigator.push<String>(
        context,
        MaterialPageRoute(
          builder: (_) => const CompanyJobPublishedPage(),
        ),
      );

      if (!mounted || result == null) return;
      Navigator.pop(context, result);
    } else {
      _showSnackBar('Gagal mempublish lowongan');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showAddFacilityDialog() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Tambah Fasilitas'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'Contoh: Remote Work',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                final value = controller.text.trim();
                if (value.isNotEmpty) {
                  setState(() => _facilities.add(value));
                }
                Navigator.pop(context);
              },
              child: const Text('Tambah'),
            ),
          ],
        );
      },
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: Colors.grey,
        fontSize: 13,
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: navy, width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.red),
      ),
    );
  }

  Widget _label(String text, {String? subtitle}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            text,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: navy,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12,
                color: textGrey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _jobTypeButton(String value) {
    final selected = _selectedJobType == value;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedJobType = value),
        child: Container(
          height: 43,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? navy : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: navy, width: 1.3),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: selected ? Colors.white : navy,
            ),
          ),
        ),
      ),
    );
  }

  Widget _facilityChip(String text) {
    return Container(
      margin: const EdgeInsets.only(right: 8, bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFF91B4FF),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: navy,
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () {
              setState(() => _facilities.remove(text));
            },
            child: const Icon(Icons.close, size: 14, color: navy),
          ),
        ],
      ),
    );
  }

  Widget _addFacilityButton() {
    return GestureDetector(
      onTap: _showAddFacilityDialog,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: navy, width: 1.2),
        ),
        child: const Text(
          '+ Tambah',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: navy,
          ),
        ),
      ),
    );
  }

  Widget _radioOption(bool value, String label) {
    return InkWell(
      onTap: () => setState(() => _openForDisability = value),
      child: Row(
        children: [
          Radio<bool>(
            value: value,
            groupValue: _openForDisability,
            activeColor: navy,
            onChanged: (newValue) {
              if (newValue != null) {
                setState(() => _openForDisability = newValue);
              }
            },
          ),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: navy,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJobPhotoPicker() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        width: double.infinity,
        height: 140,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade300),
          image: _jobPhotoBase64 != null
              ? DecorationImage(
                  image: MemoryImage(base64Decode(_jobPhotoBase64!)),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: _jobPhotoBase64 == null
            ? const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_photo_alternate_outlined, color: navy, size: 42),
                  SizedBox(height: 8),
                  Text(
                    'Tambah Foto Lowongan',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: navy,
                    ),
                  ),
                ],
              )
            : Align(
                alignment: Alignment.topRight,
                child: Container(
                  margin: const EdgeInsets.all(8),
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.black45,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.edit, color: Colors.white, size: 16),
                ),
              ),
      ),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Field ini wajib diisi';
        }
        return null;
      },
      decoration: _inputDecoration(hint),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.arrow_back, color: navy, size: 30),
                    ),
                    const SizedBox(width: 14),
                    const Text(
                      'Buat Lowongan Baru',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: navy,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                const Text(
                  'Isi informasi di bawah ini dengan lengkap',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: navy,
                  ),
                ),
                const SizedBox(height: 24),

                _label('Foto Lowongan', subtitle: 'Pilih gambar yang merepresentasikan pekerjaan.'),
                _buildJobPhotoPicker(),
                const SizedBox(height: 18),

                _label('Nama Pekerjaan'),
                _textField(
                  controller: _titleController,
                  hint: 'Contoh: Customer Service',
                ),
                const SizedBox(height: 18),

                _label('Lokasi'),
                _textField(
                  controller: _locationController,
                  hint: 'Contoh: Bandung, Jawa Barat',
                ),
                const SizedBox(height: 18),

                _label('Jenis Pekerjaan'),
                Row(
                  children: [
                    _jobTypeButton('Full Time'),
                    const SizedBox(width: 14),
                    _jobTypeButton('Part Time'),
                  ],
                ),
                const SizedBox(height: 18),

                _label('Deskripsi Pekerjaan'),
                _textField(
                  controller: _descriptionController,
                  hint: 'Tuliskan deskripsi pekerjaan secara detail...',
                  maxLines: 3,
                ),
                const SizedBox(height: 18),

                _label('Kualifikasi'),
                _textField(
                  controller: _qualificationController,
                  hint: 'Tuliskan kualifikasi yang dibutuhkan...',
                  maxLines: 3,
                ),
                const SizedBox(height: 18),

                _label(
                  'Fasilitas',
                  subtitle: 'Tambahkan fasilitas atau benefit yang diberikan.',
                ),
                Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_facilities.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: Text(
                        'Belum ada fasilitas ditambahkan',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  Wrap(
                    children: [
                      ..._facilities.map(_facilityChip),
                      _addFacilityButton(),
                    ],
                  ),
                ],
              ),
                const SizedBox(height: 10),

                _label('Terbuka untuk Disabilitas'),
                _radioOption(true, 'Ya, terbuka untuk semua disabilitas'),
                _radioOption(false, 'Tidak'),

                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _publishJob,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send_outlined),
                    label: Text(
                      _isLoading ? 'Memproses...' : 'Publish Lowongan',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: navy,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CompanyJobPublishedPage extends StatelessWidget {
  const CompanyJobPublishedPage({
    super.key,
  });

  static const Color navy = AppColors.primaryNavy;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 28),
          child: Column(
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context, 'jobs'),
                    child: const Icon(Icons.arrow_back, color: navy, size: 30),
                  ),
                  const SizedBox(width: 14),
                  const Text(
                    'Lowongan Terpublikasi',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: navy,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                width: 160,
                height: 160,
                decoration: const BoxDecoration(
                  color: Color(0xFFEAF0FF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  size: 100,
                  color: navy,
                ),
              ),
              const SizedBox(height: 44),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Apa Selanjutnya?',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: navy,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Kamu akan mendapatkan notifikasi jika ada update mengenai lowongan kamu',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textGray,
                      ),
                    ),
                    const SizedBox(height: 22),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context, 'jobs'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: navy,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Lihat Lowongan Saya',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context, 'home'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: navy,
                          side: const BorderSide(color: navy),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Kembali ke Beranda',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}