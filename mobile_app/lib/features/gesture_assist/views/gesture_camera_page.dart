import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../providers/camera_provider.dart';
import '../widgets/camera_preview_widget.dart';
import '../widgets/hand_overlay_widget.dart';

class GestureCameraPage extends StatefulWidget {
  const GestureCameraPage({super.key});

  @override
  State<GestureCameraPage> createState() => _GestureCameraPageState();
}

class _GestureCameraPageState extends State<GestureCameraPage> {
  @override
  void initState() {
    super.initState();
    // Initialize camera on start
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CameraProvider>().initializeCamera();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Gesture Detection'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Consumer<CameraProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }

          if (provider.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 60),
                  const SizedBox(height: 16),
                  Text(
                    provider.errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.initializeCamera(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (!provider.isInitialized || provider.controller == null) {
            return const Center(
              child: Text(
                'Initializing Camera...',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          return Stack(
            fit: StackFit.expand,
            children: [
              // 1. Camera Preview
              CameraPreviewWidget(controller: provider.controller!),

              // 2. Hand Landmark Overlay (New)
              HandOverlayWidget(
                landmarks: provider.landmarks,
                gestureLabel: provider.detectedGesture,
              ),

              // 3. UI Overlay (Placeholders)
              Positioned(
                bottom: 40,
                left: 0,
                right: 0,
                child: Column(
                  children: [
                    if (provider.isStreaming)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () => provider.landmarks.isEmpty
                                  ? provider.showDummyHand()
                                  : provider.clearDummyHand(),
                              icon: const Icon(Icons.bug_report),
                              label: Text(provider.landmarks.isEmpty
                                  ? "Test Overlay"
                                  : "Clear Test"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        provider.isStreaming
                            ? "Streaming Image Activity..."
                            : "Camera Ready",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FloatingActionButton(
                          backgroundColor: provider.isStreaming
                              ? Colors.red
                              : AppColors.primaryNavy,
                          onPressed: () {
                            provider.toggleStream((image) {
                              // Forward to ML Service in the future
                              debugPrint("Received frame: ${image.width}x${image.height}");
                            });
                          },
                          child: Icon(
                            provider.isStreaming ? Icons.stop : Icons.play_arrow,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
