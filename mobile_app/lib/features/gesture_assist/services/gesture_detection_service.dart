import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:hand_landmarker/hand_landmarker.dart' as mp;

import '../controllers/gesture_action_controller.dart';
import '../controllers/gesture_navigation_controller.dart';
import '../models/gesture_action_model.dart';
import '../models/gesture_log_model.dart';
import '../models/gesture_result_model.dart';
import '../models/hand_landmark_model.dart';
import '../utils/gesture_cooldown_helper.dart';
import '../utils/gesture_stability_helper.dart';
import '../utils/image_preprocessor.dart';
import 'gesture_classifier_service.dart';
import 'gesture_log_local_service.dart';
import '../../../services/offline_service.dart';

class GestureDetectionService {
  final GestureCooldownHelper _cooldown =
      GestureCooldownHelper(cooldownMs: 1000);

  final GestureStabilityHelper _stabilityHelper = GestureStabilityHelper(
    bufferSize: 6,
    requiredStableFrames: 3,
    unknownGraceMs: 500,
  );

  final GestureLogLocalService _localLogService = GestureLogLocalService();
  final GestureClassifierService _classifier = GestureClassifierService();

  GestureActionController? actionController;
  GestureNavigationController? gestureNavigationController;

  bool _isProcessing = false;

  mp.HandLandmarkerPlugin? _handLandmarker;

  bool _useRealDetection = true;

  String _debugGestureType = 'open_palm';

  String? _lastLoggedGestureType;
  DateTime? _lastLoggedAt;

  static const int _sameGestureRelogDelayMs = 5000;

  String get debugGestureType => _debugGestureType;

  void initializeRealDetector() {
    if (_handLandmarker != null) return;

    try {
      _handLandmarker = mp.HandLandmarkerPlugin.create(
        numHands: 1,
        minHandDetectionConfidence: 0.7,
        delegate: mp.HandLandmarkerDelegate.gpu,
      );

      _useRealDetection = true;
      debugPrint('✅ HandLandmarker initialized');
    } catch (e) {
      _useRealDetection = false;
      debugPrint('❌ Failed to initialize HandLandmarker: $e');
    }
  }

  void setDebugGestureType(String gestureType) {
    const allowedGestures = ['open_palm', 'fist', 'thumbs_up'];

    if (allowedGestures.contains(gestureType)) {
      _debugGestureType = gestureType;
    } else {
      _debugGestureType = 'open_palm';
    }

    _stabilityHelper.reset();
  }

  Future<GestureResultModel?> processImage(
    CameraImage image, {
    int sensorOrientation = 90,
  }) async {
    if (_isProcessing) return null;
    _isProcessing = true;

    try {
      if (_useRealDetection && _handLandmarker != null) {
        try {
          final hands = _handLandmarker!.detect(
            image,
            sensorOrientation,
          );

          final realLandmarks = _convertMediaPipeLandmarks(hands);

          if (realLandmarks.length == 21) {
            final rawResult = _classifier.classify(realLandmarks);
            final stableOutput = _stabilityHelper.process(rawResult);
            final resultForUi = stableOutput.result;

            await _handleStableActionIfNeeded(stableOutput);

            return resultForUi;
          }

          _stabilityHelper.reset();
          return GestureResultModel.noHand();
        } catch (e) {
          debugPrint('❌ Real hand detection failed: $e');
          _stabilityHelper.reset();
          return GestureResultModel.noHand();
        }
      }

      // Fallback dummy pipeline.
      // Ini hanya dipakai kalau real detector gagal init / tidak aktif.
      // ignore: unused_local_variable
      final inputData = await ImagePreprocessor.preprocessCameraImage(image);

      final mockLandmarks = _generateMockLandmarks(_debugGestureType);

      final rawResult = _buildDebugGestureResult(
        gestureType: _debugGestureType,
        landmarks: mockLandmarks,
      );

      final stableOutput = _stabilityHelper.process(rawResult);
      final resultForUi = stableOutput.result;

      await _handleStableActionIfNeeded(stableOutput);

      return resultForUi;
    } catch (e) {
      debugPrint('❌ Error in GestureDetectionService: $e');
      return null;
    } finally {
      _isProcessing = false;
    }
  }

