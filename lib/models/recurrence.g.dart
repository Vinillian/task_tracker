// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recurrence.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RecurrenceAdapter extends TypeAdapter<Recurrence> {
  @override
  final int typeId = 5;

  @override
  Recurrence read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Recurrence(
      type: fields[0] as RecurrenceType,
      interval: fields[1] as int,
      daysOfWeek: (fields[2] as List).cast<int>(),
    );
  }

  @override
  void write(BinaryWriter writer, Recurrence obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.type)
      ..writeByte(1)
      ..write(obj.interval)
      ..writeByte(2)
      ..write(obj.daysOfWeek);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecurrenceAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
