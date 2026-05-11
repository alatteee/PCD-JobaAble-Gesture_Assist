import 'package:flutter/foundation.dart';
import 'package:camera/camera.dart';
import '../services/camera_service.dart';
import '../models/hand_landmark_model.dart';

class CameraProvider extends ChangeNotifier {
  final CameraService _cameraService = CameraService();
  bool _isInitialized = false;
  bool _isLoading = false;
  String? _errorMessage;

  // New: Hand Detection UI states
  List<HandLandmark> _landmarks = [];
  String? _detectedGesture;

  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  CameraController? get controller => _cameraService.controller;
  bool get isStreaming => _cameraService.isStreaming;

  List<HandLandmark> get landmarks => _landmarks;
  String? get detectedGesture => _detectedGesture;

  // For testing UI: Generates dummy hand points
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
    notifyListeners();
  }

  Future<void> initializeCamera() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _cameraService.initialize();
      _isInitialized = true;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void toggleStream(Function(CameraImage) onImage) {
    if (_cameraService.isStreaming) {
      _cameraService.stopImageStream();
    } else {
      _cameraService.startImageStream(onImage);
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _cameraService.dispose();
    super.dispose();
  }
}
