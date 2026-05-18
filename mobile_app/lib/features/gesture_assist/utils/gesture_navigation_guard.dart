import 'package:flutter/material.dart';
import '../models/gesture_action_model.dart';
import '../controllers/gesture_navigation_controller.dart';

/// Guard untuk safety & utility dalam Gesture Navigation
/// Provides helper methods dan warnings untuk safe gesture handling
class GestureNavigationGuard {
  /// Safety wrapper untuk execute gesture action
  /// Ensures context safety dan proper error handling
  static Future<GestureActionResult?> safeExecuteAction({
    required GestureNavigationController controller,
    required GestureActionType type,
    required double confidence,
    required bool isStable,
    BuildContext? context,
    VoidCallback? onSuccess,
    VoidCallback? onFail,
  }) async {
    try {
      final result = await controller.handleGestureAction(
        type: type,
        confidence: confidence,
        isStable: isStable,
        context: context,
      );

      if (result.isSuccess && onSuccess != null) {
        onSuccess();
      } else if (result.isFailed && onFail != null) {
        onFail();
      }

      return result;
    } catch (e) {
      print('[GestureNavigationGuard] ❌ Error executing action: $e');
      onFail?.call();
      return null;
    }
  }

  /// Show feedback dialog untuk gesture action result
  static void showActionFeedback(
    BuildContext context,
    GestureActionResult result,
  ) {
    final color = result.isSuccess ? Colors.green : Colors.red;
    final icon = result.isSuccess ? '✅' : '❌';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$icon ${result.message ?? 'Action'}'),
        backgroundColor: color,
        duration: const Duration(milliseconds: 1500),
      ),
    );
  }

  /// Register gesture actions untuk specific page dengan callbacks
  static void registerPageGestures({
    required GestureNavigationController controller,
    GestureConfirmCallback? onConfirm,
    GestureNextCallback? onNext,
    GestureBackCallback? onBack,
    ScrollController? scrollController,
  }) {
    if (onConfirm != null) {
      controller.registerConfirmAction(onConfirm);
    }
    if (onNext != null) {
      controller.registerNextAction(onNext);
    }
    if (onBack != null) {
      controller.registerBackAction(onBack);
    }
    if (scrollController != null) {
      controller.setScrollController(scrollController);
    }
  }

  /// Clear gesture actions untuk specific page (call in dispose)
  static void unregisterPageGestures(
    GestureNavigationController controller,
  ) {
    controller.clearActions();
  }

  /// Validate jika gesture dapat dijalankan pada saat ini
  static bool validateGestureExecution({
    required double confidence,
    required double minimumConfidence,
    required bool isStable,
    int? timeSinceLastActionMs,
    required int cooldownMs,
  }) {
    // Check confidence
    if (confidence < minimumConfidence) {
      print(
        '[GestureNavigationGuard] ⚠️ Confidence too low: $confidence < $minimumConfidence',
      );
      return false;
    }

    // Check stability
    if (!isStable) {
      print('[GestureNavigationGuard] ⚠️ Gesture not stable yet');
      return false;
    }

    // Check cooldown
    if (timeSinceLastActionMs != null && timeSinceLastActionMs < cooldownMs) {
      print(
        '[GestureNavigationGuard] ⚠️ Cooldown active: $timeSinceLastActionMs < $cooldownMs ms',
      );
      return false;
    }

    return true;
  }

  /// Warning logger untuk non-fatal issues
  static void logWarning(String message) {
    print('[GestureNavigationGuard] ⚠️ WARNING: $message');
  }

  /// Error logger
  static void logError(String message, [Object? error, StackTrace? trace]) {
    print('[GestureNavigationGuard] ❌ ERROR: $message');
    if (error != null) print('  Error: $error');
    if (trace != null) print('  Trace: $trace');
  }

  /// Info logger
  static void logInfo(String message) {
    print('[GestureNavigationGuard] ℹ️ INFO: $message');
  }
}

/// Mixin untuk pages yang ingin support gesture navigation
/// Usage:
/// class MyPage extends StatefulWidget {
///   @override
///   State<MyPage> createState() => MyPageState();
/// }
/// 
/// class MyPageState extends State<MyPage> with GestureNavigationMixin {
///   @override
///   void initState() {
///     super.initState();
///     setupGestureNavigation();
///   }
///   
///   @override
///   void dispose() {
///     cleanupGestureNavigation();
///     super.dispose();
///   }
/// }
mixin GestureNavigationMixin on State {
  late GestureNavigationController _gestureController;

  GestureNavigationController get gestureController => _gestureController;

  /// Override untuk setup gesture actions
  void setupGestureNavigation() {
    _gestureController = GestureNavigationController();
  }

  /// Register gesture actions di page
  void registerGestureActions({
    GestureConfirmCallback? onConfirm,
    GestureNextCallback? onNext,
    GestureBackCallback? onBack,
    ScrollController? scrollController,
  }) {
    GestureNavigationGuard.registerPageGestures(
      controller: _gestureController,
      onConfirm: onConfirm,
      onNext: onNext,
      onBack: onBack,
      scrollController: scrollController,
    );
  }

  /// Cleanup gesture actions saat page ditutup
  void cleanupGestureNavigation() {
    GestureNavigationGuard.unregisterPageGestures(_gestureController);
    _gestureController.dispose();
  }

  /// Show feedback untuk action result (gunakan dalam callback action)
  void showGestureActionFeedback(GestureActionResult result) {
    GestureNavigationGuard.showActionFeedback(context, result);
  }
}
