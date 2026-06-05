import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../profile/accessibility_settings_view.dart';
import '../models/gesture_log_model.dart';
import '../services/gesture_log_local_service.dart';

class GestureHistoryPage extends StatefulWidget {
  const GestureHistoryPage({super.key});

  @override
  State<GestureHistoryPage> createState() => _GestureHistoryPageState();
}

class _GestureHistoryPageState extends State<GestureHistoryPage> {
  final GestureLogLocalService _logService = GestureLogLocalService();

  bool _isLoading = true;
  List<GestureLogModel> _gestureLogs = [];

  @override
  void initState() {
    super.initState();
    _loadGestureLogs();
  }

  Future<void> _loadGestureLogs() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final logs = await _logService.getGestureLogs();

      if (!mounted) return;

      setState(() {
        _gestureLogs = logs;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('[GestureHistory] Failed to load logs: $e');

      if (!mounted) return;

      setState(() {
        _gestureLogs = [];
        _isLoading = false;
      });
    }
  }

  Future<void> _clearAllLogs() async {
    final shouldClear = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Hapus Riwayat Gestur?'),
          content: const Text(
            'Semua riwayat gesture yang tersimpan lokal akan dihapus.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );

    if (shouldClear != true) return;

    await _logService.clearGestureLogs();

    if (!mounted) return;

    await _loadGestureLogs();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Riwayat gesture berhasil dihapus'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AccessibilityController.highContrastNotifier,
      builder: (context, isHighContrast, child) {
        final theme = Theme.of(context);

        final backgroundColor =
            isHighContrast ? const Color(0xFF050505) : theme.scaffoldBackgroundColor;
        final primaryColor =
            isHighContrast ? const Color(0xFFFFEA00) : theme.colorScheme.primary;
        final textColor =
            isHighContrast ? const Color(0xFFFFEA00) : theme.textTheme.bodyLarge?.color;
        final secondaryTextColor = isHighContrast
            ? const Color(0xFFFFEA00).withOpacity(0.75)
            : theme.textTheme.bodyMedium?.color?.withOpacity(0.6);

        return Scaffold(
          backgroundColor: backgroundColor,
          appBar: AppBar(
            backgroundColor: backgroundColor,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: primaryColor),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'Gesture History',
              style: TextStyle(
                color: primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            centerTitle: false,
            actions: [
              IconButton(
                icon: Icon(Icons.refresh_rounded, color: primaryColor),
                onPressed: _loadGestureLogs,
                tooltip: 'Refresh',
              ),
              IconButton(
                icon: Icon(Icons.delete_outline, color: primaryColor),
                onPressed: _gestureLogs.isEmpty ? null : _clearAllLogs,
                tooltip: 'Clear All',
              ),
            ],
          ),
          body: _buildBody(
            context: context,
            isHighContrast: isHighContrast,
            primaryColor: primaryColor,
            textColor: textColor ?? primaryColor,
            secondaryTextColor: secondaryTextColor ?? primaryColor,
          ),
        );
      },
    );
  }

  Widget _buildBody({
    required BuildContext context,
    required bool isHighContrast,
    required Color primaryColor,
    required Color textColor,
    required Color secondaryTextColor,
  }) {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(color: primaryColor),
      );
    }

    if (_gestureLogs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(isHighContrast ? 0.12 : 0.05),
                  shape: BoxShape.circle,
                  border: isHighContrast
                      ? Border.all(color: primaryColor, width: 1.5)
                      : null,
                ),
                child: Icon(
                  Icons.history_toggle_off_rounded,
                  size: 64,
                  color: primaryColor.withOpacity(isHighContrast ? 1 : 0.4),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Belum ada riwayat gestur',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Gunakan Gesture Navigation untuk melihat riwayat aksi yang berhasil di sini.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: secondaryTextColor,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadGestureLogs,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        itemCount: _gestureLogs.length,
        itemBuilder: (context, index) {
          final log = _gestureLogs[index];

          return GestureLogCard(
            log: log,
            isHighContrast: isHighContrast,
          );
        },
      ),
    );
  }
}

class GestureLogCard extends StatelessWidget {
  final GestureLogModel log;
  final bool isHighContrast;

  const GestureLogCard({
    super.key,
    required this.log,
    required this.isHighContrast,
  });

