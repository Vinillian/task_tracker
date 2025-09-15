import 'subtask.dart';
import 'package:hive/hive.dart';
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

// ... остальной код ...


  Task({
    required this.name,
    this.completedSteps = 0,
    required this.totalSteps,
    List<Subtask>? subtasks,
  }) : subtasks = subtasks ?? [];

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'completedSteps': completedSteps,
      'totalSteps': totalSteps,
      'subtasks': subtasks.map((s) => s.toFirestore()).toList(),
    };
  }

  static Task fromFirestore(Map<String, dynamic> data) {
    return Task(
      name: data['name'] ?? '',
      completedSteps: data['completedSteps'] ?? 0,
      totalSteps: data['totalSteps'] ?? 1,
      subtasks: (data['subtasks'] as List<dynamic>?)
          ?.map((s) => Subtask.fromFirestore(s))
          .toList() ??
          [],
    );
  }
}
