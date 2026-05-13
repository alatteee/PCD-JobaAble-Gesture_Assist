import 'dart:async';
import 'package:camera/camera.dart';
import '../models/gesture_result_model.dart';
import '../models/hand_landmark_model.dart';
import '../utils/image_preprocessor.dart';
import '../utils/gesture_cooldown_helper.dart';
import 'gesture_classifier_service.dart';
import 'gesture_log_local_service.dart';
import '../models/gesture_log_model.dart';
import '../../../services/offline_service.dart';

class GestureDetectionService {
  final GestureClassifierService _classifier = GestureClassifierService();
  final GestureCooldownHelper _cooldown =
      GestureCooldownHelper(cooldownMs: 1000);
  final GestureLogLocalService _localLogService = GestureLogLocalService();

  bool _isProcessing = false;

  /// Mode dummy gesture untuk tahap testing sebelum AI asli.
  /// Nilai yang didukung:
  /// - open_palm
  /// - fist
  /// - thumbs_up
  String _debugGestureType = 'open_palm';

  String get debugGestureType => _debugGestureType;

  void setDebugGestureType(String gestureType) {
    const allowedGestures = ['open_palm', 'fist', 'thumbs_up'];

    if (allowedGestures.contains(gestureType)) {
      _debugGestureType = gestureType;
    } else {
      _debugGestureType = 'open_palm';
    }
  }

  /// Main entry point for the detection pipeline.
  /// Menerima CameraImage, melakukan preprocess, dan menghasilkan GestureResultModel.
  Future<GestureResultModel?> processImage(CameraImage image) async {
    if (_isProcessing) return null;
    _isProcessing = true;

    try {
      // 1. Preprocessing (Resize, Color Convert, Normalization)
      // Untuk sekarang masih placeholder sebelum TFLite/MediaPipe.
      // ignore: unused_local_variable
      final inputData = await ImagePreprocessor.preprocessCameraImage(image);

      // 2. Inference dummy.
      // Untuk saat ini, landmark masih mock agar overlay dan classifier bisa dites.
      final mockLandmarks = _generateMockLandmarks(_debugGestureType);

      // 3. Classification
      final result = _classifier.classify(mockLandmarks);

      // 4. Action handling and logging
      if (result.gestureType != 'none' && _cooldown.canTrigger()) {
        _cooldown.updateLastTrigger();

        // Save to Hive
        await _saveGestureLog(result);

        return result;
      }

      return result;
    } catch (e) {
      print('❌ Error in GestureDetectionService: $e');
      return null;
    } finally {
      _isProcessing = false;
    }
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

  /// Placeholder for actual landmark detection output.
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

  /// 21 titik landmark tangan terbuka.
  /// Index mengikuti format umum MediaPipe:
  /// 0 wrist
  /// 1-4 thumb
  /// 5-8 index
  /// 9-12 middle
  /// 13-16 ring
  /// 17-20 pinky
  List<HandLandmark> _mockOpenPalm() {
    return [
      _point(0.50, 0.82), // 0 wrist

      _point(0.42, 0.72), // 1 thumb cmc
      _point(0.34, 0.62), // 2 thumb mcp
      _point(0.27, 0.52), // 3 thumb ip
      _point(0.20, 0.43), // 4 thumb tip

      _point(0.42, 0.62), // 5 index mcp
      _point(0.39, 0.48), // 6 index pip
      _point(0.38, 0.35), // 7 index dip
      _point(0.37, 0.22), // 8 index tip

      _point(0.50, 0.60), // 9 middle mcp
      _point(0.50, 0.44), // 10 middle pip
      _point(0.50, 0.30), // 11 middle dip
      _point(0.50, 0.16), // 12 middle tip

      _point(0.58, 0.62), // 13 ring mcp
      _point(0.61, 0.48), // 14 ring pip
      _point(0.62, 0.35), // 15 ring dip
      _point(0.63, 0.23), // 16 ring tip

      _point(0.66, 0.67), // 17 pinky mcp
      _point(0.71, 0.56), // 18 pinky pip
      _point(0.74, 0.46), // 19 pinky dip
      _point(0.77, 0.36), // 20 pinky tip
    ];
  }

  /// 21 titik dummy untuk fist.
  /// Dibuat lebih menyebar agar titik dan garis tetap terlihat jelas di overlay,
  /// tetapi ujung jari tetap berada dekat area telapak sehingga terbaca sebagai fist.
  List<HandLandmark> _mockFist() {
    return [
      _point(0.50, 0.82), // 0 wrist

      // Thumb folded across palm
      _point(0.42, 0.72), // 1 thumb cmc
      _point(0.36, 0.66), // 2 thumb mcp
      _point(0.34, 0.59), // 3 thumb ip
      _point(0.40, 0.54), // 4 thumb tip

      // Index folded
      _point(0.40, 0.61), // 5 index mcp
      _point(0.38, 0.52), // 6 index pip
      _point(0.43, 0.48), // 7 index dip
      _point(0.48, 0.53), // 8 index tip

      // Middle folded
      _point(0.50, 0.60), // 9 middle mcp
      _point(0.49, 0.50), // 10 middle pip
      _point(0.53, 0.47), // 11 middle dip
      _point(0.57, 0.53), // 12 middle tip

      // Ring folded
      _point(0.60, 0.61), // 13 ring mcp
      _point(0.61, 0.52), // 14 ring pip
      _point(0.58, 0.48), // 15 ring dip
      _point(0.54, 0.54), // 16 ring tip

      // Pinky folded
      _point(0.68, 0.65), // 17 pinky mcp
      _point(0.69, 0.57), // 18 pinky pip
      _point(0.65, 0.53), // 19 pinky dip
      _point(0.60, 0.58), // 20 pinky tip
    ];
  }

  /// 21 titik dummy untuk thumbs up.
  /// Thumb dibuat tinggi, jari lain dilipat.
  List<HandLandmark> _mockThumbsUp() {
    return [
      _point(0.50, 0.82), // 0 wrist

      _point(0.46, 0.68),
      _point(0.45, 0.52),
      _point(0.45, 0.36),
      _point(0.45, 0.20), // 4 thumb tip tinggi

      _point(0.42, 0.62),
      _point(0.44, 0.58),
      _point(0.47, 0.58),
      _point(0.50, 0.60), // 8 index tip rendah/lipat

      _point(0.50, 0.62),
      _point(0.52, 0.58),
      _point(0.54, 0.58),
      _point(0.56, 0.61), // 12 middle tip rendah/lipat

      _point(0.58, 0.63),
      _point(0.59, 0.59),
      _point(0.60, 0.59),
      _point(0.61, 0.62), // 16 ring tip rendah/lipat

      _point(0.65, 0.67),
      _point(0.64, 0.62),
      _point(0.63, 0.61),
      _point(0.62, 0.64), // 20 pinky tip rendah/lipat
    ];
  }
}