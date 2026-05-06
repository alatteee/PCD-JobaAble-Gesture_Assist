import 'package:flutter/material.dart';
// import library lottie
import '../../core/constants/app_colors.dart';
import '../../core/widgets/custom_text_field.dart';
import 'sign_up_view.dart';
import 'auth_controller.dart';
import '../home/home_page.dart'; // import page home (tujuan berhasil)
import '../company/company_home_page.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _isLoading = false;

  void _handleLogin() async {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;

    // 1. Validasi Empty
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email dan kata sandi tidak boleh kosong.'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() { _isLoading = true; });

    // 2. Call Logic Controller
    final user = await AuthController.login(email: email, password: password);

    setState(() { _isLoading = false; });

    // 3. Evaluasi
    if (user != null) {
      if (!mounted) return;

      final role = user['role']?.toString();

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => role == 'company'
              ? CompanyHomePage(userData: user, showSuccessDialog: true)
              : HomePage(userData: user, showSuccessDialog: true),
        ),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email atau kata sandi salah. Silakan coba lagi.'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : AppColors.primaryNavy,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header (Navy background)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.arrow_back_ios_new,
                      color: isDark ? Colors.yellow : Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Back',
                      style: TextStyle(
                        color: isDark ? Colors.yellow : Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Bottom White Container (Fill the rest of the screen)
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                decoration: BoxDecoration(
                  color: isDark ? Colors.black : Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(40),
                    topRight: Radius.circular(40),
                  ),
                  border: isDark ? const Border(
                    top: BorderSide(color: Colors.yellow, width: 2),
                  ) : null,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 48),
                      // Title
                      Text(
                        'Welcome Back !',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.yellow : AppColors.primaryNavy,
                        ),
                      ),
                      const SizedBox(height: 48),
                      
                      // Email Field
                      CustomTextField(
                        label: 'Email or Phone',
                        hint: 'Email or Phone',
                        prefixIcon: Icons.email_outlined,
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 24),
                      
                      // Password Field
                      CustomTextField(
                        label: 'Password',
                        hint: 'Password',
                        isPassword: true,
                        prefixIcon: Icons.lock_outline,
                        controller: _passwordCtrl,
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Forgot Password
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {},
                          child: Text(
                            'Forgot Password?',
                            style: TextStyle(
                              color: isDark ? Colors.yellow : AppColors.textGray,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Login Button
                      SizedBox(
                        height: 58, 
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDark ? Colors.yellow : AppColors.primaryNavy,
                            foregroundColor: isDark ? Colors.black : Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: _isLoading 
                            ? CircularProgressIndicator(color: isDark ? Colors.black : Colors.white)
                            : const Text(
                                'Log In',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Sign Up Link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Don't Have An Account? ",
                            style: TextStyle(
                              color: isDark ? Colors.yellow : AppColors.textGray,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(builder: (_) => const SignUpView()),
                              );
                            },
                            child: Text(
                              "Sign Up",
                              style: TextStyle(
                                color: isDark ? Colors.yellow : AppColors.primaryNavy,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        ],
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}