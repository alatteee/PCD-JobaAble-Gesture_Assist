import 'package:flutter/material.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;

import '../profile/profile_controller.dart';

class CompanyAccountSettingsPage extends StatefulWidget {
  final Map<String, dynamic> currentUser;

  const CompanyAccountSettingsPage({
    super.key,
    required this.currentUser,
  });

  @override
  State<CompanyAccountSettingsPage> createState() =>
      _CompanyAccountSettingsPageState();
}

class _CompanyAccountSettingsPageState
    extends State<CompanyAccountSettingsPage> {
  final TextEditingController _passwordDisplayController =
      TextEditingController(text: '••••••••••••');

  static const Color navy = Color(0xFF0B1B55);
  static const Color textDark = Color(0xFF07122F);
  static const Color subtitle = Color(0xFF8D94A6);

  @override
  void dispose() {
    _passwordDisplayController.dispose();
    super.dispose();
  }

  mongo.ObjectId? _getCurrentUserId() {
    final id = widget.currentUser['_id'];

    if (id is mongo.ObjectId) {
      return id;
    }

    if (id != null) {
      try {
        return mongo.ObjectId.fromHexString(id.toString());
      } catch (_) {
        return null;
      }
    }

    return null;
  }

  void _showSnackBar(String message, {Color? color}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 22, 24, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),

              const SizedBox(height: 34),

              const Text(
                'Ubah Kata Sandi',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: navy,
                ),
              ),

              const SizedBox(height: 14),

              _buildPasswordCard(),
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
            size: 30,
          ),
        ),

        const SizedBox(width: 18),

        const Expanded(
          child: Text(
            'Pengaturan Akun',
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
    );
  }

  Widget _buildPasswordCard() {
    return Container(
      width: double.infinity,
      height: 66,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(
            Icons.vpn_key_rounded,
            color: navy,
            size: 28,
          ),

          const SizedBox(width: 16),

          Expanded(
            child: TextField(
              controller: _passwordDisplayController,
              readOnly: true,
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: subtitle,
                letterSpacing: 3,
              ),
            ),
          ),

          const SizedBox(width: 12),

          SizedBox(
            width: 76,
            height: 40,
            child: ElevatedButton(
              onPressed: _showChangePasswordBottomSheet,
              style: ElevatedButton.styleFrom(
                backgroundColor: navy,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(11),
                ),
              ),
              child: const Text(
                'Ubah',
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordBottomSheet() {
    final oldPassController = TextEditingController();
    final newPassController = TextEditingController();
    final confirmPassController = TextEditingController();

    bool obscureOld = true;
    bool obscureNew = true;
    bool obscureConfirm = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 26,
                bottom: MediaQuery.of(context).viewInsets.bottom + 26,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 46,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(100),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    const Text(
                      'Ubah Kata Sandi',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: navy,
                      ),
                    ),

                    const SizedBox(height: 22),

                    _buildPasswordInput(
                      label: 'Kata Sandi Lama',
                      controller: oldPassController,
                      isObscured: obscureOld,
                      onToggle: () {
                        setModalState(() {
                          obscureOld = !obscureOld;
                        });
                      },
                    ),

                    const SizedBox(height: 16),

                    _buildPasswordInput(
                      label: 'Kata Sandi Baru',
                      controller: newPassController,
                      isObscured: obscureNew,
                      onToggle: () {
                        setModalState(() {
                          obscureNew = !obscureNew;
                        });
                      },
                    ),

                    const SizedBox(height: 16),

                    _buildPasswordInput(
                      label: 'Konfirmasi Kata Sandi Baru',
                      controller: confirmPassController,
                      isObscured: obscureConfirm,
                      onToggle: () {
                        setModalState(() {
                          obscureConfirm = !obscureConfirm;
                        });
                      },
                    ),

                    const SizedBox(height: 26),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          final oldPass = oldPassController.text.trim();
                          final newPass = newPassController.text.trim();
                          final confirmPass =
                              confirmPassController.text.trim();

                          if (oldPass.isEmpty ||
                              newPass.isEmpty ||
                              confirmPass.isEmpty) {
                            _showSnackBar(
                              'Semua field harus diisi',
                              color: Colors.red,
                            );
                            return;
                          }

                          if (newPass.length < 6) {
                            _showSnackBar(
                              'Kata sandi baru minimal 6 karakter',
                              color: Colors.red,
                            );
                            return;
                          }

                          if (newPass != confirmPass) {
                            _showSnackBar(
                              'Konfirmasi kata sandi tidak cocok',
                              color: Colors.red,
                            );
                            return;
                          }

                          _showConfirmUpdateDialog(
                            oldPass: oldPass,
                            newPass: newPass,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: navy,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Simpan Perubahan',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPasswordInput({
    required String label,
    required TextEditingController controller,
    required bool isObscured,
    required VoidCallback onToggle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: textDark,
          ),
        ),

        const SizedBox(height: 8),

        TextField(
          controller: controller,
          obscureText: isObscured,
          style: const TextStyle(
            fontSize: 13.5,
            color: textDark,
            fontWeight: FontWeight.w700,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF8F9FC),
            hintText: label,
            hintStyle: TextStyle(
              fontSize: 13.5,
              color: Colors.grey.shade400,
              fontWeight: FontWeight.w600,
            ),
            suffixIcon: IconButton(
              onPressed: onToggle,
              icon: Icon(
                isObscured
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: navy,
                size: 21,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 15,
              vertical: 13,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: const BorderSide(
                color: navy,
                width: 1.4,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showConfirmUpdateDialog({
    required String oldPass,
    required String newPass,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
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
                  Icons.lock_reset_rounded,
                  color: navy,
                  size: 62,
                ),

                const SizedBox(height: 16),

                const Text(
                  'Ubah Kata Sandi?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    color: textDark,
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  'Apakah anda yakin ingin mengubah\nkata sandi akun anda?',
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
                          onPressed: () => Navigator.pop(dialogContext),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE0E0E0),
                            foregroundColor: textDark,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          child: const Text(
                            'Batal',
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
                          onPressed: () async {
                            Navigator.pop(dialogContext);
                            await _updatePassword(
                              oldPass: oldPass,
                              newPass: newPass,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: navy,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          child: const Text(
                            'Ya, Ubah',
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
  }

  Future<void> _updatePassword({
    required String oldPass,
    required String newPass,
  }) async {
    final userId = _getCurrentUserId();

    if (userId == null) {
      _showSnackBar(
        'User tidak valid. Silakan login ulang.',
        color: Colors.red,
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return const Center(
          child: Card(
            color: Colors.white,
            child: Padding(
              padding: EdgeInsets.all(22),
              child: CircularProgressIndicator(
                color: navy,
              ),
            ),
          ),
        );
      },
    );

    try {
      final success = await ProfileController.updatePassword(
        userId,
        oldPass,
        newPass,
      );

      if (!mounted) return;

      Navigator.pop(context);

      if (success) {
        Navigator.pop(context);
        _showSuccessDialog();
      } else {
        _showErrorDialog();
      }
    } catch (e) {
      if (!mounted) return;

      Navigator.pop(context);
      _showSnackBar(
        'Gagal mengubah kata sandi',
        color: Colors.red,
      );
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (successContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 42),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
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
                  Icons.check_circle_rounded,
                  color: Colors.green,
                  size: 64,
                ),

                const SizedBox(height: 18),

                const Text(
                  'Berhasil!',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    color: navy,
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  'Kata sandi Anda telah berhasil\ndiperbarui.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                  ),
                ),

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(successContext),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: navy,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: const Text(
                      'Selesai',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showErrorDialog() {
    showDialog(
      context: context,
      builder: (errorContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 42),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
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
                  color: Colors.orange,
                  size: 62,
                ),

                const SizedBox(height: 16),

                const Text(
                  'Perhatian',
                  style: TextStyle(
                    color: navy,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  'Kata sandi lama yang Anda masukkan\ntidak cocok. Silakan periksa kembali.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13.5,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                  ),
                ),

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(errorContext),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: navy,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: const Text(
                      'Tutup',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}