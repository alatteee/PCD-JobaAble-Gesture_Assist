import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../models/gesture_log_model.dart';
import '../providers/gesture_history_provider.dart';

class GestureHistoryPage extends StatefulWidget {
  const GestureHistoryPage({super.key});

  @override
  State<GestureHistoryPage> createState() => _GestureHistoryPageState();
}

class _GestureHistoryPageState extends State<GestureHistoryPage> {
  late GestureHistoryProvider _provider;

  @override
  void initState() {
    super.initState();
    _provider = GestureHistoryProvider();
    _provider.init();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ChangeNotifierProvider.value(
      value: _provider,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: theme.appBarTheme.backgroundColor,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: theme.colorScheme.primary),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Gesture History',
            style: TextStyle(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          centerTitle: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () => _provider.addTestGesture('Swipe Left', 'Back'),
              tooltip: 'Add Test Log',
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _provider.clearAllLogs(),
              tooltip: 'Clear All',
            ),
          ],
        ),
        body: Consumer<GestureHistoryProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading) {
              return Center(
                  child: CircularProgressIndicator(
                      color: theme.colorScheme.primary));
            }

            if (provider.gestureLogs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.05),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.history_toggle_off_rounded,
                        size: 64,
                        color: theme.colorScheme.primary.withOpacity(0.4),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Belum ada riwayat gestur',
                      style: TextStyle(
                        color: theme.colorScheme.primary.withOpacity(0.8),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Gunakan fitur Gesture Assist untuk\nmelihat riwayat deteksi di sini.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: theme.textTheme.bodyMedium?.color
                            ?.withOpacity(0.5),
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              itemCount: provider.gestureLogs.length,
              itemBuilder: (context, index) {
                final log = provider.gestureLogs[index];
                return GestureLogCard(log: log);
              },
            );
          },
        ),
      ),
    );
  }
}

class GestureLogCard extends StatelessWidget {
  final GestureLogModel log;

  const GestureLogCard({super.key, required this.log});

  IconData _getGestureIcon(String gestureType) {
    switch (gestureType.toLowerCase()) {
      case 'swipe left':
        return Icons.swipe_left_alt;
      case 'open palm':
        return Icons.front_hand;
      case 'thumbs up':
        return Icons.thumb_up;
      default:
        return Icons.gesture;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formattedDate =
        DateFormat('d MMMM yyyy, HH:mm').format(log.timestamp);
    final confidenceValue = log.confidence;
    final confidencePercentage = (confidenceValue * 100).toStringAsFixed(0);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color:
            theme.brightness == Brightness.dark ? Colors.black : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: theme.brightness == Brightness.dark
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
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.primary,
                          theme.colorScheme.primary.withOpacity(0.8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.primary.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Icon(
                      _getGestureIcon(log.gestureType),
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              log.gestureType,
                              style: TextStyle(
                                color: theme.colorScheme.primary,
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color:
                                    theme.colorScheme.secondary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '$confidencePercentage%',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: theme.colorScheme.secondary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          formattedDate,
                          style: TextStyle(
                            color: theme.textTheme.bodyMedium?.color
                                ?.withOpacity(0.5),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _buildInfoChip(
                              context,
                              Icons.ads_click_rounded,
                              log.action,
                            ),
                            const SizedBox(width: 8),
                            _buildInfoChip(
                              context,
                              Icons.videocam_rounded,
                              'Video Source',
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

  Widget _buildInfoChip(BuildContext context, IconData icon, String label) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: theme.colorScheme.primary.withOpacity(0.6)),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: theme.colorScheme.primary.withOpacity(0.7),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
