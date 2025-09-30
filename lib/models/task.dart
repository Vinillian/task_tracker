// lib/models/task.dart
class Task {
  final String id;
  final String title;
  final String description;
  final bool isCompleted;
  final int priority;
  final DateTime? dueDate;
  final String? parentTaskId;
  final List<Task> subTasks;
  final DateTime createdAt;
  final DateTime updatedAt;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.isCompleted,
    required this.priority,
    this.dueDate,
    this.parentTaskId,
    required this.subTasks,
    required this.createdAt,
    required this.updatedAt,
  });

  Task copyWith({
    String? id,
    String? title,
    String? description,
    bool? isCompleted,
    int? priority,
    DateTime? dueDate,
    String? parentTaskId,
    List<Task>? subTasks,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      priority: priority ?? this.priority,
      dueDate: dueDate ?? this.dueDate,
      parentTaskId: parentTaskId ?? this.parentTaskId,
      subTasks: subTasks ?? this.subTasks,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'isCompleted': isCompleted,
      'priority': priority,
      'dueDate': dueDate?.millisecondsSinceEpoch,
      'parentTaskId': parentTaskId,
      'subTasks': subTasks.map((task) => task.toJson()).toList(),
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      isCompleted: json['isCompleted'] ?? false,
      priority: json['priority'] ?? 1,
      dueDate: json['dueDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['dueDate'])
          : null,
      parentTaskId: json['parentTaskId'],
      subTasks: (json['subTasks'] as List<dynamic>?)
          ?.map((taskJson) => Task.fromJson(taskJson))
          .toList() ??
          [],
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] ?? 0),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(json['updatedAt'] ?? 0),
    );
  }

  // Вспомогательные методы
  double get progress {
    if (subTasks.isEmpty) {
      return isCompleted ? 1.0 : 0.0;
    }

    final completedCount = subTasks.where((task) => task.isCompleted).length;
    return completedCount / subTasks.length;
  }

  bool get hasSubtasks => subTasks.isNotEmpty;
}