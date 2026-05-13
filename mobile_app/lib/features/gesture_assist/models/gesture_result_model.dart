import 'hand_landmark_model.dart';

class GestureResultModel {
  final String gestureType; // e.g., 'open_palm', 'fist', 'thumbs_up', 'none'
  final String action;      // e.g., 'next', 'back', 'confirm', 'none'
  final double confidence;
  final List<HandLandmark> landmarks;
  final DateTime timestamp;

  GestureResultModel({
    required this.gestureType,
    required this.action,
    required this.confidence,
    required this.landmarks,
    required this.timestamp,
  });

  factory GestureResultModel.none() {
    return GestureResultModel(
      gestureType: 'none',
      action: 'none',
      confidence: 0.0,
      landmarks: [],
      timestamp: DateTime.now(),
    );
  }
}
