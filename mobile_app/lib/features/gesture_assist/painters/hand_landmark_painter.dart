import 'package:flutter/material.dart';
import '../models/hand_landmark_model.dart';

class HandLandmarkPainter extends CustomPainter {
  final List<HandLandmark> landmarks;
  final Color pointColor;
  final Color connectionColor;

  HandLandmarkPainter({
    required this.landmarks,
    this.pointColor = Colors.cyanAccent,
    this.connectionColor = Colors.white70,
  });

  static const List<List<int>> _connections = [
    // Thumb
    [0, 1],
    [1, 2],
    [2, 3],
    [3, 4],

    // Index finger
    [0, 5],
    [5, 6],
    [6, 7],
    [7, 8],

    // Middle finger
    [0, 9],
    [9, 10],
    [10, 11],
    [11, 12],

    // Ring finger
    [0, 13],
    [13, 14],
    [14, 15],
    [15, 16],

    // Pinky finger
    [0, 17],
    [17, 18],
    [18, 19],
    [19, 20],

    // Palm shape
    [5, 9],
    [9, 13],
    [13, 17],
    [17, 5],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (landmarks.isEmpty) return;

    final pointPaint = Paint()
      ..color = pointColor
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.fill;

    final linePaint = Paint()
      ..color = connectionColor
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    Offset getOffset(HandLandmark landmark) {
      final corrected = _transformLandmark(landmark);

      return Offset(
        corrected.dx * size.width,
        corrected.dy * size.height,
      );
    }

    // Draw proper MediaPipe hand skeleton connections.
    for (final connection in _connections) {
      final startIndex = connection[0];
      final endIndex = connection[1];

      if (startIndex >= landmarks.length || endIndex >= landmarks.length) {
        continue;
      }

      canvas.drawLine(
        getOffset(landmarks[startIndex]),
        getOffset(landmarks[endIndex]),
        linePaint,
      );
    }

    // Draw landmark points.
    for (final landmark in landmarks) {
      canvas.drawCircle(
        getOffset(landmark),
        4.0,
        pointPaint,
      );
    }
  }

  Offset _transformLandmark(HandLandmark landmark) {
    final x = landmark.x;
    final y = landmark.y;

    // Koreksi orientasi CameraImage ke CameraPreview.
    // Berdasarkan hasil testing device:
    // x' = 1 - y
    // y' = 1 - x
    return Offset(1.0 - y, 1.0 - x);
  }

  @override
  bool shouldRepaint(covariant HandLandmarkPainter oldDelegate) {
    return oldDelegate.landmarks != landmarks ||
        oldDelegate.pointColor != pointColor ||
        oldDelegate.connectionColor != connectionColor;
  }
}