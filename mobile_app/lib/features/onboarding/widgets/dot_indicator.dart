import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class DotIndicator extends StatelessWidget {
  final bool isActive;

  const DotIndicator({super.key, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 10,
      width: 10,
      decoration: BoxDecoration(
        color: isActive ? AppColors.primaryNavy : Colors.grey[300],
        shape: BoxShape.circle,
      ),
    );
  }
}
