import 'stage.dart';
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
  final List<Stage> stages; // ← ИЗМЕНИЛИ с subtasks на stages

  @HiveField(4)
  final String taskType;

  @HiveField(5)
  final Recurrence? recurrence;

  @HiveField(6)
  final DateTime? dueDate;

  @HiveField(7)
  final bool isCompleted;

  @HiveField(8)
  final String? description;

  Task({
    required this.name,
    this.completedSteps = 0,
    required this.totalSteps,
    List<Stage>? stages, // ← ИЗМЕНИЛИ
    this.taskType = 'stepByStep',
    this.recurrence,
    this.dueDate,
    this.isCompleted = false,
    this.description,
  }) : stages = stages ?? [];

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'completedSteps': completedSteps,
      'totalSteps': totalSteps,
      'stages': stages.map((s) => s.toFirestore()).toList(), // ← ИЗМЕНИЛИ
      'taskType': taskType.toString(),
      'recurrence': recurrence?.toMap(),
      'dueDate': dueDate?.toIso8601String(),
      'isCompleted': isCompleted,
      'description': description,
    };
  }

  static Task fromFirestore(Map<String, dynamic> data) {
    return Task(
      name: data['name'] ?? '',
      completedSteps: data['completedSteps'] ?? 0,
      totalSteps: data['totalSteps'] ?? 1,
      stages: (data['stages'] as List<dynamic>?) // ← ИЗМЕНИЛИ
          ?.map((s) => Stage.fromFirestore(s))
          .toList() ?? [],
      taskType: data['taskType'] ?? 'stepByStep',
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