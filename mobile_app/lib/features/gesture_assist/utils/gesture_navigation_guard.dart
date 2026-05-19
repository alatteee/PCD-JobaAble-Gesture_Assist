import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../controllers/gesture_navigation_controller.dart';
import '../models/gesture_action_model.dart';

/// Guard/helper untuk integrasi gesture navigation di halaman JobAble.
class GestureNavigationGuard {
  static Future<GestureActionResult?> safeExecuteAction({
    required GestureNavigationController controller,
    required GestureActionType type,
    required double confidence,
    required bool isStable,
    BuildContext? context,
    String? screenContext,
    VoidCallback? onSuccess,
    VoidCallback? onFail,
    bool showFeedback = true,
  }) async {
    try {
      final result = await controller.handleGestureAction(
        type: type,
        confidence: confidence,
        isStable: isStable,
        context: context,
        screenContext: screenContext,
      );

      if (context != null && context.mounted && showFeedback) {
        showActionFeedback(context, result);
      }

      if (result.isSuccess) {
        HapticFeedback.lightImpact();
        onSuccess?.call();
      } else if (result.isFailed) {
        onFail?.call();
      }

      return result;
    } catch (e) {
      debugPrint('[GestureNavigationGuard] Error executing action: $e');
      onFail?.call();

      if (context != null && context.mounted && showFeedback) {
        showErrorFeedback(context, 'Gagal menjalankan gesture action');
      }

      return null;
    }
  }

  static void showActionFeedback(
    BuildContext context,
    GestureActionResult result,
  ) {
    Color color;
    IconData icon;

    if (result.isSuccess) {
      color = const Color(0xFF16A34A);
      icon = Icons.check_circle_rounded;
    } else if (result.isNotReady) {
      color = Colors.orange;
      icon = Icons.hourglass_bottom_rounded;
    } else if (result.isSkipped) {
      color = Colors.orange;
      icon = Icons.info_rounded;
    } else {
      color = Colors.red;
      icon = Icons.error_rounded;
    }

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: color,
        duration: const Duration(milliseconds: 1500),
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                result.message ?? 'Gesture action',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static void showSuccessFeedback(BuildContext context, String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF16A34A),
        duration: const Duration(milliseconds: 1500),
        content: Text(message),
      ),
    );
  }

  static void showErrorFeedback(BuildContext context, String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.red,
        duration: const Duration(milliseconds: 1500),
        content: Text(message),
      ),
    );
  }

  static void registerPageGestures({
    required GestureNavigationController controller,
    required Object owner,
    GestureConfirmCallback? onConfirm,
    GestureNextCallback? onNext,
    GestureBackCallback? onBack,
    ScrollController? scrollController,
    String? screenContext,
  }) {
    controller.registerPageActions(
      owner: owner,
      onConfirm: onConfirm,
      onNext: onNext,
      onBack: onBack,
      scrollController: scrollController,
      screenContext: screenContext,
    );
  }

  static void unregisterPageGestures(
    GestureNavigationController controller, {
    required Object owner,
  }) {
    controller.unregisterPageActions(owner);
  }

  static bool validateGestureExecution({
    required double confidence,
    required double minimumConfidence,
    required bool isStable,
    int? timeSinceLastActionMs,
    required int cooldownMs,
  }) {
    if (confidence < minimumConfidence) {
      debugPrint(
        '[GestureNavigationGuard] Confidence too low: $confidence < $minimumConfidence',
      );
      return false;
    }

    if (!isStable) {
      debugPrint('[GestureNavigationGuard] Gesture not stable yet');
      return false;
    }

    if (timeSinceLastActionMs != null && timeSinceLastActionMs < cooldownMs) {
      debugPrint(
        '[GestureNavigationGuard] Cooldown active: $timeSinceLastActionMs < $cooldownMs ms',
      );
      return false;
    }

    return true;
  }

  static void logWarning(String message) {
    debugPrint('[GestureNavigationGuard] WARNING: $message');
  }

  static void logError(String message, [Object? error, StackTrace? trace]) {
    debugPrint('[GestureNavigationGuard] ERROR: $message');

    if (error != null) {
      debugPrint('Error: $error');
    }

    if (trace != null) {
      debugPrint('Trace: $trace');
    }
  }

  static void logInfo(String message) {
    debugPrint('[GestureNavigationGuard] INFO: $message');
  }
}

/// Mixin opsional untuk page yang mau support gesture navigation.
mixin GestureNavigationMixin<T extends StatefulWidget> on State<T> {
  late final GestureNavigationController gestureController;

  void setupGestureNavigation({String screenContext = 'unknown'}) {
    gestureController = GestureNavigationController();
    gestureController.setScreenContext(screenContext);
  }

  void registerGestureActions({
    GestureConfirmCallback? onConfirm,
    GestureNextCallback? onNext,
    GestureBackCallback? onBack,
    ScrollController? scrollController,
    String? screenContext,
  }) {
    GestureNavigationGuard.registerPageGestures(
      controller: gestureController,
      owner: this,
      onConfirm: onConfirm,
      onNext: onNext,
      onBack: onBack,
      scrollController: scrollController,
      screenContext: screenContext,
    );
  }

  void cleanupGestureNavigation() {
    GestureNavigationGuard.unregisterPageGestures(
      gestureController,
      owner: this,
    );
  }

  void showGestureActionFeedback(GestureActionResult result) {
    if (!mounted) return;
    GestureNavigationGuard.showActionFeedback(context, result);
  }
}
