// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'progress_history.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ProgressHistoryAdapter extends TypeAdapter<ProgressHistory> {
  @override
  final int typeId = 4;

  @override
  ProgressHistory read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ProgressHistory(
      date: fields[0] as DateTime,
      itemName: fields[1] as String,
      stepsAdded: fields[2] as int,
      itemType: fields[3] as String,
    );
  }

  @override
  void write(BinaryWriter writer, ProgressHistory obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.date)
      ..writeByte(1)
      ..write(obj.itemName)
      ..writeByte(2)
      ..write(obj.stepsAdded)
      ..writeByte(3)
      ..write(obj.itemType);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProgressHistoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
