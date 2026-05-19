import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../core/constants/app_colors.dart';
import '../gesture_assist/views/gesture_guide_page.dart';

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
      onPrimary: black,
      onSecondary: black,
      onSurface: yellow,
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
  static const String _settingsBoxName = 'accessibilitySettings';
  static const String _gestureNavigationModeKey = 'gestureNavigationMode';

  static final ValueNotifier<AccessibilityTextSize> textSizeNotifier =
      ValueNotifier<AccessibilityTextSize>(AccessibilityTextSize.medium);

  static final ValueNotifier<double> textScaleNotifier =
      ValueNotifier<double>(1.0);

  static final ValueNotifier<bool> highContrastNotifier =
      ValueNotifier<bool>(false);

  static final ValueNotifier<bool> gestureNavigationModeNotifier =
      ValueNotifier<bool>(false);

  static bool _isInitialized = false;

  static bool get isGestureNavigationEnabled =>
      gestureNavigationModeNotifier.value;

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

  static Future<void> init() async {
    if (_isInitialized) return;

    final box = await _openSettingsBox();
    final savedGestureMode = box.get(
      _gestureNavigationModeKey,
      defaultValue: false,
    );

    gestureNavigationModeNotifier.value = savedGestureMode == true;
    _isInitialized = true;
  }

  static Future<Box<dynamic>> _openSettingsBox() async {
    if (Hive.isBoxOpen(_settingsBoxName)) {
      return Hive.box<dynamic>(_settingsBoxName);
    }

    return Hive.openBox<dynamic>(_settingsBoxName);
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

  static Future<void> setGestureNavigationMode(bool value) async {
    gestureNavigationModeNotifier.value = value;

    final box = await _openSettingsBox();
    await box.put(_gestureNavigationModeKey, value);
  }
}

class AccessibilitySettingsView extends StatelessWidget {
  const AccessibilitySettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: AccessibilityController.init(),
      builder: (context, snapshot) {
        return ValueListenableBuilder<bool>(
          valueListenable: AccessibilityController.highContrastNotifier,
          builder: (context, isHighContrast, _) {
            final bgColor =
                isHighContrast ? AccessibilityTheme.black : Colors.white;
            final mainColor = isHighContrast
                ? AccessibilityTheme.yellow
                : AppColors.primaryNavy;
            final textColor =
                isHighContrast ? AccessibilityTheme.yellow : Colors.black87;
            final cardColor = isHighContrast
                ? AccessibilityTheme.darkCard
                : const Color(0xFFDCE7FF);

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
                        valueListenable:
                            AccessibilityController.textSizeNotifier,
                        builder: (context, textSize, _) {
                          return Row(
                            children: [
                              Expanded(
                                child: _TextSizeButton(
                                  label: 'A-',
                                  isBold: true,
                                  onTap:
                                      AccessibilityController.decreaseTextSize,
                                  isHighContrast: isHighContrast,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _TextSizeButton(
                                  label:
                                      AccessibilityController.textSizeLabel,
                                  onTap: () {},
                                  isHighContrast: isHighContrast,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _TextSizeButton(
                                  label: 'A+',
                                  isBold: true,
                                  onTap:
                                      AccessibilityController.increaseTextSize,
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
                      const SizedBox(height: 18),
                      _GestureNavigationModeToggle(
                        isHighContrast: isHighContrast,
                        mainColor: mainColor,
                        textColor: textColor,
                      ),
                      const SizedBox(height: 14),
                      _GestureGuideMenu(
                        isHighContrast: isHighContrast,
                        mainColor: mainColor,
                        textColor: textColor,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _GestureNavigationModeToggle extends StatelessWidget {
  final bool isHighContrast;
  final Color mainColor;
  final Color textColor;

  const _GestureNavigationModeToggle({
    required this.isHighContrast,
    required this.mainColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor =
        isHighContrast ? AccessibilityTheme.darkCard : Colors.white;

    final borderColor =
        isHighContrast ? AccessibilityTheme.yellow : const Color(0xFFE2E8F0);

    return ValueListenableBuilder<bool>(
      valueListenable: AccessibilityController.gestureNavigationModeNotifier,
      builder: (context, isGestureModeOn, _) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 16,
          ),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(
                  isHighContrast ? 0.25 : 0.08,
                ),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isHighContrast
                      ? AccessibilityTheme.black
                      : AppColors.primaryNavy.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(12),
                  border: isHighContrast
                      ? Border.all(color: AccessibilityTheme.yellow)
                      : null,
                ),
                child: Icon(
                  Icons.gesture_rounded,
                  color: mainColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Gesture Navigation Mode',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isGestureModeOn
                          ? 'Aktif: gesture dapat menjalankan navigasi aplikasi.'
                          : 'Nonaktif: gesture tetap terdeteksi, tapi tidak menjalankan aksi.',
                      style: TextStyle(
                        color: isHighContrast
                            ? AccessibilityTheme.yellow
                            : AppColors.textGray,
                        fontSize: 12.5,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Switch(
                value: isGestureModeOn,
                activeColor:
                    isHighContrast ? AccessibilityTheme.yellow : mainColor,
                onChanged: (value) async {
                  await AccessibilityController.setGestureNavigationMode(value);

                  if (!context.mounted) return;

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        value
                            ? 'Gesture Navigation Mode aktif'
                            : 'Gesture Navigation Mode nonaktif',
                      ),
                      backgroundColor:
                          value ? const Color(0xFF16A34A) : Colors.orange,
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _GestureGuideMenu extends StatelessWidget {
  final bool isHighContrast;
  final Color mainColor;
  final Color textColor;

  const _GestureGuideMenu({
    required this.isHighContrast,
    required this.mainColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor =
        isHighContrast ? AccessibilityTheme.darkCard : Colors.white;

    final borderColor =
        isHighContrast ? AccessibilityTheme.yellow : const Color(0xFFE2E8F0);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const GestureGuidePage(),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(
                isHighContrast ? 0.25 : 0.08,
              ),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isHighContrast
                    ? AccessibilityTheme.black
                    : AppColors.primaryNavy.withOpacity(0.10),
                borderRadius: BorderRadius.circular(12),
                border: isHighContrast
                    ? Border.all(color: AccessibilityTheme.yellow)
                    : null,
              ),
              child: Icon(
                Icons.front_hand_rounded,
                color: mainColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Panduan Gesture Assist',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Lihat panduan gesture sebelum menggunakan kamera.',
                    style: TextStyle(
                      color: isHighContrast
                          ? AccessibilityTheme.yellow
                          : AppColors.textGray,
                      fontSize: 12.5,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Icon(
              Icons.chevron_right_rounded,
              color: mainColor,
              size: 26,
            ),
          ],
        ),
      ),
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