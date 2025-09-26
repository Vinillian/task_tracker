// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stage.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class StageAdapter extends TypeAdapter<Stage> {
  @override
  final int typeId = 6;

  @override
  Stage read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Stage(
      name: fields[0] as String,
      completedSteps: fields[1] as int,
      totalSteps: fields[2] as int,
      stageType: fields[3] as String,
      isCompleted: fields[4] as bool,
      steps: (fields[5] as List?)?.cast<Step>(),
      plannedDate: fields[8] as DateTime?,
      recurrence: fields[7] as Recurrence?,
    );
  }

  @override
  void write(BinaryWriter writer, Stage obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.completedSteps)
      ..writeByte(2)
      ..write(obj.totalSteps)
      ..writeByte(3)
      ..write(obj.stageType)
      ..writeByte(4)
      ..write(obj.isCompleted)
      ..writeByte(5)
      ..write(obj.steps)
      ..writeByte(8)
      ..write(obj.plannedDate)
      ..writeByte(7)
      ..write(obj.recurrence);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StageAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
