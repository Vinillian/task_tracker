import 'package:hive/hive.dart';
import 'step.dart';
import 'recurrence.dart';
part 'stage.g.dart';



@HiveType(typeId: 6) // Новый typeId
class Stage {
  @HiveField(0)
  final String name;

  @HiveField(1)
  final int completedSteps;

  @HiveField(2)
  final int totalSteps;

  @HiveField(3)
  final String stageType; // 'stepByStep' или 'singleStep'

  @HiveField(4)
  final bool isCompleted;

  @HiveField(5)
  final List<Step> steps;

  @HiveField(6) // Следующий доступный номер
  final DateTime? plannedDate;

  @HiveField(7) // Следующий доступный номер
  final Recurrence? recurrence;

  Stage({
    required this.name,
    this.completedSteps = 0,
    required this.totalSteps,
    this.stageType = 'stepByStep',
    this.isCompleted = false,
    List<Step>? steps,
    this.plannedDate, // Добавлено
    this.recurrence, // Добавлено
  }) : steps = steps ?? [];

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'completedSteps': completedSteps,
      'totalSteps': totalSteps,
      'stageType': stageType,
      'isCompleted': isCompleted,
      'steps': steps.map((s) => s.toFirestore()).toList(),
      'plannedDate': plannedDate?.toIso8601String(), // Добавлено
    };
  }

  static Stage fromFirestore(Map<String, dynamic> data) {
    return Stage(
      name: data['name'] ?? '',
      completedSteps: data['completedSteps'] ?? 0,
      totalSteps: data['totalSteps'] ?? 1,
      stageType: data['stageType'] ?? 'stepByStep',
      isCompleted: data['isCompleted'] ?? false,
      steps: (data['steps'] as List<dynamic>?)
          ?.map((s) => Step.fromFirestore(s))
          .toList() ?? [],
      plannedDate: data['plannedDate'] != null // Добавлено
          ? DateTime.parse(data['plannedDate'])
          : null,
    );
  }
}