import 'package:flutter/material.dart';
import '../../services/mongo_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';

class CompanyEditProfilePage extends StatefulWidget {
  final Map<String, dynamic> companyData;

  const CompanyEditProfilePage({
    super.key,
    required this.companyData,
  });

  @override
  State<CompanyEditProfilePage> createState() => _CompanyEditProfilePageState();
}

class _CompanyEditProfilePageState extends State<CompanyEditProfilePage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _companyNameController;
  late final TextEditingController _fieldController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  late final TextEditingController _descriptionController;

  String? _profilePhotoBase64;
  bool isSaving = false;

  static const Color navy = Color(0xFF0B1B55);
  static const Color textDark = Color(0xFF07122F);
  static const Color hintText = Color(0xFF5B6475);
  static const Color inputFill = Color(0xFFF3F5FC);

  @override
  void initState() {
    super.initState();

    _companyNameController = TextEditingController(
      text: widget.companyData['company_name']?.toString() ?? '',
    );

    _fieldController = TextEditingController(
      text: widget.companyData['field']?.toString() ?? '',
    );

    _emailController = TextEditingController(
      text: widget.companyData['email']?.toString() ?? '',
    );

    _phoneController = TextEditingController(
      text: widget.companyData['phone']?.toString() ?? '',
    );

    _addressController = TextEditingController(
      text: widget.companyData['address']?.toString() ?? '',
    );

    _descriptionController = TextEditingController(
      text: widget.companyData['description']?.toString() ?? '',
    );

    _profilePhotoBase64 = widget.companyData['profile_photo']?.toString();
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _fieldController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
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
        _profilePhotoBase64 = base64String;
      });
    } catch (e) {
      if (mounted) {
        _showSnackBar('Gagal memilih foto: $e');
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final companyId = MongoService.getMongoId(widget.companyData['_id']);

    if (companyId.isEmpty) {
      _showSnackBar('ID perusahaan tidak valid');
      return;
    }

    setState(() {
      isSaving = true;
    });

    final success = await MongoService.updateCompanyProfile(
      companyId: companyId,
      data: {
        'company_name': _companyNameController.text.trim(),
        'field': _fieldController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'description': _descriptionController.text.trim(),
        'profile_photo': _profilePhotoBase64,
      },
    );

    if (!mounted) return;

    setState(() {
      isSaving = false;
    });

    if (success) {
      _showSnackBar('Profil perusahaan berhasil diperbarui');
      Navigator.pop(context, true);
    } else {
      _showSnackBar('Gagal memperbarui profil perusahaan');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _confirmBack() async {
    if (isSaving) return;

    final shouldExit = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 42),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.18),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: navy,
                  size: 62,
                ),

                const SizedBox(height: 16),

                const Text(
                  'Batalkan Perubahan?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    color: textDark,
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  'Perubahan yang belum disimpan\nakan hilang.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade500,
                    height: 1.35,
                  ),
                ),

                const SizedBox(height: 26),

                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 46,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(dialogContext, false),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE0E0E0),
                            foregroundColor: textDark,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          child: const Text(
                            'Tetap Edit',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 14),

                    Expanded(
                      child: SizedBox(
                        height: 46,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(dialogContext, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: navy,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          child: const Text(
                            'Keluar',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (shouldExit == true && mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _confirmBack();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(23, 22, 23, 34),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _buildPhotoPicker(),

                        const SizedBox(height: 24),

                        _buildInputGroup(
                          label: 'Nama Perusahaan',
                          controller: _companyNameController,
                          hint: 'Masukkan nama perusahaan',
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Nama perusahaan wajib diisi';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 18),

                        _buildInputGroup(
                          label: 'Bidang Perusahaan',
                          controller: _fieldController,
                          hint: 'Contoh: Teknologi Informasi',
                        ),

                        const SizedBox(height: 18),

                        _buildInputGroup(
                          label: 'Email',
                          controller: _emailController,
                          hint: 'Masukkan email perusahaan',
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            final email = value?.trim() ?? '';

                            if (email.isEmpty) {
                              return 'Email wajib diisi';
                            }

                            if (!email.contains('@') || !email.contains('.')) {
                              return 'Format email tidak valid';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 18),

                        _buildInputGroup(
                          label: 'No. Telepon',
                          controller: _phoneController,
                          hint: 'Masukkan no. telepon',
                          keyboardType: TextInputType.phone,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'No. telepon wajib diisi';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 18),

                        _buildInputGroup(
                          label: 'Alamat',
                          controller: _addressController,
                          hint: 'Masukkan alamat perusahaan',
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Alamat wajib diisi';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 18),

                        _buildInputGroup(
                          label: 'Deskripsi Perusahaan',
                          controller: _descriptionController,
                          hint: 'Masukkan deskripsi perusahaan',
                          minLines: 4,
                          maxLines: 4,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Deskripsi perusahaan wajib diisi';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 34),

                        _buildSaveButton(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(23, 22, 23, 6),
      child: Row(
        children: [
          GestureDetector(
            onTap: _confirmBack,
            child: const Icon(
              Icons.arrow_back,
              color: navy,
              size: 30,
            ),
          ),

          const SizedBox(width: 18),

          const Expanded(
            child: Text(
              'Edit Profil',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.w900,
                color: navy,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoPicker() {
    return Center(
      child: Stack(
        children: [
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              color: inputFill,
              shape: BoxShape.circle,
              border: Border.all(color: navy.withOpacity(0.1), width: 2),
              image: _profilePhotoBase64 != null
                  ? DecorationImage(
                      image: MemoryImage(base64Decode(_profilePhotoBase64!)),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: _profilePhotoBase64 == null
                ? const Icon(
                    Icons.apartment_rounded,
                    color: navy,
                    size: 50,
                  )
                : null,
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: _pickImage,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: navy,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputGroup({
    required String label,
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    int minLines = 1,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    final bool isMultiline = maxLines > 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: textDark,
          ),
        ),

        const SizedBox(height: 10),

        Container(
          decoration: BoxDecoration(
            color: inputFill,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 7,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            minLines: minLines,
            maxLines: maxLines,
            validator: validator,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
              color: hintText,
              height: 1.35,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: hintText.withOpacity(0.75),
              ),
              filled: true,
              fillColor: inputFill,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 18,
                vertical: isMultiline ? 16 : 17,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: navy,
                  width: 1.2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: Colors.red,
                  width: 1.1,
                ),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: Colors.red,
                  width: 1.2,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: isSaving ? null : _saveProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: navy,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey.shade500,
          elevation: 6,
          shadowColor: Colors.black.withOpacity(0.28),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child: isSaving
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.4,
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.save_rounded,
                    size: 21,
                    color: Colors.white,
                  ),
                  SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      'Simpan Perubahan',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}