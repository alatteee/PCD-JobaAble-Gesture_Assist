import 'package:flutter/material.dart';
import '../models/gesture_action_model.dart';
import '../models/gesture_log_model.dart';
import '../services/gesture_action_service.dart';
import '../services/gesture_log_local_service.dart';

/// Controller untuk Real Gesture Navigation
/// Handles gesture detection dan execution dengan cooldown & stability check
class GestureNavigationController extends ChangeNotifier {
  final GestureActionService _actionService = GestureActionService();
  final GestureLogLocalService _logService;

  GestureNavigationController({
    GestureLogLocalService? logService,
  }) : _logService = logService ?? GestureLogLocalService();

  // State
  GestureActionResult? _lastActionResult;
  DateTime? _lastActionTime;
  bool _isEnabled = true;

  // Settings
  int _cooldownMs = 1500; // Cooldown antara actions
  double _confidenceThreshold = 0.65; // Minimum confidence

  // Callback untuk feedback ke UI
  Function(GestureActionResult)? _onActionResult;

  // Getters
  GestureActionResult? get lastActionResult => _lastActionResult;
  bool get isEnabled => _isEnabled;
  int get cooldownMs => _cooldownMs;
  double get confidenceThreshold => _confidenceThreshold;

  /// Set cooldown duration (milliseconds)
  void setCooldown(int ms) {
    _cooldownMs = ms;
    notifyListeners();
  }

  /// Register callback untuk action results (untuk UI feedback)
  void onActionResult(Function(GestureActionResult) callback) {
    _onActionResult = callback;
  }

  /// Set confidence threshold (0.0 - 1.0)
  void setConfidenceThreshold(double threshold) {
    _confidenceThreshold = threshold.clamp(0.0, 1.0);
    notifyListeners();
  }

  /// Enable/disable gesture navigation
  void setEnabled(bool enabled) {
    _isEnabled = enabled;
    if (!enabled) {
      _actionService.clearCallbacks();
    }
    notifyListeners();
  }

  /// Register callback untuk CONFIRM (Thumbs Up)
  void registerConfirmAction(GestureConfirmCallback callback) {
    _actionService.onConfirmAction(callback);
  }

  /// Register callback untuk NEXT (Open Palm)
  void registerNextAction(GestureNextCallback callback) {
    _actionService.onNextAction(callback);
  }

  /// Register callback untuk BACK (Fist)
  void registerBackAction(GestureBackCallback callback) {
    _actionService.onBackAction(callback);
  }

  /// Register scroll controller untuk NEXT action (scroll down)
  void setScrollController(ScrollController controller) {
    _actionService.setScrollController(controller);
  }

  /// Clear semua registered actions
  void clearActions() {
    _actionService.clearCallbacks();
  }

  /// Check apakah gesture action bisa dijalankan (cooldown check)
  bool _canExecuteAction() {
    if (!_isEnabled) return false;

    final now = DateTime.now();
    if (_lastActionTime != null) {
      final timeSinceLastAction = now.difference(_lastActionTime!).inMilliseconds;
      if (timeSinceLastAction < _cooldownMs) {
        return false;
      }
    }
    return true;
  }

  /// Handle gesture action dengan safety checks
  /// confidence: nilai 0.0 - 1.0 dari detector
  /// isStable: apakah gesture sudah stabil dari stabilityHelper
  Future<GestureActionResult> handleGestureAction({
    required GestureActionType type,
    required double confidence,
    required bool isStable,
    BuildContext? context,
  }) async {
    // Safety check: tidak aktif
    if (!_isEnabled) {
      final result = GestureActionResult(
        type: type,
        status: ActionStatus.skipped,
        message: 'Gesture Navigation sedang non-aktif',
      );
      _setActionResult(result);
      notifyListeners();
      return result;
    }

    // Check confidence
    if (confidence < _confidenceThreshold) {
      final result = GestureActionResult(
        type: type,
        status: ActionStatus.notReady,
        message:
            'Confidence terlalu rendah: ${confidence.toStringAsFixed(2)} < $_confidenceThreshold',
      );
      _setActionResult(result);
      notifyListeners();
      return result;
    }

    // Check stability
    if (!isStable) {
      final result = GestureActionResult(
        type: type,
        status: ActionStatus.notReady,
        message: 'Gesture belum stabil',
      );
      _setActionResult(result);
      notifyListeners();
      return result;
    }

    // Check cooldown
    if (!_canExecuteAction()) {
      final timeSinceLastAction =
          DateTime.now().difference(_lastActionTime!).inMilliseconds;
      final result = GestureActionResult(
        type: type,
        status: ActionStatus.notReady,
        message:
            'Cooldown aktif: tunggu ${_cooldownMs - timeSinceLastAction}ms',
      );
      _setActionResult(result);
      notifyListeners();
      return result;
    }

    // Execute action
    GestureActionResult result;
    switch (type) {
      case GestureActionType.confirm:
        result = await _actionService.executeConfirm();
        break;
      case GestureActionType.next:
        result = await _actionService.executeNext();
        break;
      case GestureActionType.back:
        result = await _actionService.executeBack(context);
        break;
      case GestureActionType.unknown:
        result = GestureActionResult(
          type: type,
          status: ActionStatus.failed,
          message: 'Gesture type unknown',
        );
    }

    // Update state
    _setActionResult(result);
    _lastActionTime = DateTime.now();

    // Log action jika berhasil
    if (result.isSuccess) {
      try {
        final log = GestureLogModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          userId: 'default_user', // TODO: Get from auth/user context
          gestureType: type.toString().split('.').last,
          action: type.toString().split('.').last,
          confidence: confidence,
          screenContext: 'gesture_navigation',
          timestamp: DateTime.now(),
          syncStatus: 'pending',
        );
        await _logService.saveGestureLog(log);
      } catch (e) {
        print('[GestureNavigation] ⚠️ Failed to save log: $e');
      }
      print('[GestureNavigation] ✅ Action successful: ${result.message}');
    } else {
      print('[GestureNavigation] ❌ Action failed: ${result.message}');
    }

    notifyListeners();
    return result;
  }

  /// Helper untuk set result dan trigger callback UI
  void _setActionResult(GestureActionResult result) {
    _lastActionResult = result;
    _onActionResult?.call(result);
  }

  /// Debug helper
  void printStatus() {
    print('[GestureNavigation] === Status ===');
    print('[GestureNavigation] Enabled: $_isEnabled');
    print('[GestureNavigation] Cooldown: $_cooldownMs ms');
    print('[GestureNavigation] Confidence Threshold: $_confidenceThreshold');
    print(
      '[GestureNavigation] Last Action: ${_lastActionResult?.type} - ${_lastActionResult?.status}',
    );
    print('[GestureNavigation] Last Action Time: $_lastActionTime');
    print('[GestureNavigation] ==================');
    _actionService.printRegisteredCallbacks();
  }

  @override
  void dispose() {
    clearActions();
    super.dispose();
  }
}
