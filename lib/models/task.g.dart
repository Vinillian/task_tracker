// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TaskAdapter extends TypeAdapter<Task> {
  @override
  final int typeId = 1;

  @override
  Task read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Task(
      id: fields[0] as String,
      parentId: fields[1] as String?,
      projectId: fields[2] as String,
      title: fields[3] as String,
      description: fields[4] as String,
      isCompleted: fields[5] as bool,
      type: fields[6] as TaskType,
      totalSteps: fields[7] as int,
      completedSteps: fields[8] as int,
      maxDepth: fields[9] as int,
      color: fields[10] as int?,
      priority: fields[11] as int?,
      estimatedMinutes: fields[12] as int?,
      dueDate: fields[13] as DateTime?,
      isRecurring: fields[14] as bool,
      lastCompletedDate: fields[15] as DateTime?,
      createdAt: fields[16] as DateTime?,
      updatedAt: fields[17] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, Task obj) {
    writer
      ..writeByte(18)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.parentId)
      ..writeByte(2)
      ..write(obj.projectId)
      ..writeByte(3)
      ..write(obj.title)
      ..writeByte(4)
      ..write(obj.description)
      ..writeByte(5)
      ..write(obj.isCompleted)
      ..writeByte(6)
      ..write(obj.type)
      ..writeByte(7)
      ..write(obj.totalSteps)
      ..writeByte(8)
      ..write(obj.completedSteps)
      ..writeByte(9)
      ..write(obj.maxDepth)
      ..writeByte(10)
      ..write(obj.color)
      ..writeByte(11)
      ..write(obj.priority)
      ..writeByte(12)
      ..write(obj.estimatedMinutes)
      ..writeByte(13)
      ..write(obj.dueDate)
      ..writeByte(14)
      ..write(obj.isRecurring)
      ..writeByte(15)
      ..write(obj.lastCompletedDate)
      ..writeByte(16)
      ..write(obj.createdAt)
      ..writeByte(17)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
