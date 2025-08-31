import 'subtask.dart';

class Task {
  String name;
  int totalSteps;
  int completedSteps;
  List<Subtask> subtasks;

  Task({
    required this.name,
    required this.totalSteps,
    required this.completedSteps,
    required this.subtasks,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'totalSteps': totalSteps,
    'completedSteps': completedSteps,
    'subtasks': subtasks.map((s) => s.toJson()).toList(),
  };

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      name: json['name'],
      totalSteps: json['totalSteps'],
      completedSteps: json['completedSteps'],
      subtasks: (json['subtasks'] as List)
          .map((s) => Subtask.fromJson(s))
          .toList(),
    );
  }
}