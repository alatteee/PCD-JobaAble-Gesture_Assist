import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/camera_provider.dart';
import './camera_preview_widget.dart';
import './hand_overlay_widget.dart';

/// Mini camera preview widget untuk debugging gesture detection.
/// Tampilkan di corner dengan gesture status real-time dan hand landmark.
class MiniCameraPreview extends StatelessWidget {
  final double width;
  final double height;

  const MiniCameraPreview({
    super.key,
    this.width = 120,
    this.height = 160,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<CameraProvider>(
      builder: (context, cameraProvider, _) {
        if (!cameraProvider.isInitialized || cameraProvider.controller == null) {
          return const SizedBox.shrink();
        }

        return Positioned(
          top: 60,
          right: 16,
          child: Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: Colors.black,
              border: Border.all(
                color: cameraProvider.isStreaming ? Colors.green : Colors.grey,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 12,
                  spreadRadius: 2,
                )
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Camera preview
                  CameraPreviewWidget(controller: cameraProvider.controller!),

                  // Hand landmarks (Skeleton)
                  HandOverlayWidget(landmarks: cameraProvider.landmarks),

                  // Gesture detection status badge
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.8),
                        border: Border(
                          top: BorderSide(
                            color: _getGestureColor(
                              cameraProvider.detectedGesture,
                            ),
                            width: 2,
                          ),
                        ),
                      ),
                      child: Text(
                        cameraProvider.detectedGesture?.toUpperCase() ?? 
                            (cameraProvider.isStreaming ? 'READING...' : 'PAUSED'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _getGestureColor(
                            cameraProvider.detectedGesture,
                          ),
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),

                  // Tap to Toggle label
                  if (!cameraProvider.isStreaming)
                    const Center(
                      child: Icon(Icons.play_circle_fill, color: Colors.white70, size: 40),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getGestureColor(String? gesture) {
    if (gesture == null) return Colors.white;
    switch (gesture.toLowerCase()) {
      case 'open_palm':
        return Colors.lime;
      case 'fist':
        return Colors.red;
      case 'thumbs_up':
        return Colors.cyan;
      default:
        return Colors.white;
    }
  }
}
    

  Widget _buildCameraPreview(CameraProvider provider) {
    if (!provider.isInitialized || provider.controller == null) {
      return Container(
        color: Colors.black87,
        child: const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white30),
              strokeWidth: 1.5,
            ),
          ),
        ),
      );
    }

    if (provider.errorMessage != null) {
      return Container(
        color: Colors.black87,
        child: Center(
          child: Icon(
            Icons.error_outline,
            color: Colors.red.withOpacity(0.7),
            size: 20,
          ),
        ),
      );
    }

    return CameraPreviewWidget(controller: provider.controller!);
  }

  Color _getGestureColor(String? gesture) {
    switch (gesture) {
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
