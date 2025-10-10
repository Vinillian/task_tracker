// lib/models/task.dart
import 'task_type.dart';

class Task {
  final String id;
  final String? parentId; // ✅ null для корневых задач
  final String projectId; // ✅ связь с проектом
  final String title;
  final String description;
  bool isCompleted;
  final TaskType type;
  final int totalSteps;
  int completedSteps;
  final int maxDepth;
  // ✅ БУДУЩИЕ ПОЛЯ для ваших фич:
  // DateTime? dueDate;
  // Priority priority;
  // Color color;
  // bool isDaily = false;

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

  // ✅ СОБСТВЕННЫЙ прогресс задачи (без учета подзадач)
  double get progress {
    if (type == TaskType.stepByStep) {
      return totalSteps > 0 ? completedSteps / totalSteps : 0.0;
    }
    return isCompleted ? 1.0 : 0.0;
  }

  // ✅ УДАЛЯЕМ все методы работы с subTasks
  // ❌ УБРАТЬ: get subTasks, getAllTasks(), calculateDepth() и т.д.

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