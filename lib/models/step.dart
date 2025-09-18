import 'package:hive/hive.dart';
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

  Step({
    required this.name,
    this.completedSteps = 0,
    required this.totalSteps,
    this.stepType = 'stepByStep',
    this.isCompleted = false,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'completedSteps': completedSteps,
      'totalSteps': totalSteps,
      'stepType': stepType,
      'isCompleted': isCompleted,
    };
  }

  static Step fromFirestore(Map<String, dynamic> data) {
    return Step(
      name: data['name'] ?? '',
      completedSteps: data['completedSteps'] ?? 0,
      totalSteps: data['totalSteps'] ?? 1,
      stepType: data['stepType'] ?? 'stepByStep',
      isCompleted: data['isCompleted'] ?? false,
    );
  }
}