import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../providers/camera_provider.dart';
import '../widgets/camera_preview_widget.dart';
import '../widgets/hand_overlay_widget.dart';
import '../controllers/gesture_action_controller.dart';
import '../controllers/gesture_navigation_controller.dart';

class GestureCameraPage extends StatefulWidget {
  const GestureCameraPage({super.key});

  @override
  State<GestureCameraPage> createState() => _GestureCameraPageState();
}

class _GestureCameraPageState extends State<GestureCameraPage> {
  late GestureActionController _actionController;
  late GestureNavigationController _navigationController;

  @override
  void initState() {
    super.initState();
    _actionController = GestureActionController(context);
    _navigationController = GestureNavigationController();

    // Register callback untuk show feedback ketika action selesai
    _navigationController.onActionResult((result) {
      if (!mounted) return;

      // Show SnackBar feedback
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.message ?? 'Action',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: result.isSuccess ? Colors.green : Colors.red,
          duration: const Duration(milliseconds: 1500),
        ),
      );
    });

    // ============================================================
    // REGISTER GESTURE ACTION CALLBACKS
    // ============================================================

    // CONFIRM ACTION (Thumbs Up)
    _navigationController.registerConfirmAction(() async {
      debugPrint('✅ [GestureCamera] CONFIRM action triggered (Thumbs Up)');
      // TODO: Implement confirm action untuk page ini
      // Misalnya: submit form, apply untuk job, dll
      // For now, just return true (success)
      return true;
    });

    // NEXT ACTION (Open Palm)
    _navigationController.registerNextAction(() async {
      debugPrint('👉 [GestureCamera] NEXT action triggered (Open Palm)');
      // TODO: Implement next action untuk page ini
      // Misalnya: scroll ke bawah, navigate ke job berikutnya, dll
      // For now, just return true (success)
      return true;
    });

    // BACK ACTION (Fist)
    _navigationController.registerBackAction(() async {
      debugPrint('👈 [GestureCamera] BACK action triggered (Fist)');
      // Try to pop navigator, if possible
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
        return true;
      }
      // If can't pop, stay on this page
      return false;
    });

    // Initialize camera on start
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<CameraProvider>();
      provider.initializeCamera();
      
      // Wire BOTH controllers to provider
      // GestureNavigationController will be used (newer, dengan cooldown notif)
      // GestureActionController sebagai fallback
      provider.setActionController(_actionController);
      provider.setGestureNavigationController(_navigationController);
    });
  }

  @override
  void dispose() {
    _navigationController.dispose();
    super.dispose();
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
                gestureLabel: '',
              ),

              // 3. Real Gesture Status Overlay
              Positioned(
                top: 105,
                left: 16,
                right: 16,
                child: _GestureStatusCard(provider: provider),
              ),

              // 4. Bottom Control Overlay
              Positioned(
                bottom: 40,
                left: 0,
                right: 0,
                child: Column(
                  children: [
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

class _GestureStatusCard extends StatelessWidget {
  final CameraProvider provider;

  const _GestureStatusCard({
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
  final String gesture = provider.detectedGesture ?? 'none';
  final action = _mapActionLabel(gesture);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.45),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white.withOpacity(0.18),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Real Gesture Detection',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _formatGestureLabel(gesture),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _gestureColor(gesture),
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Action: $action',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _formatGestureLabel(String gesture) {
    switch (gesture) {
      case 'open_palm':
        return 'Open Palm';
      case 'fist':
        return 'Fist';
      case 'thumbs_up':
        return 'Thumbs Up';
      case 'unknown':
        return 'Unknown Gesture';
      case 'no_hand':
        return 'No Hand Detected';
      case 'none':
        return 'No Gesture';
      default:
        if (gesture.isEmpty) return 'No Gesture';
        return gesture
            .replaceAll('_', ' ')
            .split(' ')
            .map((word) {
              if (word.isEmpty) return word;
              return word[0].toUpperCase() + word.substring(1);
            })
            .join(' ');
    }
  }

  String _mapActionLabel(String gesture) {
    switch (gesture) {
      case 'open_palm':
        return 'next';
      case 'fist':
        return 'back';
      case 'thumbs_up':
        return 'confirm';
      case 'unknown':
        return 'no_action';
      case 'no_hand':
        return 'waiting';
      case 'none':
        return 'none';
      default:
        return 'waiting';
    }
  }

  Color _gestureColor(String gesture) {
    switch (gesture) {
      case 'open_palm':
        return Colors.greenAccent;
      case 'fist':
        return Colors.orangeAccent;
      case 'thumbs_up':
        return Colors.lightBlueAccent;
      case 'unknown':
        return Colors.yellowAccent;
      case 'no_hand':
        return Colors.white70;
      default:
        return Colors.white;
    }
  }
}