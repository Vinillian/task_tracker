// lib/models/task.dart
import 'package:hive/hive.dart';
import 'task_type.dart';

part 'task.g.dart';

@HiveType(typeId: 1)
class Task {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String? parentId;

  @HiveField(2)
  final String projectId;

  @HiveField(3)
  final String title;

  @HiveField(4)
  final String description;

  @HiveField(5)
  bool isCompleted;

  @HiveField(6)
  final TaskType type;

  @HiveField(7)
  final int totalSteps;

  @HiveField(8)
  int completedSteps;

  @HiveField(9)
  final int maxDepth;

  Task({
    required this.id,
    this.parentId,
    required this.projectId,
    required this.title,
    required this.description,
    this.isCompleted = false,
    this.type = TaskType.single,
    this.totalSteps = 1,
    this.completedSteps = 0,
    this.maxDepth = 5,
  });

  double get progress {
    if (type == TaskType.stepByStep) {
      return totalSteps > 0 ? completedSteps / totalSteps : 0.0;
    }
    return isCompleted ? 1.0 : 0.0;
  }

  Task copyWith({
    String? id,
    String? parentId,
    String? projectId,
    String? title,
    String? description,
    bool? isCompleted,
    TaskType? type,
    int? totalSteps,
    int? completedSteps,
    int? maxDepth,
  }) {
    return Task(
      id: id ?? this.id,
      parentId: parentId ?? this.parentId,
      projectId: projectId ?? this.projectId,
      title: title ?? this.title,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      type: type ?? this.type,
      totalSteps: totalSteps ?? this.totalSteps,
      completedSteps: completedSteps ?? this.completedSteps,
      maxDepth: maxDepth ?? this.maxDepth,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'parentId': parentId,
      'projectId': projectId,
      'title': title,
      'description': description,
      'isCompleted': isCompleted,
      'type': type.index,
      'totalSteps': totalSteps,
      'completedSteps': completedSteps,
      'maxDepth': maxDepth,
    };
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] ?? '',
      parentId: json['parentId'],
      projectId: json['projectId'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      isCompleted: json['isCompleted'] ?? false,
      type: TaskType.values[json['type'] as int? ?? 0],
      totalSteps: json['totalSteps'] as int? ?? 1,
      completedSteps: json['completedSteps'] as int? ?? 0,
      maxDepth: json['maxDepth'] as int? ?? 5,
    );
  }
}