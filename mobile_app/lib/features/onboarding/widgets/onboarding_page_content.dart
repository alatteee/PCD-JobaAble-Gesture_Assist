import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class OnboardingPageContent extends StatelessWidget {
  final String title;
  final String description;
  final String imagePath;
  final bool isFirstPage;

  const OnboardingPageContent({
    super.key,
    required this.title,
    required this.description,
    required this.imagePath,
    this.isFirstPage = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isFirstPage)
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: const TextStyle(fontSize: 38, fontWeight: FontWeight.bold, height: 1.3),
                children: [
                  TextSpan(text: 'Welcome To\n', style: TextStyle(color: isDark ? Colors.yellow : AppColors.primaryNavy)),
                  TextSpan(text: 'Job', style: TextStyle(color: isDark ? Colors.yellow : AppColors.primaryNavy)),
                  TextSpan(text: 'Able', style: TextStyle(color: isDark ? Colors.yellow.withOpacity(0.8) : AppColors.accentBlue)),
                ],
              ),
            )
          else
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.yellow : AppColors.primaryNavy,
                height: 1.3,
              ),
            ),
            
          if (description.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: isDark ? Colors.yellow.withOpacity(0.8) : AppColors.textGray,
                fontWeight: FontWeight.w500,
                height: 1.5,
              ),
            ),
          ],
          
          const SizedBox(height: 48),
          
          SizedBox(
            height: 280,
            child: Image.asset(
              imagePath,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 280,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(16)
                  ),
                  child: const Center(
                    child: Text('Illustration Placeholder\n(Add image here)', 
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
