import 'package:flutter/foundation.dart';
import 'package:camera/camera.dart';
import '../services/camera_service.dart';

class CameraProvider extends ChangeNotifier {
  final CameraService _cameraService = CameraService();
  bool _isInitialized = false;
  bool _isLoading = false;
  String? _errorMessage;

  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  CameraController? get controller => _cameraService.controller;
  bool get isStreaming => _cameraService.isStreaming;

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
