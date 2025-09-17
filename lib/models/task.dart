import 'subtask.dart';
import 'package:hive/hive.dart';
import 'task_type.dart';
import 'recurrence.dart';

part 'task.g.dart';

@HiveType(typeId: 2)
class Task {
  @HiveField(0)
  final String name;

  @HiveField(1)
  final int completedSteps;

  @HiveField(2)
  final int totalSteps;

  @HiveField(3)
  final List<Subtask> subtasks;

  @HiveField(4)
  final String taskType; // Используйте String вместо TaskType

  @HiveField(5)
  final Recurrence? recurrence;

  @HiveField(6)
  final DateTime? dueDate;

  @HiveField(7)
  final bool isCompleted;

  @HiveField(8)
  final String? description;

  // В конструкторе:
  Task({
    required this.name,
    this.completedSteps = 0,
    required this.totalSteps,
    List<Subtask>? subtasks,
    this.taskType = 'stepByStep', // Используйте строки
    this.recurrence,
    this.dueDate,
    this.isCompleted = false,
    this.description,
  }) : subtasks = subtasks ?? [];

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'completedSteps': completedSteps,
      'totalSteps': totalSteps,
      'subtasks': subtasks.map((s) => s.toFirestore()).toList(),
      'taskType': taskType.toString(), // ← Используйте toString()
      'recurrence': recurrence?.toMap(),
      'dueDate': dueDate?.toIso8601String(),
      'isCompleted': isCompleted,
      'description': description,
    };
  }

  // В fromFirestore просто возвращаем строку
  static Task fromFirestore(Map<String, dynamic> data) {
    return Task(
      name: data['name'] ?? '',
      completedSteps: data['completedSteps'] ?? 0,
      totalSteps: data['totalSteps'] ?? 1,
      subtasks: (data['subtasks'] as List<dynamic>?)
          ?.map((s) => Subtask.fromFirestore(s))
          .toList() ?? [],
      taskType: data['taskType'] ?? 'stepByStep', // ← Просто возвращаем строку
      recurrence: data['recurrence'] != null
          ? Recurrence.fromMap(data['recurrence'])
          : null,
      dueDate: data['dueDate'] != null
          ? DateTime.parse(data['dueDate'])
          : null,
      isCompleted: data['isCompleted'] ?? false,
      description: data['description'],
    );
  }
}