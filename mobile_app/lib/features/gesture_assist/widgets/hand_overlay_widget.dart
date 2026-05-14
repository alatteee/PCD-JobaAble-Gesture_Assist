import 'package:flutter/material.dart';
import '../models/hand_landmark_model.dart';
import '../painters/hand_landmark_painter.dart';

class HandOverlayWidget extends StatelessWidget {
  final List<HandLandmark> landmarks;
  final String? gestureLabel;

  const HandOverlayWidget({
    super.key,
    required this.landmarks,
    this.gestureLabel,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.infinite,
      painter: HandLandmarkPainter(landmarks: landmarks),
    );
  }
}