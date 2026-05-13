import 'dart:isolate';
import 'package:camera/camera.dart';

/// Isolate for running heavy ML inference in the background.
/// This prevents UI jank during image processing.
class GestureInferenceIsolate {
  static Future<void> spawn() async {
    // Pipeline implementation using isolates will go here 
    // when TFLite interpreter is ready.
  }

  // Placeholder for isolate message handling
  static void _entryPoint(SendPort sendPort) {
    // Isolate logic
  }
}

/// Helper class to pass data between Main Isolate and Inference Isolate
class InferenceRequest {
  final CameraImage image;
  InferenceRequest(this.image);
}
