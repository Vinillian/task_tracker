// lib/models/project.dart
// УДАЛИТЬ импорт task.dart если есть

class Project {
  final String id;
  final String name;
  final String description;
  final DateTime createdAt;
  // ✅ УДАЛЯЕМ List<Task> tasks - задачи теперь хранятся отдельно

  Project({
    required this.id,
    required this.name,
    required this.description,
    required this.createdAt,
  });

  // ✅ Прогресс и счетчики БУДУТ в TaskService
  double get progress => 0.0; // Временная заглушка
  int get totalTasks => 0;    // Временная заглушка
  int get completedTasks => 0; // Временная заглушка

  Project copyWith({
    String? id,
    String? name,
    String? description,
    DateTime? createdAt,
  }) {
    return Project(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'createdAt': createdAt.millisecondsSinceEpoch,
      // ✅ УДАЛЯЕМ tasks из JSON
    };
  }

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int? ?? 0),
    );
  }
}