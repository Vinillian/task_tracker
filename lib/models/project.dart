// lib/models/project.dart
class Project {
  final String id;
  final String name;
  final String description;
  final int color;
  final DateTime createdAt;
  final List<Task> tasks;

  Project({
    required this.id,
    required this.name,
    required this.description,
    required this.color,
    required this.createdAt,
    required this.tasks,
  });

  Project copyWith({
    String? id,
    String? name,
    String? description,
    int? color,
    DateTime? createdAt,
    List<Task>? tasks,
  }) {
    return Project(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
      tasks: tasks ?? this.tasks,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'color': color,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'tasks': tasks.map((task) => task.toJson()).toList(),
    };
  }

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      color: json['color'] ?? 0xFF2196F3,
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] ?? 0),
      tasks: (json['tasks'] as List<dynamic>?)
          ?.map((taskJson) => Task.fromJson(taskJson))
          .toList() ??
          [],
    );
  }

  // Вспомогательные методы
  double get progress {
    if (tasks.isEmpty) return 0.0;

    final totalProgress = tasks.fold(0.0, (sum, task) => sum + task.progress);
    return totalProgress / tasks.length;
  }

  int get totalTasks {
    int countTasks(Task task) {
      return 1 + task.subTasks.fold(0, (sum, subtask) => sum + countTasks(subtask));
    }

    return tasks.fold(0, (sum, task) => sum + countTasks(task));
  }

  int get completedTasks {
    int countCompleted(Task task) {
      final selfCompleted = task.isCompleted ? 1 : 0;
      final subtasksCompleted = task.subTasks.fold(0,
              (sum, subtask) => sum + countCompleted(subtask));
      return selfCompleted + subtasksCompleted;
    }

    return tasks.fold(0, (sum, task) => sum + countCompleted(task));
  }
}