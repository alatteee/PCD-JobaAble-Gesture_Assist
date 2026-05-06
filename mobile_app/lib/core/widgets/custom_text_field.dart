import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class CustomTextField extends StatefulWidget {
  final String label;
  final String hint;
  final bool isPassword;
  final IconData? prefixIcon;
  final TextEditingController? controller;
  final TextInputType? keyboardType;

  const CustomTextField({
    super.key,
    required this.label,
    required this.hint,
    this.isPassword = false,
    this.prefixIcon,
    this.controller,
    this.keyboardType,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.yellow : AppColors.primaryNavy,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: widget.controller,
          keyboardType: widget.keyboardType,
          obscureText: widget.isPassword ? _obscureText : false,
          style: TextStyle(color: isDark ? Colors.yellow : AppColors.primaryNavy),
          decoration: InputDecoration(
            filled: isDark,
            fillColor: isDark ? Colors.black : Colors.transparent,
            hintText: widget.hint,
            hintStyle: TextStyle(color: isDark ? Colors.yellow.withOpacity(0.5) : Colors.grey.shade400),
            prefixIcon: widget.prefixIcon != null 
                ? Icon(widget.prefixIcon, color: isDark ? Colors.yellow : Colors.grey.shade500) 
                : null,
            suffixIcon: widget.isPassword
                ? IconButton(
                    icon: Icon(
                      _obscureText ? Icons.visibility_off : Icons.visibility,
                      color: isDark ? Colors.yellow : Colors.grey.shade500,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureText = !_obscureText;
                      });
                    },
                  )
                : null,
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: isDark ? Colors.yellow : Colors.black12),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: isDark ? Colors.yellow : Colors.black12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: isDark ? Colors.yellow : AppColors.primaryNavy, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