  Future<void> _handleStableActionIfNeeded(
    GestureStabilityOutput stableOutput,
  ) async {
    final result = stableOutput.result;

    if (!stableOutput.shouldTriggerAction) {
      return;
    }

    debugPrint(
      '🔥 STABLE GESTURE DETECTED: '
      '${result.gestureType} | '
      'raw=${stableOutput.rawGesture} | '
      'winnerCount=${stableOutput.winnerCount}',
    );

    if (gestureNavigationController != null) {
      debugPrint('📤 [GestureDetection] Calling handleGestureAction via NavigationController');
      
      final actionType = _gestureTypeToActionType(result.gestureType);
      debugPrint('📊 [GestureDetection] ActionType: $actionType, Confidence: ${result.confidence}');

      final actionResult = await gestureNavigationController!.handleGestureAction(
        type: actionType,
        confidence: result.confidence,
        isStable: stableOutput.isStable,
        context: null,
      );

      debugPrint('✅ [GestureDetection] Action executed: ${actionResult.message}');
      
      // Logika logging dipindahkan ke dalam GestureNavigationController.
      // Tidak perlu log duplikat di sini.
      return;
    }

    debugPrint('❌ [GestureDetection] gestureNavigationController is NULL!');

    // Fallback ke action controller lama jika navigation controller tidak ada
    if (actionController != null) {
      if (!_cooldown.canTrigger()) {
        debugPrint('⏳ Gesture fallback cooldown active');
        return;
      }

      _cooldown.updateLastTrigger();
      actionController!.handleAction(result);

      if (_shouldLogGesture(result)) {
        await _saveGestureLog(result);
        _updateLastLoggedGesture(result);
      }
    }
  }

  List<HandLandmark> _convertMediaPipeLandmarks(List<mp.Hand> hands) {
    if (hands.isEmpty) return [];

    final firstHand = hands.first;

    return firstHand.landmarks.map((landmark) {
      return HandLandmark(
        x: landmark.x.clamp(0.0, 1.0),
        y: landmark.y.clamp(0.0, 1.0),
        confidence: 0.95,
      );
    }).toList();
  }

  GestureResultModel _buildDebugGestureResult({
    required String gestureType,
    required List<HandLandmark> landmarks,
  }) {
    switch (gestureType) {
      case 'fist':
        return GestureResultModel(
          gestureType: 'fist',
          action: 'back',
          confidence: 0.85,
          landmarks: landmarks,
          timestamp: DateTime.now(),
        );

      case 'thumbs_up':
        return GestureResultModel(
          gestureType: 'thumbs_up',
          action: 'confirm',
          confidence: 0.95,
          landmarks: landmarks,
          timestamp: DateTime.now(),
        );

      case 'open_palm':
      default:
        return GestureResultModel(
          gestureType: 'open_palm',
          action: 'next',
          confidence: 0.9,
          landmarks: landmarks,
          timestamp: DateTime.now(),
        );
    }
  }

  bool _shouldLogGesture(GestureResultModel result) {
    const validGestures = {
      'open_palm',
      'fist',
      'thumbs_up',
    };

    if (!validGestures.contains(result.gestureType)) {
      return false;
    }

    final now = DateTime.now();

    if (_lastLoggedGestureType == result.gestureType && _lastLoggedAt != null) {
      final diff = now.difference(_lastLoggedAt!).inMilliseconds;

      if (diff < _sameGestureRelogDelayMs) {
        return false;
      }
    }

    return true;
  }

  void _updateLastLoggedGesture(GestureResultModel result) {
    _lastLoggedGestureType = result.gestureType;
    _lastLoggedAt = DateTime.now();
  }

