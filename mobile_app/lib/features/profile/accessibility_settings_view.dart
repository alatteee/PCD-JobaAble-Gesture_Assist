import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

enum AccessibilityTextSize {
  small,
  medium,
  large,
  extraLarge,
}

class AccessibilityTheme {
  static const Color black = Color(0xFF050505);
  static const Color yellow = Color(0xFFFFEA00);
  static const Color darkCard = Color(0xFF111111);

  static ThemeData highContrastTheme = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: black,
    primaryColor: yellow,
    colorScheme: const ColorScheme.dark(
      primary: yellow,
      secondary: yellow,
      surface: black,
      background: black,
      onPrimary: black,
      onSecondary: black,
      onSurface: yellow,
      onBackground: yellow,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: black,
      foregroundColor: yellow,
      elevation: 0,
      iconTheme: IconThemeData(color: yellow),
      titleTextStyle: TextStyle(
        color: yellow,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: yellow),
      bodyMedium: TextStyle(color: yellow),
      bodySmall: TextStyle(color: yellow),
      titleLarge: TextStyle(color: yellow),
      titleMedium: TextStyle(color: yellow),
      titleSmall: TextStyle(color: yellow),
      labelLarge: TextStyle(color: yellow),
      labelMedium: TextStyle(color: yellow),
      labelSmall: TextStyle(color: yellow),
    ),
    iconTheme: const IconThemeData(color: yellow),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.all(yellow),
      trackColor: WidgetStateProperty.all(yellow.withOpacity(0.35)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: yellow,
        foregroundColor: black,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: yellow,
        side: const BorderSide(color: yellow),
      ),
    ),
  );
}

class AccessibilityController {
  static final ValueNotifier<AccessibilityTextSize> textSizeNotifier =
      ValueNotifier<AccessibilityTextSize>(AccessibilityTextSize.medium);

  static final ValueNotifier<double> textScaleNotifier =
      ValueNotifier<double>(1.0);

  static final ValueNotifier<bool> highContrastNotifier =
      ValueNotifier<bool>(false);

  static String get textSizeLabel {
    switch (textSizeNotifier.value) {
      case AccessibilityTextSize.small:
        return 'Kecil';
      case AccessibilityTextSize.medium:
        return 'Sedang';
      case AccessibilityTextSize.large:
        return 'Besar';
      case AccessibilityTextSize.extraLarge:
        return 'Sangat Besar';
    }
  }

  static void increaseTextSize() {
    switch (textSizeNotifier.value) {
      case AccessibilityTextSize.small:
        _setTextSize(AccessibilityTextSize.medium);
        break;
      case AccessibilityTextSize.medium:
        _setTextSize(AccessibilityTextSize.large);
        break;
      case AccessibilityTextSize.large:
        _setTextSize(AccessibilityTextSize.extraLarge);
        break;
      case AccessibilityTextSize.extraLarge:
        break;
    }
  }

  static void decreaseTextSize() {
    switch (textSizeNotifier.value) {
      case AccessibilityTextSize.extraLarge:
        _setTextSize(AccessibilityTextSize.large);
        break;
      case AccessibilityTextSize.large:
        _setTextSize(AccessibilityTextSize.medium);
        break;
      case AccessibilityTextSize.medium:
        _setTextSize(AccessibilityTextSize.small);
        break;
      case AccessibilityTextSize.small:
        break;
    }
  }

  static void _setTextSize(AccessibilityTextSize size) {
    textSizeNotifier.value = size;

    switch (size) {
      case AccessibilityTextSize.small:
        textScaleNotifier.value = 0.9;
        break;
      case AccessibilityTextSize.medium:
        textScaleNotifier.value = 1.0;
        break;
      case AccessibilityTextSize.large:
        textScaleNotifier.value = 1.15;
        break;
      case AccessibilityTextSize.extraLarge:
        textScaleNotifier.value = 1.3;
        break;
    }
  }

  static void setHighContrast(bool value) {
    highContrastNotifier.value = value;
  }
}

class AccessibilitySettingsView extends StatelessWidget {
  const AccessibilitySettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AccessibilityController.highContrastNotifier,
      builder: (context, isHighContrast, _) {
        final bgColor = isHighContrast ? AccessibilityTheme.black : Colors.white;
        final mainColor =
            isHighContrast ? AccessibilityTheme.yellow : AppColors.primaryNavy;
        final textColor = isHighContrast ? AccessibilityTheme.yellow : Colors.black87;
        final cardColor =
            isHighContrast ? AccessibilityTheme.darkCard : const Color(0xFFDCE7FF);

        return Scaffold(
          backgroundColor: bgColor,
          appBar: AppBar(
            backgroundColor: bgColor,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: mainColor),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'Pengaturan Aksesibilitas',
              style: TextStyle(
                color: mainColor,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            centerTitle: false,
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ukuran Teks',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 14),
                  ValueListenableBuilder<AccessibilityTextSize>(
                    valueListenable: AccessibilityController.textSizeNotifier,
                    builder: (context, textSize, _) {
                      return Row(
                        children: [
                          Expanded(
                            child: _TextSizeButton(
                              label: 'A-',
                              isBold: true,
                              onTap: AccessibilityController.decreaseTextSize,
                              isHighContrast: isHighContrast,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _TextSizeButton(
                              label: AccessibilityController.textSizeLabel,
                              onTap: () {},
                              isHighContrast: isHighContrast,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _TextSizeButton(
                              label: 'A+',
                              isBold: true,
                              onTap: AccessibilityController.increaseTextSize,
                              isHighContrast: isHighContrast,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 22),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 22,
                    ),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: isHighContrast
                          ? Border.all(color: AccessibilityTheme.yellow)
                          : null,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(
                            isHighContrast ? 0.35 : 0.22,
                          ),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.accessible,
                          color: mainColor,
                          size: 34,
                        ),
                        const SizedBox(width: 18),
                        Expanded(
                          child: Text(
                            'Pengaturan ini membantu meningkatkan\nkenyamanan penggunaan aplikasi',
                            style: TextStyle(
                              color: mainColor,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              height: 1.25,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TextSizeButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isBold;
  final bool isHighContrast;

  const _TextSizeButton({
    required this.label,
    required this.onTap,
    required this.isHighContrast,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    final mainColor =
        isHighContrast ? AccessibilityTheme.yellow : AppColors.primaryNavy;

    return SizedBox(
      height: 46,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor:
              isHighContrast ? AccessibilityTheme.black : Colors.white,
          foregroundColor: mainColor,
          side: BorderSide(color: mainColor, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: FittedBox(
          child: Text(
            label,
            style: TextStyle(
              fontSize: isBold ? 18 : 12,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}