  IconData _getGestureIcon(String gestureType) {
    switch (gestureType.toLowerCase()) {
      case 'open_palm':
      case 'open palm':
        return Icons.front_hand_rounded;
      case 'thumbs_up':
      case 'thumbs up':
        return Icons.thumb_up_rounded;
      case 'fist':
        return Icons.back_hand_rounded;
      default:
        return Icons.gesture_rounded;
    }
  }

  String _getGestureLabel(String gestureType) {
    switch (gestureType.toLowerCase()) {
      case 'open_palm':
      case 'open palm':
        return 'Open Palm';
      case 'thumbs_up':
      case 'thumbs up':
        return 'Thumbs Up';
      case 'fist':
        return 'Fist';
      default:
        return gestureType.isNotEmpty ? gestureType : 'Unknown Gesture';
    }
  }

  String _getActionLabel(String action) {
    switch (action.toLowerCase()) {
      case 'next':
        return 'Pindah fokus';
      case 'confirm':
        return 'Konfirmasi';
      case 'back':
        return 'Kembali';
      default:
        return action.isNotEmpty ? action : 'Unknown Action';
    }
  }

  String _getScreenLabel(String screenContext) {
    switch (screenContext.toLowerCase()) {
      case 'home':
        return 'Home';
      case 'job_detail':
        return 'Job Detail';
      case 'apply_job':
        return 'Apply Job';
      default:
        return screenContext.isNotEmpty ? screenContext : 'Unknown Screen';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final formattedDate =
        DateFormat('d MMM yyyy, HH:mm').format(log.timestamp);
    final confidencePercentage = (log.confidence * 100).toStringAsFixed(0);

    final backgroundColor =
        isHighContrast ? const Color(0xFF050505) : Colors.white;
    final primaryColor =
        isHighContrast ? const Color(0xFFFFEA00) : theme.colorScheme.primary;
    final textColor =
        isHighContrast ? const Color(0xFFFFEA00) : theme.textTheme.bodyLarge?.color;
    final secondaryTextColor = isHighContrast
        ? const Color(0xFFFFEA00).withOpacity(0.75)
        : theme.textTheme.bodyMedium?.color?.withOpacity(0.55);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isHighContrast
              ? primaryColor
              : theme.colorScheme.primary.withOpacity(0.08),
          width: isHighContrast ? 1.5 : 1,
        ),
        boxShadow: isHighContrast
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {},
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: isHighContrast ? primaryColor : null,
                      gradient: isHighContrast
                          ? null
                          : LinearGradient(
                              colors: [
                                theme.colorScheme.primary,
                                theme.colorScheme.primary.withOpacity(0.8),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: isHighContrast
                          ? []
                          : [
                              BoxShadow(
                                color:
                                    theme.colorScheme.primary.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                    ),
                    child: Icon(
                      _getGestureIcon(log.gestureType),
                      color: isHighContrast ? const Color(0xFF050505) : Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              _getGestureLabel(log.gestureType),
                              style: TextStyle(
                                color: primaryColor,
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: primaryColor.withOpacity(
                                  isHighContrast ? 0.14 : 0.08,
                                ),
                                borderRadius: BorderRadius.circular(8),
                                border: isHighContrast
                                    ? Border.all(color: primaryColor)
                                    : null,
                              ),
                              child: Text(
                                '$confidencePercentage%',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          formattedDate,
                          style: TextStyle(
                            color: secondaryTextColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _buildInfoChip(
                              context,
                              icon: Icons.ads_click_rounded,
                              label: _getActionLabel(log.action),
                              isHighContrast: isHighContrast,
                            ),
                            _buildInfoChip(
                              context,
                              icon: Icons.phone_android_rounded,
                              label: _getScreenLabel(log.screenContext),
                              isHighContrast: isHighContrast,
                            ),
                            _buildInfoChip(
                              context,
                              icon: Icons.storage_rounded,
                              label: 'Local',
                              isHighContrast: isHighContrast,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool isHighContrast,
  }) {
    final theme = Theme.of(context);
    final primaryColor =
        isHighContrast ? const Color(0xFFFFEA00) : theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(isHighContrast ? 0.12 : 0.05),
        borderRadius: BorderRadius.circular(6),
        border: isHighContrast ? Border.all(color: primaryColor) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: primaryColor.withOpacity(isHighContrast ? 1 : 0.65),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: primaryColor.withOpacity(isHighContrast ? 1 : 0.75),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}