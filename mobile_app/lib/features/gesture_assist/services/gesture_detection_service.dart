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
  final GestureCooldownHelper _cooldown = GestureCooldownHelper(cooldownMs: 1000);
  final GestureLogLocalService _localLogService = GestureLogLocalService();

  bool _isProcessing = false;

  /// Main entry point for the detection pipeline.
  /// Menerima CameraImage, melakukan preprocess, dan menghasilkan GestureResultModel.
  Future<GestureResultModel?> processImage(CameraImage image) async {
    if (_isProcessing) return null;
    _isProcessing = true;

    try {
      // 1. Preprocessing (Resize, Color Convert, Normalization)
      // ignore: unused_local_variable
      final inputData = await ImagePreprocessor.preprocessCameraImage(image);

      // 2. Inference (Placeholder for TFLite)
      // For now, we use mock landmarks to test the pipeline
      final mockLandmarks = _generateMockLandmarks();

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

  /// Placeholder for actual landmark detection output
  List<HandLandmark> _generateMockLandmarks() {
    // Generate 21 dummy landmarks
    return List.generate(21, (index) {
      return HandLandmark(
        x: 0.5, 
        y: 0.5, 
        confidence: 0.9,
      );
    });
  }
}
