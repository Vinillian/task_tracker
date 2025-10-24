// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task_type.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TaskTypeAdapter extends TypeAdapter<TaskType> {
  @override
  final int typeId = 2;

  @override
  TaskType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return TaskType.single;
      case 1:
        return TaskType.stepByStep;
      default:
        return TaskType.single;
    }
  }

  @override
  void write(BinaryWriter writer, TaskType obj) {
    switch (obj) {
      case TaskType.single:
        writer.writeByte(0);
        break;
      case TaskType.stepByStep:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
