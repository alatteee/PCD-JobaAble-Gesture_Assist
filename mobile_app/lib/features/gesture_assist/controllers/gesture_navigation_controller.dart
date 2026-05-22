import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/gesture_action_model.dart';
import '../models/gesture_log_model.dart';
import '../services/gesture_action_service.dart';
import '../services/gesture_log_local_service.dart';
import '../services/gesture_log_sync_service.dart';

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

  /// Cache lokal untuk status Gesture Navigation Mode.
  /// Ini disinkronkan langsung dari AccessibilityController agar tidak hanya
  /// bergantung pada pembacaan Hive setiap kali action berjalan.
  bool? _gestureModeCache;

  int _cooldownMs = 1500;
  double _confidenceThreshold = 0.65;
  String _screenContext = 'unknown';
  String _userId = '';

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

  /// Sinkronisasi langsung dari Accessibility Settings.
  ///
  /// Dipakai agar toggle Gesture Navigation Mode yang terlihat ON di UI
  /// langsung terbaca ON oleh controller gesture.
  void syncGestureNavigationMode(bool enabled) {
    _gestureModeCache = enabled;
    _isEnabled = enabled;

    debugPrint('[GestureNavigation] Gesture mode synced: $enabled');

    notifyListeners();
  }

  void setUserId(String userId) {
    _userId = userId;
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
    if (_gestureModeCache != null) {
      debugPrint(
        '[GestureNavigation] Gesture mode read from cache: $_gestureModeCache',
      );
      return _gestureModeCache == true;
    }

    try {
      final Box<dynamic> box;

      if (Hive.isBoxOpen(_settingsBoxName)) {
        box = Hive.box<dynamic>(_settingsBoxName);
      } else {
        box = await Hive.openBox<dynamic>(_settingsBoxName);
      }

      final savedValue = box.get(
        _gestureNavigationModeKey,
        defaultValue: false,
      );

      _gestureModeCache = savedValue == true;

      debugPrint(
        '[GestureNavigation] Gesture mode read from Hive: $savedValue',
      );

      return savedValue == true;
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

  /// Dipakai oleh GestureDetectionService untuk menampilkan feedback cooldown
  /// tanpa menjalankan action baru.
  bool notifyCooldownIfActive(GestureActionType type) {
    if (!_isCooldownActive()) {
      return false;
    }

    _finishAction(
      GestureActionResult(
        type: type,
        status: ActionStatus.notReady,
        message: 'Gesture cooldown... (${_remainingCooldownMs()}ms)',
      ),
      shouldNotify: true,
    );

    return true;
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
          message: 'Gesture cooldown... (${_remainingCooldownMs()}ms)',
        ),
        shouldNotify: true,
      );
    }

    _isExecuting = true;
    notifyListeners();

    GestureActionResult result;

    switch (type) {
      case GestureActionType.confirm:
        result = await _actionService.executeConfirm();
        break;
      case GestureActionType.next:
        result = await _actionService.executeNext();
        break;
      case GestureActionType.back:
        result = await _actionService.executeBack(null);
        break;
      case GestureActionType.unknown:
        result = GestureActionResult(
          type: type,
          status: ActionStatus.skipped,
          message: 'Gesture tidak dikenali',
        );
        break;
    }

    if (result.isSuccess) {
      _lastActionTime = DateTime.now();
      await _saveLog(type, confidence);
    }

    return _finishAction(result);
  }

  Future<void> _saveLog(GestureActionType type, double confidence) async {
    final now = DateTime.now();

    final currentScreenContext = _screenContext.isNotEmpty
        ? _screenContext
        : _actionService.activeScreenContext;

    final uniqueId =
        '${now.microsecondsSinceEpoch}_${currentScreenContext}_${type.name}';

    final log = GestureLogModel(
      id: uniqueId,
      userId: _userId.trim().isNotEmpty ? _userId.trim() : 'unknown',
      gestureType: _actionTypeToGestureType(type),
      action: type.name,
      confidence: confidence,
      screenContext:
          currentScreenContext.isNotEmpty ? currentScreenContext : 'unknown',
      timestamp: now,
      syncStatus: 'pending',
    );

    try {
      await _logService.saveGestureLog(log);

      debugPrint(
        '[GestureNavigation] Log saved locally: '
        '${log.gestureType} | ${log.action} | ${log.screenContext} | ${log.confidence}',
      );

      GestureLogSyncService().syncPendingGestureLogs();
    } catch (e) {
      debugPrint('[GestureNavigation] Failed to save gesture log: $e');
    }
  }

  String _actionTypeToGestureType(GestureActionType type) {
    switch (type) {
      case GestureActionType.confirm:
        return 'thumbs_up';
      case GestureActionType.next:
        return 'open_palm';
      case GestureActionType.back:
        return 'fist';
      case GestureActionType.unknown:
        return 'unknown';
    }
  }

  GestureActionResult _finishAction(
    GestureActionResult result, {
    bool shouldNotify = true,
  }) {
    _isExecuting = false;
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
    debugPrint('[GestureNavigation] Gesture Mode Cache: $_gestureModeCache');
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