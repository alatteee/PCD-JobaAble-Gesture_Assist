import 'package:hive/hive.dart';

part 'gesture_log_model.g.dart';

@HiveType(typeId: 1)
class GestureLogModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String userId;

  @HiveField(2)
  final String gestureType;

  @HiveField(3)
  final String action;

  @HiveField(4)
  final double confidence;

  @HiveField(5)
  final String screenContext;

  @HiveField(6)
  final DateTime timestamp;

  /// Status penyimpanan log.
  ///
  /// Saat ini Gesture History hanya disimpan secara lokal di Hive,
  /// jadi nilai default-nya adalah 'local'.
  ///
  /// Field ini tetap dipertahankan agar kompatibel dengan Hive Adapter
  /// yang sudah pernah dibuat.
  @HiveField(7)
  final String syncStatus;

  GestureLogModel({
    required this.id,
    required this.userId,
    required this.gestureType,
    required this.action,
    required this.confidence,
    required this.screenContext,
    required this.timestamp,
    this.syncStatus = 'local',
  });

  Map<String, dynamic> toMap() {
    return {
      '_id': id,
      'userId': userId,
      'gestureType': gestureType,
      'action': action,
      'confidence': confidence,
      'screenContext': screenContext,
      'timestamp': timestamp.toIso8601String(),
      'syncStatus': syncStatus,
    };
  }

  factory GestureLogModel.fromMap(Map<String, dynamic> map) {
    return GestureLogModel(
      id: map['_id'] ?? '',
      userId: map['userId'] ?? '',
      gestureType: map['gestureType'] ?? '',
      action: map['action'] ?? '',
      confidence: (map['confidence'] as num?)?.toDouble() ?? 0.0,
      screenContext: map['screenContext'] ?? '',
      timestamp: map['timestamp'] != null
          ? DateTime.parse(map['timestamp'])
          : DateTime.now(),
      syncStatus: map['syncStatus'] ?? 'local',
    );
  }

  GestureLogModel copyWith({
    String? id,
    String? userId,
    String? gestureType,
    String? action,
    double? confidence,
    String? screenContext,
    DateTime? timestamp,
    String? syncStatus,
  }) {
    return GestureLogModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      gestureType: gestureType ?? this.gestureType,
      action: action ?? this.action,
      confidence: confidence ?? this.confidence,
      screenContext: screenContext ?? this.screenContext,
      timestamp: timestamp ?? this.timestamp,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }
}