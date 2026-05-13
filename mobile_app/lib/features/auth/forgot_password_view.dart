import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/custom_text_field.dart';
import 'auth_controller.dart';
import '../../services/mongo_service.dart';

class ForgotPasswordView extends StatefulWidget {
  const ForgotPasswordView({super.key});

  @override
  State<ForgotPasswordView> createState() => _ForgotPasswordViewState();
}

class _ForgotPasswordViewState extends State<ForgotPasswordView> {
  final _emailCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  bool _isLoading = false;
  int _currentStep = 1; // 1: Email, 2: Reset Password

  @override
  void dispose() {
    _emailCtrl.dispose();
    _newPasswordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  Future<void> _verifyEmail() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      _showSnackBar('Silakan masukkan email Anda');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final exists = await AuthController.isEmailExists(email);
      if (!mounted) return;

      if (exists) {
        setState(() => _currentStep = 2);
      } else {
        _showSnackBar('Email tidak terdaftar');
      }
    } catch (e) {
      _showSnackBar('Terjadi kesalahan: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailCtrl.text.trim();
    final newPassword = _newPasswordCtrl.text;
    final confirmPassword = _confirmPasswordCtrl.text;

    if (newPassword.isEmpty || confirmPassword.isEmpty) {
      _showSnackBar('Silakan isi kata sandi baru');
      return;
    }

    if (newPassword.length < 6) {
      _showSnackBar('Kata sandi harus minimal 6 karakter');
      return;
    }

    if (newPassword != confirmPassword) {
      _showSnackBar('Konfirmasi kata sandi tidak cocok');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final passwordHash = AuthController.hashPassword(newPassword);
      
      // Update password di database
      final success = await MongoService.updateUserPassword(email, passwordHash);
      
      if (!mounted) return;

      if (success) {
        _showSnackBar('Kata sandi berhasil diperbarui!', isError: false);
        Navigator.pop(context); // Kembali ke Login
      } else {
        _showSnackBar('Gagal memperbarui kata sandi');
      }
    } catch (e) {
      _showSnackBar('Terjadi kesalahan: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      appBar: AppBar(
        title: const Text('Reset Password'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: isDark ? Colors.white : AppColors.primaryNavy,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _currentStep == 1 ? 'Lupa Kata Sandi?' : 'Buat Kata Sandi Baru',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.primaryNavy,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _currentStep == 1 
                  ? 'Masukkan email terdaftar Anda untuk mengatur ulang kata sandi.'
                  : 'Sandi baru ini akan digunakan untuk login ke akun Anda.',
              style: TextStyle(
                fontSize: 16,
                color: isDark ? Colors.white70 : AppColors.textGray,
              ),
            ),
            const SizedBox(height: 32),
            if (_currentStep == 1) ...[
              CustomTextField(
                label: 'Email',
                hint: 'Masukkan email Anda',
                prefixIcon: Icons.email_outlined,
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
              ),
            ] else ...[
              CustomTextField(
                label: 'Kata Sandi Baru',
                hint: 'Masukkan kata sandi baru',
                isPassword: true,
                prefixIcon: Icons.lock_outline,
                controller: _newPasswordCtrl,
              ),
              const SizedBox(height: 20),
              CustomTextField(
                label: 'Konfirmasi Kata Sandi',
                hint: 'Masukkan kembali kata sandi baru',
                isPassword: true,
                prefixIcon: Icons.lock_reset,
                controller: _confirmPasswordCtrl,
              ),
            ],
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 58,
              child: ElevatedButton(
                onPressed: _isLoading 
                    ? null 
                    : (_currentStep == 1 ? _verifyEmail : _resetPassword),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? Colors.yellow : AppColors.primaryNavy,
                  foregroundColor: isDark ? Colors.black : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isLoading 
                    ? const CircularProgressIndicator()
                    : Text(
                        _currentStep == 1 ? 'Verifikasi Email' : 'Perbarui Kata Sandi',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
