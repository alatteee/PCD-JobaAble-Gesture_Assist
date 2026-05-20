import 'package:flutter/material.dart';

/// Simple gesture status indicator widget.
/// Shows current gesture detection status without requiring CameraProvider.
/// Can be placed anywhere without provider scope issues.
class GestureStatusIndicator extends StatelessWidget {
  final String? gestureStatus;
  final bool isDetecting;

  const GestureStatusIndicator({
    super.key,
    this.gestureStatus,
    this.isDetecting = false,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 80,
      right: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _getStatusColor(),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
            )
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Gesture',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            if (isDetecting)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: _getStatusColor(),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    gestureStatus ?? 'Detecting...',
                    style: TextStyle(
                      color: _getStatusColor(),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              )
            else
              Text(
                'Ready',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 10,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor() {
    switch (gestureStatus?.toLowerCase()) {
      case 'open_palm':
        return Colors.lime;
      case 'fist':
        return Colors.red;
      case 'thumbs_up':
        return Colors.cyan;
      default:
        return Colors.grey;
    }
  }
}
