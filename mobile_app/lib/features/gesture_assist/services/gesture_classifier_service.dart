import '../models/hand_landmark_model.dart';
import '../models/gesture_result_model.dart';

class GestureClassifierService {
  /// Classifies common gestures based on the 21 hand landmarks.
  /// This is currently rule-based (heuristic) as a placeholder for the ML model.
  GestureResultModel classify(List<HandLandmark> landmarks) {
    if (landmarks.length < 21) {
      return GestureResultModel.none();
    }

    // Example logic using basic heuristics:
    // 0: Wrist, 4: Thumb tip, 8: Index tip, 12: Middle tip, 16: Ring tip, 20: Pinky tip
    
    if (_isOpenPalm(landmarks)) {
      return GestureResultModel(
        gestureType: 'open_palm',
        action: 'next',
        confidence: 0.9,
        landmarks: landmarks,
        timestamp: DateTime.now(),
      );
    } else if (_isFist(landmarks)) {
      return GestureResultModel(
        gestureType: 'fist',
        action: 'back',
        confidence: 0.85,
        landmarks: landmarks,
        timestamp: DateTime.now(),
      );
    } else if (_isThumbsUp(landmarks)) {
      return GestureResultModel(
        gestureType: 'thumbs_up',
        action: 'confirm',
        confidence: 0.95,
        landmarks: landmarks,
        timestamp: DateTime.now(),
      );
    }

    return GestureResultModel.none();
  }

  // --- HEURISTIC LOGIC (MOCK) ---
  
  bool _isOpenPalm(List<HandLandmark> landmarks) {
    // Heuristic: All fingers are significantly above the wrist (y is smaller for higher positions)
    final wristY = landmarks[0].y;
    return landmarks[8].y < wristY - 0.2 && 
           landmarks[12].y < wristY - 0.2 && 
           landmarks[20].y < wristY - 0.2;
  }

  bool _isFist(List<HandLandmark> landmarks) {
    // Heuristic: Finger tips are very close to the wrist or palm center
    final wristY = landmarks[0].y;
    return landmarks[8].y > wristY - 0.1 && 
           landmarks[12].y > wristY - 0.1 && 
           landmarks[20].y > wristY - 0.1;
  }

  bool _isThumbsUp(List<HandLandmark> landmarks) {
    // Heuristic: Thumb tip (index 4) is high, other fingers are low
    return landmarks[4].y < landmarks[8].y - 0.1 && 
           landmarks[4].y < landmarks[12].y - 0.1;
  }
}
