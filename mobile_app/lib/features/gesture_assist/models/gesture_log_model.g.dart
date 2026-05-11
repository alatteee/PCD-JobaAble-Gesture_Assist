// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gesture_log_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class GestureLogModelAdapter extends TypeAdapter<GestureLogModel> {
  @override
  final int typeId = 1;

  @override
  GestureLogModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return GestureLogModel(
      id: fields[0] as String,
      userId: fields[1] as String,
      gestureType: fields[2] as String,
      action: fields[3] as String,
      confidence: fields[4] as double,
      screenContext: fields[5] as String,
      timestamp: fields[6] as DateTime,
      syncStatus: fields[7] as String,
    );
  }

  @override
  void write(BinaryWriter writer, GestureLogModel obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.gestureType)
      ..writeByte(3)
      ..write(obj.action)
      ..writeByte(4)
      ..write(obj.confidence)
      ..writeByte(5)
      ..write(obj.screenContext)
      ..writeByte(6)
      ..write(obj.timestamp)
      ..writeByte(7)
      ..write(obj.syncStatus);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GestureLogModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
