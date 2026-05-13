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
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      provider.errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white),
                    ),
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

              // 2. Hand Landmark Overlay
              HandOverlayWidget(
                landmarks: provider.landmarks,
                gestureLabel: provider.detectedGesture,
              ),

              // 3. Debug gesture selector
              Positioned(
                top: 110,
                left: 16,
                right: 16,
                child: _DebugGestureSelector(provider: provider),
              ),

              // 4. UI Overlay
              Positioned(
                bottom: 40,
                left: 0,
                right: 0,
                child: Column(
                  children: [
                    if (provider.isStreaming)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: ElevatedButton.icon(
                          onPressed: () => provider.clearDummyHand(),
                          icon: const Icon(Icons.cleaning_services),
                          label: const Text("Clear Test"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
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
                    FloatingActionButton(
                      backgroundColor: provider.isStreaming
                          ? Colors.red
                          : AppColors.primaryNavy,
                      onPressed: () => provider.toggleStream(),
                      child: Icon(
                        provider.isStreaming ? Icons.stop : Icons.play_arrow,
                        color: Colors.white,
                      ),
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

class _DebugGestureSelector extends StatelessWidget {
  final CameraProvider provider;

  const _DebugGestureSelector({
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.45),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children: [
          _GestureButton(
            label: 'Open Palm',
            value: 'open_palm',
            selectedValue: provider.debugGestureType,
            onSelected: provider.setDebugGestureType,
          ),
          _GestureButton(
            label: 'Fist',
            value: 'fist',
            selectedValue: provider.debugGestureType,
            onSelected: provider.setDebugGestureType,
          ),
          _GestureButton(
            label: 'Thumbs Up',
            value: 'thumbs_up',
            selectedValue: provider.debugGestureType,
            onSelected: provider.setDebugGestureType,
          ),
        ],
      ),
    );
  }
}

class _GestureButton extends StatelessWidget {
  final String label;
  final String value;
  final String selectedValue;
  final ValueChanged<String> onSelected;

  const _GestureButton({
    required this.label,
    required this.value,
    required this.selectedValue,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final bool isSelected = value == selectedValue;

    return ElevatedButton(
      onPressed: () => onSelected(value),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.green : Colors.white,
        foregroundColor: isSelected ? Colors.white : Colors.black87,
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 10,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}