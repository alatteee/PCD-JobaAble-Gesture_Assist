import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/gesture_action_model.dart';
import '../models/gesture_log_model.dart';
import '../services/gesture_action_service.dart';
import '../services/gesture_log_local_service.dart';

/// Controller utama untuk Gesture Navigation.
///
/// Controller ini dibuat singleton/shared supaya GestureCameraPage dan halaman
/// asli JobAble memakai controller/action registry yang sama.
class GestureNavigationController extends ChangeNotifier {
  static final GestureNavigationController _instance =
      GestureNavigationController._internal();

  factory GestureNavigationController({GestureLogLocalService? logService}) {
    if (logService != null) {
      _instance._logService = logService;
    }
    return _instance;
  }

  GestureNavigationController._internal()
      : _logService = GestureLogLocalService();

  static const String _settingsBoxName = 'accessibilitySettings';
  static const String _gestureNavigationModeKey = 'gestureNavigationMode';

  final GestureActionService _actionService = GestureActionService();
  GestureLogLocalService _logService;

  GestureActionResult? _lastActionResult;
  DateTime? _lastActionTime;

  bool _isEnabled = true;
  bool _isExecuting = false;

  int _cooldownMs = 1500;
  double _confidenceThreshold = 0.65;
  String _screenContext = 'unknown';

  Function(GestureActionResult)? _onActionResult;

  GestureActionResult? get lastActionResult => _lastActionResult;
  bool get isEnabled => _isEnabled;
  bool get isExecuting => _isExecuting;
  int get cooldownMs => _cooldownMs;
  double get confidenceThreshold => _confidenceThreshold;
  String get screenContext => _screenContext;

  void setCooldown(int ms) {
    _cooldownMs = ms.clamp(300, 10000);
    notifyListeners();
  }

  void setConfidenceThreshold(double threshold) {
    _confidenceThreshold = threshold.clamp(0.0, 1.0);
    notifyListeners();
  }

  void setScreenContext(String screenContext) {
    _screenContext = screenContext;
  }

  void setEnabled(bool enabled) {
    _isEnabled = enabled;
    notifyListeners();
  }

  void onActionResult(Function(GestureActionResult) callback) {
    _onActionResult = callback;
  }

  /// Compatibility methods untuk kode lama.
  void registerConfirmAction(GestureConfirmCallback callback) {
    _actionService.onConfirmAction(callback);
  }

  void registerNextAction(GestureNextCallback callback) {
    _actionService.onNextAction(callback);
  }

  void registerBackAction(GestureBackCallback callback) {
    _actionService.onBackAction(callback);
  }

  void setScrollController(ScrollController controller) {
    _actionService.setScrollController(controller);
  }

  /// Register callback halaman aktif.
  void registerPageActions({
    required Object owner,
    GestureConfirmCallback? onConfirm,
    GestureNextCallback? onNext,
    GestureBackCallback? onBack,
    ScrollController? scrollController,
    String? screenContext,
  }) {
    final contextName = screenContext ?? 'unknown';
    _screenContext = contextName;

    _actionService.registerPageActions(
      owner: owner,
      screenContext: contextName,
      onConfirm: onConfirm,
      onNext: onNext,
      onBack: onBack,
      scrollController: scrollController,
    );

    notifyListeners();
  }

  void unregisterPageActions(Object owner) {
    _actionService.unregisterOwner(owner);
    _screenContext = _actionService.activeScreenContext;
    notifyListeners();
  }

  void clearActions() {
    _actionService.clearCallbacks();
    _screenContext = 'unknown';
    notifyListeners();
  }

  Future<bool> _isGestureNavigationModeEnabled() async {
    try {
      final Box<dynamic> box;

      if (Hive.isBoxOpen(_settingsBoxName)) {
        box = Hive.box<dynamic>(_settingsBoxName);
      } else {
        box = await Hive.openBox<dynamic>(_settingsBoxName);
      }

      return box.get(_gestureNavigationModeKey, defaultValue: false) == true;
    } catch (e) {
      debugPrint('[GestureNavigation] Failed to read gesture mode: $e');
      return false;
    }
  }

  bool _isCooldownActive() {
    if (_lastActionTime == null) return false;

    final elapsedMs =
        DateTime.now().difference(_lastActionTime!).inMilliseconds;

    return elapsedMs < _cooldownMs;
  }

  int _remainingCooldownMs() {
    if (_lastActionTime == null) return 0;

    final elapsedMs =
        DateTime.now().difference(_lastActionTime!).inMilliseconds;

    final remaining = _cooldownMs - elapsedMs;
    return remaining <= 0 ? 0 : remaining;
  }

