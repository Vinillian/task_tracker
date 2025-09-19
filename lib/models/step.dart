import 'package:hive/hive.dart';
import 'recurrence.dart';
part 'step.g.dart';


@HiveType(typeId: 3)
class Step {
  @HiveField(0)
  final String name;

  @HiveField(1)
  final int completedSteps;

  @HiveField(2)
  final int totalSteps;

  @HiveField(3)
  final String stepType; // 'stepByStep' или 'singleStep'

  @HiveField(4)
  final bool isCompleted;

  @HiveField(5) // Следующий доступный номер
  final DateTime? plannedDate;

  @HiveField(6) // Следующий доступный номер
  final Recurrence? recurrence;

  Step({
    required this.name,
    this.completedSteps = 0,
    required this.totalSteps,
    this.stepType = 'stepByStep',
    this.isCompleted = false,
    this.plannedDate, // Добавлено
    this.recurrence, // Добавлено
  });

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'completedSteps': completedSteps,
      'totalSteps': totalSteps,
      'stepType': stepType,
      'isCompleted': isCompleted,
      'plannedDate': plannedDate?.toIso8601String(), // Добавлено
    };
  }

  static Step fromFirestore(Map<String, dynamic> data) {
    return Step(
      name: data['name'] ?? '',
      completedSteps: data['completedSteps'] ?? 0,
      totalSteps: data['totalSteps'] ?? 1,
      stepType: data['stepType'] ?? 'stepByStep',
      isCompleted: data['isCompleted'] ?? false,
      plannedDate: data['plannedDate'] != null // Добавлено
          ? DateTime.parse(data['plannedDate'])
          : null,
    );
  }
}