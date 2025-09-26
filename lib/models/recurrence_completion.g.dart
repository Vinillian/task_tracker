// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recurrence_completion.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RecurrenceCompletionAdapter extends TypeAdapter<RecurrenceCompletion> {
  @override
  final int typeId = 9;

  @override
  RecurrenceCompletion read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RecurrenceCompletion(
      taskId: fields[0] as String,
      occurrenceDate: fields[1] as DateTime,
      completedAt: fields[2] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, RecurrenceCompletion obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.taskId)
      ..writeByte(1)
      ..write(obj.occurrenceDate)
      ..writeByte(2)
      ..write(obj.completedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecurrenceCompletionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
