import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/constants/app_colors.dart';
import 'features/profile/accessibility_settings_view.dart';
import 'features/splash/splash_view.dart';
import 'services/mongo_service.dart';
import 'services/offline_service.dart';
import 'services/sync_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (FlutterErrorDetails details) {
    final errorText = details.exceptionAsString();

    if (_isIgnoredMongoSocketError(errorText)) {
      print('⚠️ Ignored Mongo socket disconnect: $errorText');
      return;
    }

    FlutterError.presentError(details);
  };

  runZonedGuarded(() async {
    await dotenv.load(fileName: ".env");
    await OfflineService.init();
    await MongoService.connect();

    runApp(const JobAbleApp());
  }, (error, stack) {
    final errorText = error.toString();

    if (_isIgnoredMongoSocketError(errorText)) {
      print('⚠️ Ignored async Mongo disconnect: $errorText');
      return;
    }

    print('❌ Unhandled error: $error');
    print(stack);
  });
}

bool _isIgnoredMongoSocketError(String errorText) {
  return errorText.contains('Software caused connection abort') ||
      errorText.contains('No master connection') ||
      errorText.contains('connection closed') ||
      errorText.contains('MongoDB ConnectionException') ||
      errorText.contains('SocketException');
}

class JobAbleApp extends StatefulWidget {
  const JobAbleApp({super.key});

  @override
  State<JobAbleApp> createState() => _JobAbleAppState();
}

class _JobAbleAppState extends State<JobAbleApp> {
  @override
  void initState() {
    super.initState();
  }

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
                SyncService.initialize(context);

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