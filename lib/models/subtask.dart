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

// ... остальной код ...


  Subtask({
    required this.name,
    this.completedSteps = 0,
    required this.totalSteps,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'completedSteps': completedSteps,
      'totalSteps': totalSteps,
    };
  }

  static Subtask fromFirestore(Map<String, dynamic> data) {
    return Subtask(
      name: data['name'] ?? '',
      completedSteps: data['completedSteps'] ?? 0,
      totalSteps: data['totalSteps'] ?? 1,
    );
  }
}
