import 'hand_landmark_model.dart';

class GestureResultModel {
  final String gestureType; // open_palm, fist, thumbs_up, unknown, no_hand
  final String action; // next, back, confirm, no_action, waiting
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

  factory GestureResultModel.unknown(List<HandLandmark> landmarks) {
    return GestureResultModel(
      gestureType: 'unknown',
      action: 'no_action',
      confidence: 0.0,
      landmarks: landmarks,
      timestamp: DateTime.now(),
    );
  }

  factory GestureResultModel.noHand() {
    return GestureResultModel(
      gestureType: 'no_hand',
      action: 'waiting',
      confidence: 0.0,
      landmarks: [],
      timestamp: DateTime.now(),
    );
  }
}