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
                child: Text(
                  'No Gesture History Found',
                  style: TextStyle(
                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
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
    final confidencePercentage = (log.confidence * 100).toStringAsFixed(0);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color:
            theme.brightness == Brightness.dark ? Colors.black : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.dividerColor),
        boxShadow: theme.brightness == Brightness.dark
            ? []
            : [
                const BoxShadow(
                  color: Colors.black12,
                  blurRadius: 6,
                  offset: Offset(0, 3),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getGestureIcon(log.gestureType),
                    color: theme.colorScheme.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        log.gestureType,
                        style: TextStyle(
                          color: theme.textTheme.titleLarge?.color,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        formattedDate,
                        style: TextStyle(
                          color: theme.textTheme.bodyMedium?.color
                              ?.withOpacity(0.7),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(Icons.camera_alt_outlined,
                              size: 14,
                              color: theme.colorScheme.primary.withOpacity(0.8)),
                          const SizedBox(width: 4),
                          Text(
                            'Camera Context',
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.primary.withOpacity(0.8),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            'Confidence: $confidencePercentage%',
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.secondary,
                              fontWeight: FontWeight.bold,
                            ),
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
    );
  }
}
