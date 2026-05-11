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
    return Stack(
      children: [
        // 1. The Skeletal Drawing
        CustomPaint(
          size: Size.infinite,
          painter: HandLandmarkPainter(landmarks: landmarks),
        ),

        // 2. Gesture Label Prompt
        if (gestureLabel != null)
          Positioned(
            top: 100,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  gestureLabel!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
