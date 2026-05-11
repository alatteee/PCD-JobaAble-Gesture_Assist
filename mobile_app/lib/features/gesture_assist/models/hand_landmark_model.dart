class HandLandmark {
  final double x; // Normalized 0.0 - 1.0
  final double y; // Normalized 0.0 - 1.0
  final double confidence;

  HandLandmark({
    required this.x,
    required this.y,
    this.confidence = 0.0,
  });

  // Factory for easy dummy data creation
  factory HandLandmark.dummy(double x, double y) {
    return HandLandmark(x: x, y: y, confidence: 1.0);
  }
}

class HandResult {
  final List<HandLandmark> landmarks;
  final String? gestureLabel;

  HandResult({
    required this.landmarks,
    this.gestureLabel,
  });
}
