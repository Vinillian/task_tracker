// models/project.dart
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

  double get progress {
    if (tasks.isEmpty) return 0.0;
    final totalProgress = tasks.map((task) => task.progress).reduce((a, b) => a + b);
    return totalProgress / tasks.length;
  }

  int get totalTasks => tasks.length;

  int get completedTasks => tasks.where((task) => task.isCompleted).length;

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
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      tasks: (json['tasks'] as List<dynamic>?)
          ?.map((taskJson) => Task.fromJson(taskJson as Map<String, dynamic>))
          .toList() ?? [],
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int? ?? 0),
    );
  }
}