  Future<GestureActionResult> handleGestureAction({
    required GestureActionType type,
    required double confidence,
    required bool isStable,
    BuildContext? context,
    String? screenContext,
  }) async {
    if (screenContext != null) {
      _screenContext = screenContext;
    } else {
      _screenContext = _actionService.activeScreenContext;
    }

    if (!_isEnabled) {
      return _finishAction(
        GestureActionResult(
          type: type,
          status: ActionStatus.skipped,
          message: 'Gesture navigation controller nonaktif',
        ),
        shouldNotify: true,
      );
    }

    final gestureModeEnabled = await _isGestureNavigationModeEnabled();

    if (!gestureModeEnabled) {
      return _finishAction(
        GestureActionResult(
          type: type,
          status: ActionStatus.skipped,
          message: 'Gesture Navigation Mode nonaktif',
        ),
        shouldNotify: true,
      );
    }

    if (type == GestureActionType.unknown) {
      return _finishAction(
        GestureActionResult(
          type: type,
          status: ActionStatus.skipped,
          message: 'Gesture tidak dikenali',
        ),
        shouldNotify: true,
      );
    }

    if (confidence < _confidenceThreshold) {
      return _finishAction(
        GestureActionResult(
          type: type,
          status: ActionStatus.notReady,
          message:
              'Confidence terlalu rendah (${confidence.toStringAsFixed(2)})',
        ),
        shouldNotify: true,
      );
    }

    if (!isStable) {
      return _finishAction(
        GestureActionResult(
          type: type,
          status: ActionStatus.notReady,
          message: 'Gesture belum stabil',
        ),
        shouldNotify: true,
      );
    }

    if (_isExecuting) {
      return _finishAction(
        GestureActionResult(
          type: type,
          status: ActionStatus.notReady,
          message: 'Gesture sedang diproses',
        ),
        shouldNotify: true,
      );
    }

    if (_isCooldownActive()) {
      return _finishAction(
        GestureActionResult(
          type: type,
          status: ActionStatus.notReady,
          message: 'Gesture sedang cooldown (${_remainingCooldownMs()}ms)',
        ),
        shouldNotify: true,
      );
    }

    _isExecuting = true;
    notifyListeners();

    try {
      _actionService.printRegisteredCallbacks();

      final result = await _executeAction(
        type: type,
        context: context,
      );

      _setActionResult(result);

      if (result.isSuccess) {
        _lastActionTime = DateTime.now();

        await _saveSuccessLog(
          type: type,
          confidence: confidence,
          result: result,
        );

        debugPrint('[GestureNavigation] Action success: ${result.message}');
      } else {
        debugPrint(
          '[GestureNavigation] Action ignored/failed: ${result.message}',
        );
      }

      return result;
    } catch (e) {
      final result = GestureActionResult(
        type: type,
        status: ActionStatus.failed,
        message: 'Gagal menjalankan gesture action: $e',
      );

      _setActionResult(result);
      return result;
    } finally {
      _isExecuting = false;
      notifyListeners();
    }
  }

  Future<GestureActionResult> _executeAction({
    required GestureActionType type,
    BuildContext? context,
  }) async {
    switch (type) {
      case GestureActionType.confirm:
        return _actionService.executeConfirm();
      case GestureActionType.next:
        return _actionService.executeNext();
      case GestureActionType.back:
        return _actionService.executeBack(context);
      case GestureActionType.unknown:
        return GestureActionResult(
          type: type,
          status: ActionStatus.skipped,
          message: 'Gesture tidak dikenali',
        );
    }
  }

  Future<void> _saveSuccessLog({
    required GestureActionType type,
    required double confidence,
    required GestureActionResult result,
  }) async {
    try {
      final actionName = _actionNameFromType(type);

      final log = GestureLogModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: 'default_user',
        gestureType: _gestureNameFromType(type),
        action: actionName,
        confidence: confidence,
        screenContext: _actionService.activeScreenContext,
        timestamp: DateTime.now(),
        syncStatus: 'pending',
      );

      await _logService.saveGestureLog(log);
    } catch (e) {
      debugPrint('[GestureNavigation] Failed to save gesture log: $e');
    }
  }

  String _gestureNameFromType(GestureActionType type) {
    switch (type) {
      case GestureActionType.next:
        return 'open_palm';
      case GestureActionType.back:
        return 'fist';
      case GestureActionType.confirm:
        return 'thumbs_up';
      case GestureActionType.unknown:
        return 'unknown';
    }
  }

  String _actionNameFromType(GestureActionType type) {
    switch (type) {
      case GestureActionType.next:
        return 'next';
      case GestureActionType.back:
        return 'back';
      case GestureActionType.confirm:
        return 'confirm';
      case GestureActionType.unknown:
        return 'unknown';
    }
  }

  GestureActionResult _finishAction(
    GestureActionResult result, {
    bool shouldNotify = false,
  }) {
    _setActionResult(result);

    if (shouldNotify) {
      notifyListeners();
    }

    return result;
  }

  void _setActionResult(GestureActionResult result) {
    _lastActionResult = result;
    _onActionResult?.call(result);
  }

  void printStatus() {
    debugPrint('[GestureNavigation] === Status ===');
    debugPrint('[GestureNavigation] Enabled: $_isEnabled');
    debugPrint('[GestureNavigation] Executing: $_isExecuting');
    debugPrint('[GestureNavigation] Cooldown: $_cooldownMs ms');
    debugPrint('[GestureNavigation] Confidence: $_confidenceThreshold');
    debugPrint('[GestureNavigation] Screen Context: $_screenContext');
    debugPrint(
      '[GestureNavigation] Last Action: ${_lastActionResult?.type} - ${_lastActionResult?.status}',
    );
    debugPrint('[GestureNavigation] Last Action Time: $_lastActionTime');
    debugPrint('[GestureNavigation] =================');
    _actionService.printRegisteredCallbacks();
  }

  @override
  // ignore: must_call_super
  void dispose() {
    // Controller ini singleton/shared, jadi jangan clear callback global di sini.
    debugPrint('[GestureNavigation] dispose ignored for singleton controller');
  }
}
