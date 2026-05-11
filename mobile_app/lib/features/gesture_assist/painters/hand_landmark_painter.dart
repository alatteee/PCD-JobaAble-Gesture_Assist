import 'package:flutter/material.dart';
import '../models/hand_landmark_model.dart';
import '../../../core/constants/app_colors.dart';

class HandLandmarkPainter extends CustomPainter {
  final List<HandLandmark> landmarks;
  final Color pointColor;
  final Color connectionColor;

  HandLandmarkPainter({
    required this.landmarks,
    this.pointColor = Colors.cyanAccent,
    this.connectionColor = Colors.white70,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (landmarks.isEmpty) return;

    final pointPaint = Paint()
      ..color = pointColor
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round;

    final linePaint = Paint()
      ..color = connectionColor
      ..strokeWidth = 2.0;

    // Helper to convert normalized to screen coordinates
    Offset getOffset(HandLandmark landmark) {
      return Offset(landmark.x * size.width, landmark.y * size.height);
    }

    // 1. Draw connections (Basic skeleton)
    // MediaPipe Hand Connections indexing (simplified for dummy)
    if (landmarks.length >= 5) {
      for (int i = 0; i < landmarks.length - 1; i++) {
        canvas.drawLine(
          getOffset(landmarks[i]),
          getOffset(landmarks[i + 1]),
          linePaint,
        );
      }
    }

    // 2. Draw landmark points
    for (var landmark in landmarks) {
      canvas.drawCircle(getOffset(landmark), 3.0, pointPaint);
    }
  }

  @override
  bool shouldRepaint(covariant HandLandmarkPainter oldDelegate) {
    return oldDelegate.landmarks != landmarks;
  }
}