  Future<void> _saveGestureLog(GestureResultModel result) async {
    final user = OfflineService.getLoggedInUser();
    final userId = user?['_id']?.toString() ?? 'unknown_user';

    final log = GestureLogModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      gestureType: result.gestureType,
      action: result.action,
      confidence: result.confidence,
      screenContext: 'gesture_camera_page',
      timestamp: result.timestamp,
    );

    await _localLogService.saveGestureLog(log);
  }

  List<HandLandmark> _generateMockLandmarks(String gestureType) {
    switch (gestureType) {
      case 'fist':
        return _mockFist();
      case 'thumbs_up':
        return _mockThumbsUp();
      case 'open_palm':
      default:
        return _mockOpenPalm();
    }
  }

  HandLandmark _point(double x, double y) {
    return HandLandmark(
      x: x.clamp(0.0, 1.0),
      y: y.clamp(0.0, 1.0),
      confidence: 0.95,
    );
  }

  List<HandLandmark> _mockOpenPalm() {
    return [
      _point(0.50, 0.82),

      _point(0.42, 0.72),
      _point(0.34, 0.62),
      _point(0.27, 0.52),
      _point(0.20, 0.43),

      _point(0.42, 0.62),
      _point(0.39, 0.48),
      _point(0.38, 0.35),
      _point(0.37, 0.22),

      _point(0.50, 0.60),
      _point(0.50, 0.44),
      _point(0.50, 0.30),
      _point(0.50, 0.16),

      _point(0.58, 0.62),
      _point(0.61, 0.48),
      _point(0.62, 0.35),
      _point(0.63, 0.23),

      _point(0.66, 0.67),
      _point(0.71, 0.56),
      _point(0.74, 0.46),
      _point(0.77, 0.36),
    ];
  }

  List<HandLandmark> _mockFist() {
    return [
      _point(0.50, 0.82),

      _point(0.42, 0.72),
      _point(0.36, 0.66),
      _point(0.34, 0.59),
      _point(0.40, 0.54),

      _point(0.40, 0.61),
      _point(0.38, 0.52),
      _point(0.43, 0.48),
      _point(0.48, 0.53),

      _point(0.50, 0.60),
      _point(0.49, 0.50),
      _point(0.53, 0.47),
      _point(0.57, 0.53),

      _point(0.60, 0.61),
      _point(0.61, 0.52),
      _point(0.58, 0.48),
      _point(0.54, 0.54),

      _point(0.68, 0.65),
      _point(0.69, 0.57),
      _point(0.65, 0.53),
      _point(0.60, 0.58),
    ];
  }

  List<HandLandmark> _mockThumbsUp() {
    return [
      _point(0.50, 0.82),

      _point(0.46, 0.68),
      _point(0.45, 0.52),
      _point(0.45, 0.36),
      _point(0.45, 0.20),

      _point(0.42, 0.62),
      _point(0.44, 0.58),
      _point(0.47, 0.58),
      _point(0.50, 0.60),

      _point(0.50, 0.62),
      _point(0.52, 0.58),
      _point(0.54, 0.58),
      _point(0.56, 0.61),

      _point(0.58, 0.63),
      _point(0.59, 0.59),
      _point(0.60, 0.59),
      _point(0.61, 0.62),

      _point(0.65, 0.67),
      _point(0.64, 0.62),
      _point(0.63, 0.61),
      _point(0.62, 0.64),
    ];
  }

  GestureActionType _gestureTypeToActionType(String gestureType) {
    switch (gestureType) {
      case 'thumbs_up':
        return GestureActionType.confirm;
      case 'open_palm':
        return GestureActionType.next;
      case 'fist':
        return GestureActionType.back;
      default:
        return GestureActionType.unknown;
    }
  }

  void dispose() {
    try {
      _stabilityHelper.reset();
      _handLandmarker?.dispose();
      _handLandmarker = null;
      debugPrint('✅ HandLandmarker disposed');
    } catch (e) {
      debugPrint('❌ Failed to dispose HandLandmarker: $e');
    }
  }
}