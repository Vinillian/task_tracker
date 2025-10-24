// models/task_type.dart
import 'package:hive/hive.dart';

part 'task_type.g.dart'; // ✅ ДОБАВИТЬ эту строку

@HiveType(typeId: 2)
enum TaskType {
  @HiveField(0)
  single,

  @HiveField(1)
  stepByStep
}