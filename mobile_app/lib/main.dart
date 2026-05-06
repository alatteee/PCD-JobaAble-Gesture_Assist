import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/constants/app_colors.dart';
import 'features/profile/accessibility_settings_view.dart';
import 'features/splash/splash_view.dart';
import 'services/mongo_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");
  await MongoService.connect();

  runApp(const JobAbleApp());
}

class JobAbleApp extends StatelessWidget {
  const JobAbleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: AccessibilityController.textScaleNotifier,
      builder: (context, textScale, _) {
        return ValueListenableBuilder<bool>(
          valueListenable: AccessibilityController.highContrastNotifier,
          builder: (context, isHighContrast, _) {
            return MaterialApp(
              title: 'JobAble',
              debugShowCheckedModeBanner: false,
              builder: (context, child) {
                Widget app = MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    textScaler: TextScaler.linear(textScale),
                  ),
                  child: child!,
                );

                if (isHighContrast) {
                  app = Theme(
                    data: AccessibilityTheme.highContrastTheme,
                    child: app,
                  );
                }

                return app;
              },
              theme: isHighContrast
                  ? AccessibilityTheme.highContrastTheme
                  : ThemeData(
                      scaffoldBackgroundColor: Colors.white,
                      primaryColor: AppColors.primaryNavy,
                      colorScheme: ColorScheme.fromSeed(
                        seedColor: AppColors.primaryNavy,
                        primary: AppColors.primaryNavy,
                        secondary: AppColors.accentBlue,
                        surface: Colors.white,
                        onPrimary: Colors.white,
                        onSurface: AppColors.primaryNavy,
                      ),
                      appBarTheme: const AppBarTheme(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primaryNavy,
                        elevation: 0,
                      ),
                      useMaterial3: true,
                    ),
              home: const SplashView(),
            );
          },
        );
      },
    );
  }
}