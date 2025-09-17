// models/subtask.dart
import 'package:hive/hive.dart';
part 'subtask.g.dart';

@HiveType(typeId: 3)
class Subtask {
  @HiveField(0)
  final String name;

  @HiveField(1)
  final int completedSteps;

  @HiveField(2)
  final int totalSteps;

  @HiveField(3)
  final String subtaskType; // 'stepByStep' или 'singleStep'

  @HiveField(4)
  final bool isCompleted;

  Subtask({
    required this.name,
    this.completedSteps = 0,
    required this.totalSteps,
    this.subtaskType = 'stepByStep',
    this.isCompleted = false,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'name': name, // ← УБРАТЬ лишнюю букву "С"
      'completedSteps': completedSteps,
      'totalSteps': totalSteps,
      'subtaskType': subtaskType,
      'isCompleted': isCompleted,
    };
  }

  static Subtask fromFirestore(Map<String, dynamic> data) {
    return Subtask(
      name: data['name'] ?? '',
      completedSteps: data['completedSteps'] ?? 0,
      totalSteps: data['totalSteps'] ?? 1,
      subtaskType: data['subtaskType'] ?? 'stepByStep',
      isCompleted: data['isCompleted'] ?? false,
    );
  }
}