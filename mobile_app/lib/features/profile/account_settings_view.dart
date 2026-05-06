import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import 'profile_controller.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;

class AccountSettingsView extends StatefulWidget {
  final Map<String, dynamic> currentUser;

  const AccountSettingsView({super.key, required this.currentUser});

  @override
  State<AccountSettingsView> createState() => _AccountSettingsViewState();
}

class _AccountSettingsViewState extends State<AccountSettingsView> {
  final TextEditingController _passwordDisplayController = TextEditingController(text: '••••••••••••');

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
          'Pengaturan Akun',
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
              'Ubah Kata Sandi',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: isDark ? Colors.black : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: isDark ? [] : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(color: isDark ? Colors.yellow : Colors.grey.shade100),
              ),
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.vpn_key_outlined, color: theme.colorScheme.primary),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _passwordDisplayController,
                      obscureText: false,
                      readOnly: true,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      style: TextStyle(
                        letterSpacing: 2,
                        fontSize: 18,
                        color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    height: 40,
                    child: ElevatedButton(
                      onPressed: () {
                        _showChangePasswordDialog(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: isDark ? Colors.black : Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: isDark
                              ? const BorderSide(color: Colors.yellow)
                              : BorderSide.none,
                        ),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                      ),
                      child: const Text(
                        'Ubah',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final TextEditingController oldPassController = TextEditingController();
    final TextEditingController newPassController = TextEditingController();
    final TextEditingController confirmPassController = TextEditingController();
    bool obscureOld = true;
    bool obscureNew = true;
    bool obscureConfirm = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (builderContext) => StatefulBuilder(builder: (context, setModalState) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? Colors.black : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: isDark ? Border.all(color: Colors.yellow) : null,
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 32,
            left: 24,
            right: 24,
            top: 32,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ubah Kata Sandi',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 24),
              _buildPasswordField(
                context,
                label: 'Kata Sandi Lama',
                controller: oldPassController,
                isObscured: obscureOld,
                onToggle: () => setModalState(() => obscureOld = !obscureOld),
              ),
              const SizedBox(height: 16),
              _buildPasswordField(
                context,
                label: 'Kata Sandi Baru',
                controller: newPassController,
                isObscured: obscureNew,
                onToggle: () => setModalState(() => obscureNew = !obscureNew),
              ),
              const SizedBox(height: 16),
              _buildPasswordField(
                context,
                label: 'Konfirmasi Kata Sandi Baru',
                controller: confirmPassController,
                isObscured: obscureConfirm,
                onToggle: () => setModalState(() => obscureConfirm = !obscureConfirm),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () {
                    if (newPassController.text != confirmPassController.text) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Konfirmasi password tidak cocok')),
                      );
                      return;
                    }
                    if (newPassController.text.isEmpty || oldPassController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Semua field harus diisi')),
                      );
                      return;
                    }
                    _showConfirmUpdateDialog(context, oldPassController.text, newPassController.text);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: isDark ? Colors.black : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Simpan Perubahan',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildPasswordField(
    BuildContext context, {
    required String label,
    required TextEditingController controller,
    required bool isObscured,
    required VoidCallback onToggle,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: theme.textTheme.bodySmall?.color),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: isObscured,
          style: TextStyle(color: theme.textTheme.bodyLarge?.color),
          decoration: InputDecoration(
            filled: true,
            fillColor: isDark ? Colors.black : const Color(0xFFF9FAFB),
            suffixIcon: IconButton(
              icon: Icon(
                isObscured ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: theme.colorScheme.primary,
                size: 20,
              ),
              onPressed: onToggle,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: isDark ? Colors.yellow : Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: isDark ? Colors.yellow : Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }

  void _showConfirmUpdateDialog(BuildContext context, String oldPass, String newPass) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: theme.scaffoldBackgroundColor,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: isDark ? const BorderSide(color: Colors.yellow) : BorderSide.none),
        title: Text('Konfirmasi', style: TextStyle(color: theme.colorScheme.primary)),
        content: Text('Apakah anda yakin ingin mengubah kata sandi anda?',
            style: TextStyle(color: theme.textTheme.bodyMedium?.color)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Batal', style: TextStyle(color: theme.colorScheme.primary)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);

              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (loadingContext) => Center(
                  child: Card(
                    color: isDark ? Colors.black : Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: CircularProgressIndicator(color: theme.colorScheme.primary),
                    ),
                  ),
                ),
              );

              try {
                final success = await ProfileController.updatePassword(
                    widget.currentUser['_id'] as mongo.ObjectId, oldPass, newPass);

                if (mounted) {
                  Navigator.pop(context);
                  if (success) {
                    Navigator.pop(context);

                    // Tampilkan Dialog Sukses yang Informatif
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: theme.scaffoldBackgroundColor,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: isDark ? const BorderSide(color: Colors.yellow) : BorderSide.none),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(height: 16),
                            Icon(Icons.check_circle,
                                color: isDark ? Colors.yellow : Colors.green, size: 64),
                            const SizedBox(height: 24),
                            const Text(
                              'Berhasil!',
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primaryNavy),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Kata sandi Anda telah berhasil diperbarui.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey),
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () => Navigator.pop(context),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryNavy,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                child: const Text('Selesai', style: TextStyle(color: Colors.white)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  } else {
                    _showErrorDialog(context);
                  }
                }
              } catch (e) {
                if (mounted) Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryNavy,
              foregroundColor: Colors.white,
            ),
            child: const Text('Ya, Ubah'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 8),
            Text('Perhatian'),
          ],
        ),
        content: const Text(
          'Kata sandi lama yang Anda masukkan tidak cocok. Silakan periksa kembali.',
          style: TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup', style: TextStyle(color: AppColors.primaryNavy, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
