import 'package:camera/camera.dart';

class CameraService {
  CameraController? _controller;
  bool _isStreaming = false;

  CameraController? get controller => _controller;
  bool get isStreaming => _isStreaming;

  Future<void> initialize() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) throw Exception('No cameras available');

    // Use front camera if available, otherwise first camera
    final frontCamera = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    _controller = CameraController(
      frontCamera,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420, // Common for ML
    );

    await _controller!.initialize();
  }

  void startImageStream(Function(CameraImage) onImage) {
    if (_controller == null || _isStreaming) return;
    _isStreaming = true;
    _controller!.startImageStream(onImage);
  }

  Future<void> stopImageStream() async {
    if (_controller == null || !_isStreaming) return;
    _isStreaming = false;
    await _controller!.stopImageStream();
  }

  Future<void> dispose() async {
    await stopImageStream();
    await _controller?.dispose();
    _controller = null;
  }
}
