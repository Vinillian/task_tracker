// lib/models/project.dart
import 'task.dart';

class Project {
  final String id;
  final String name;
  final String description;
  final List<Task> tasks;
  final DateTime createdAt;

  Project({
    required this.id,
    required this.name,
    required this.description,
    required this.tasks,
    required this.createdAt,
  });

  // ✅ Прогресс проекта с учетом ВСЕХ задач всех уровней
  double get progress {
    if (tasks.isEmpty) return 0.0;

    // Убедитесь что логика расчета правильная
    double totalProgress = 0.0;
    for (final task in tasks) {
      totalProgress += task.progress;
    }

    return tasks.isEmpty ? 0.0 : totalProgress / tasks.length;
  }

  // ✅ Общее количество задач (включая все подзадачи)
  int get totalTasks {
    int count = 0;
    for (final task in tasks) {
      count += task.totalTasksCount;
    }
    return count;
  }

  // ✅ Количество выполненных задач (включая все подзадачи)
  int get completedTasks {
    int count = 0;
    for (final task in tasks) {
      count += task.completedTasksCount;
    }
    return count;
  }

  // ✅ Метод для обновления статусов завершения всех задач
  void updateAllCompletionStatuses() {
    for (final task in tasks) {
      _updateTaskCompletionStatus(task);
    }
  }

  void _updateTaskCompletionStatus(Task task) {
    for (final subTask in task.subTasks) {
      _updateTaskCompletionStatus(subTask);
    }
    task.updateCompletionStatus();
  }

  Project copyWith({
    String? id,
    String? name,
    String? description,
    List<Task>? tasks,
    DateTime? createdAt,
  }) {
    return Project(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      tasks: tasks ?? this.tasks,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'tasks': tasks.map((task) => task.toJson()).toList(),
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      tasks: (json['tasks'] as List<dynamic>?)
              ?.map((taskJson) => Task.fromJson(taskJson))
              .toList() ??
          [],
      createdAt:
          DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int? ?? 0),
    );
  }
}
