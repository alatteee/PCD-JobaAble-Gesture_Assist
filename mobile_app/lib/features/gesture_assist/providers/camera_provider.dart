import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

import '../services/camera_service.dart';
import '../models/hand_landmark_model.dart';
import '../services/gesture_detection_service.dart';
import '../controllers/gesture_action_controller.dart';

class CameraProvider extends ChangeNotifier {
  final CameraService _cameraService = CameraService();
  final GestureDetectionService _detectionService = GestureDetectionService();
  
  GestureActionController? _actionController;

  bool _isInitialized = false;
  bool _isLoading = false;
  String? _errorMessage;

  // ... rest of state ...

  // Detection UI states
  List<HandLandmark> _landmarks = [];
  String? _detectedGesture;
  String? _lastAction;

  // Debug dummy gesture state
  String _debugGestureType = 'open_palm';

  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  CameraController? get controller => _cameraService.controller;
  bool get isStreaming => _cameraService.isStreaming;

  List<HandLandmark> get landmarks => _landmarks;
  String? get detectedGesture => _detectedGesture;
  String? get lastAction => _lastAction;
  String get debugGestureType => _debugGestureType;

  /// Mengganti mode dummy gesture untuk testing:
  /// open_palm, fist, thumbs_up.
  void setDebugGestureType(String gestureType) {
    _debugGestureType = gestureType;
    _detectionService.setDebugGestureType(gestureType);

    // Reset label sebentar agar user tahu mode berubah.
    _detectedGesture = null;
    _lastAction = null;

    notifyListeners();
  }

  /// Menghubungkan detection service ke action controller yang butuh context.
  void setActionController(GestureActionController controller) {
    _detectionService.actionController = controller;
  }

  // For testing UI: Generates dummy hand points manual tanpa camera stream.
  // Ini tetap dipertahankan agar tombol test lama tidak merusak flow.
  void showDummyHand() {
    _landmarks = [
      HandLandmark.dummy(0.5, 0.7), // Wrist
      HandLandmark.dummy(0.4, 0.6), // Thumb base
      HandLandmark.dummy(0.35, 0.5), // Thumb tip
      HandLandmark.dummy(0.45, 0.4), // Index tip
      HandLandmark.dummy(0.55, 0.4), // Middle tip
    ];
    _detectedGesture = "Open Palm";
    notifyListeners();
  }

  void clearDummyHand() {
    _landmarks = [];
    _detectedGesture = null;
    _lastAction = null;
    notifyListeners();
  }

  // Integrasi dengan Detection Pipeline
  Future<void> _onImageStream(CameraImage image) async {
    final controller = _cameraService.controller;

    final sensorOrientation =
        controller?.description.sensorOrientation ?? 90;

    final result = await _detectionService.processImage(
      image,
      sensorOrientation: 90,
    );

    if (result != null) {
      _landmarks = result.landmarks;
      _detectedGesture = result.gestureType;
      _lastAction = result.action;
      notifyListeners();
    }
  }

  Future<void> initializeCamera() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _cameraService.initialize();

      // Initialize real MediaPipe hand landmark detector setelah camera siap.
      _detectionService.initializeRealDetector();

      _isInitialized = true;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('❌ CameraProvider initializeCamera error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void toggleStream() {
    if (_cameraService.isStreaming) {
      _cameraService.stopImageStream();
    } else {
      _cameraService.startImageStream(_onImageStream);
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _cameraService.dispose();
    _detectionService.dispose();
    super.dispose();
  }
}