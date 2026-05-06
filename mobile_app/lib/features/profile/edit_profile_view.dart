import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import 'profile_controller.dart';
import 'widgets/skill_chip.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class EditProfileView extends StatefulWidget {
  final Map<String, dynamic> currentUser;
  final Map<String, dynamic>? userDetails;

  const EditProfileView({super.key, required this.currentUser, this.userDetails});

  @override
  State<EditProfileView> createState() => _EditProfileViewState();
}

class _EditProfileViewState extends State<EditProfileView> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _namaLengkapController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _deskripsiController;
  late TextEditingController _birthDateController;
  final TextEditingController _skillController = TextEditingController();

  String? _jenisKelamin;
  String? _jenisDisabilitas;
  DateTime? _birthDate;
  List<String> _skills = [];
  String? _cvFileName;
  bool _isLoading = false;
  String? _cvFilePath;
  int? _cvFileSize;
  String? _profilePhotoPath;

  static const int _maxCvSizeBytes = 10 * 1024 * 1024;

  final List<String> _kelaminOptions = ['Laki-laki', 'Perempuan'];
  final List<String> _disabilitasOptions = [
    'Tunanetra',
    'Tunarungu',
    'Tunadaksa',
    'Tunawicara',
    'Disabilitas Intelektual',
    'Disabilitas Mental',
    'Lainnya'
  ];

  @override
  void initState() {
    super.initState();
    _namaLengkapController = TextEditingController(text: widget.userDetails?['nama_lengkap'] ?? widget.currentUser['username']);
    _emailController = TextEditingController(text: widget.userDetails?['email'] ?? widget.currentUser['email']);
    _phoneController = TextEditingController(text: widget.userDetails?['phone'] ?? widget.currentUser['phone']);
    _deskripsiController = TextEditingController(text: widget.userDetails?['deskripsi_disabilitas'] ?? '');
    _birthDateController = TextEditingController();
    _profilePhotoPath = widget.userDetails?['profile_photo'];
    
    // Load birth date
    final birthDateStr = widget.userDetails?['tanggal_lahir'];
    if (birthDateStr != null) {
      if (birthDateStr is DateTime) {
        _birthDate = birthDateStr;
        _birthDateController.text = '${_birthDate!.day}/${_birthDate!.month}/${_birthDate!.year}';
      } else if (birthDateStr is String) {
        try {
          _birthDate = DateTime.parse(birthDateStr);
          _birthDateController.text = '${_birthDate!.day}/${_birthDate!.month}/${_birthDate!.year}';
        } catch (_) {}
      }
    }
    
    // Load dropdowns if they exist in options
    final jk = widget.userDetails?['jenis_kelamin'];
    if (_kelaminOptions.contains(jk)) _jenisKelamin = jk;
    
    final jd = widget.userDetails?['jenis_disabilitas'];
    if (_disabilitasOptions.contains(jd)) _jenisDisabilitas = jd;
    
    _cvFileName = widget.userDetails?['cv_filename'];
    
    final skillsData = widget.userDetails?['skills'];
    if (skillsData != null && skillsData is List) {
      _skills = skillsData.map((e) => e.toString()).toList();
    }
  }

  bool _isBase64(String str) {
    try {
      base64Decode(str);
      return str.length % 4 == 0 && !str.contains(' ');
    } catch (e) {
      return false;
    }
  }

  @override
  void dispose() {
    _namaLengkapController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _deskripsiController.dispose();
    _birthDateController.dispose();
    _skillController.dispose();
    super.dispose();
  }

  void _addSkill() {
    final skill = _skillController.text.trim();
    if (skill.isNotEmpty && !_skills.contains(skill)) {
      setState(() {
        _skills.add(skill);
      });
    }
    _skillController.clear();
  }

  Future<void> _pickCV() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      allowMultiple: false,
    );

    if (result == null || result.files.isEmpty) return;

    final file = result.files.single;

    if (file.size > _maxCvSizeBytes) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ukuran CV maksimal 10 MB')),
      );
      return;
    }

    setState(() {
      _cvFileName = file.name;
      _cvFilePath = file.path;
      _cvFileSize = file.size;
    });
  }

  Future<void> _pickBirthDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (pickedDate != null) {
      setState(() {
        _birthDate = pickedDate;
        _birthDateController.text = '${pickedDate.day}/${pickedDate.month}/${pickedDate.year}';
      });
    }
  }

  Future<void> _pickProfilePhoto() async {
    try {
      final picker = ImagePicker();

      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (pickedFile == null) return;
      
      // Read file as bytes
      final bytes = await pickedFile.readAsBytes();
      // Convert to base64
      final base64String = base64Encode(bytes);

      setState(() {
        _profilePhotoPath = base64String;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memilih foto: $e')),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    if (_jenisKelamin == null || _jenisDisabilitas == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harap pilih Jenis Kelamin dan Jenis Disabilitas')),
      );
      return;
    }

    setState(() { _isLoading = true; });

    final data = {
      'user_id': widget.currentUser['_id'],
      'nama_lengkap': _namaLengkapController.text.trim(),
      'email': _emailController.text.trim(),
      'phone': _phoneController.text.trim(),
      'tanggal_lahir': _birthDate,
      'jenis_kelamin': _jenisKelamin,
      'jenis_disabilitas': _jenisDisabilitas,
      'deskripsi_disabilitas': _deskripsiController.text.trim(),
      'skills': _skills,
      'cv_filename': _cvFileName,
      'cv_file_path': _cvFilePath,
      'cv_file_size': _cvFileSize,
      'profile_photo': _profilePhotoPath,
    };

    final success = await ProfileController.createOrUpdateProfile(data);
    setState(() { _isLoading = false; });

    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil berhasil disimpan'), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal menyimpan profil'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<bool> _showExitConfirmation(BuildContext context) async {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: isDark ? const BorderSide(color: Colors.yellow) : BorderSide.none,
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.warning_amber_rounded,
                  color: theme.colorScheme.primary,
                  size: 40,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Batalkan Perubahan?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Perubahan yang belum disimpan akan hilang.',
                style: TextStyle(
                  fontSize: 14,
                  color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: theme.colorScheme.primary.withOpacity(0.2)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        'Tetap Edit',
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Keluar',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final shouldPop = await _showExitConfirmation(context);
        if (shouldPop && mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text('Edit Profil', style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
          backgroundColor: theme.appBarTheme.backgroundColor,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: theme.colorScheme.primary),
            onPressed: () async {
              final shouldPop = await _showExitConfirmation(context);
              if (shouldPop && mounted) {
                Navigator.pop(context);
              }
            },
          ),
          iconTheme: IconThemeData(color: theme.colorScheme.primary),
        ),
        body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: GestureDetector(
                  onTap: _pickProfilePhoto,
                  child: Stack(
                    children: [
                      Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(24),
                          image: _profilePhotoPath != null && _profilePhotoPath!.isNotEmpty
                              ? DecorationImage(
                                  image: _isBase64(_profilePhotoPath!)
                                      ? MemoryImage(base64Decode(_profilePhotoPath!)) as ImageProvider
                                      : (_profilePhotoPath!.startsWith('http')
                                          ? NetworkImage(_profilePhotoPath!)
                                          : FileImage(File(_profilePhotoPath!))) as ImageProvider,
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: _profilePhotoPath == null || _profilePhotoPath!.isEmpty
                            ? Icon(
                                Icons.person,
                                size: 56,
                                color: theme.colorScheme.primary,
                              )
                            : null,
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.camera_alt,
                            color: theme.colorScheme.onPrimary,
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _buildTextField('Nama Lengkap', _namaLengkapController, validator: (v) => v!.isEmpty ? 'Tidak boleh kosong' : null),
              _buildTextField('Email', _emailController, keyboardType: TextInputType.emailAddress, validator: (v) {
                if (v == null || v.isEmpty) return 'Tidak boleh kosong';
                if (!v.contains('@')) return 'Format email tidak valid';
                return null;
              }),
              _buildTextField('No. Handphone', _phoneController, keyboardType: TextInputType.phone, validator: (v) {
                if (v == null || v.isEmpty) return 'Tidak boleh kosong';
                if (!RegExp(r'^[0-9]+$').hasMatch(v)) return 'Hanya boleh berisi angka';
                if (v.length < 10) return 'Minimal 10 digit';
                return null;
              }),
              
              GestureDetector(
                onTap: _pickBirthDate,
                child: AbsorbPointer(
                  child: _buildTextField('Tanggal Lahir (DD/MM/YYYY)', _birthDateController, readOnly: true, validator: (v) => null),
                ),
              ),
              
              _buildDropdown('Jenis Kelamin', _kelaminOptions, _jenisKelamin, (v) => setState(() => _jenisKelamin = v)),
              _buildDropdown('Jenis Disabilitas', _disabilitasOptions, _jenisDisabilitas, (v) => setState(() => _jenisDisabilitas = v)),
              
              _buildTextField('Deskripsi Disabilitas', _deskripsiController, maxLines: 3),
              
              const SizedBox(height: 16),
              Text('Kemampuan (Skills)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: theme.textTheme.titleMedium?.color)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _skillController,
                      style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                      decoration: InputDecoration(
                        hintText: 'Tambahkan skill (mis: Microsoft Word)',
                        hintStyle: TextStyle(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: theme.dividerColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: theme.colorScheme.primary),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      onFieldSubmitted: (_) => _addSkill(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _addSkill,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    child: Icon(Icons.add, color: theme.colorScheme.onPrimary),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _skills.map((skill) => SkillChip(
                  label: skill,
                  onDeleted: () {
                    setState(() => _skills.remove(skill));
                  },
                )).toList(),
              ),

              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading 
                    ? SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: theme.colorScheme.onPrimary, strokeWidth: 2))
                    : const Text('Simpan Profil', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    ),
  );
}

  Widget _buildTextField(String label, TextEditingController controller, {int maxLines = 1, TextInputType? keyboardType, String? Function(String?)? validator, bool readOnly = false}) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: theme.textTheme.titleMedium?.color)),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            validator: validator,
            readOnly: readOnly,
            style: TextStyle(color: theme.textTheme.bodyLarge?.color),
            decoration: InputDecoration(
              filled: true,
              fillColor: theme.brightness == Brightness.dark ? Colors.grey.shade900 : Colors.grey.shade50,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: theme.dividerColor)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: theme.dividerColor)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: theme.colorScheme.primary)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(String label, List<String> options, String? value, void Function(String?) onChanged) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4.0),
            child: Text(
              label, 
              style: TextStyle(
                fontSize: 14, 
                fontWeight: FontWeight.bold, 
                color: theme.colorScheme.primary,
                letterSpacing: 0.5,
              )
            ),
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: theme.brightness == Brightness.dark ? Colors.transparent : Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: DropdownButtonFormField<String>(
              value: value,
              dropdownColor: theme.brightness == Brightness.dark ? Colors.grey.shade900 : Colors.white,
              isExpanded: true, 
              items: options.map((o) => DropdownMenuItem(
                value: o, 
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: Text(
                    o, 
                    style: TextStyle(
                      fontSize: 15, 
                      color: theme.textTheme.bodyLarge?.color,
                      fontWeight: FontWeight.w500,
                    )
                  ),
                )
              )).toList(),
              onChanged: onChanged,
              validator: (v) => v == null ? 'Harap pilih $label' : null,
              icon: Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Icon(
                  Icons.expand_more_rounded, 
                  color: theme.colorScheme.primary.withOpacity(0.8),
                  size: 28,
                ),
              ),
              borderRadius: BorderRadius.circular(20),
              elevation: 16,
              menuMaxHeight: 350,
              decoration: InputDecoration(
                filled: true,
                fillColor: theme.brightness == Brightness.dark ? Colors.grey.shade900 : Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                prefixIcon: Container(
                  margin: const EdgeInsets.only(left: 12, right: 12),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    label.contains('Kelamin') ? Icons.wc_rounded : Icons.accessibility_new_rounded,
                    color: theme.colorScheme.primary,
                    size: 18,
                  ),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: theme.dividerColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: theme.dividerColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Colors.redAccent, width: 1),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
