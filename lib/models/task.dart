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

  // НОВЫЕ ПОЛЯ ДЛЯ АНАЛИТИКИ И КАЛЕНДАРЯ
  @HiveField(10)
  final int? color;

  @HiveField(11)
  final int? priority; // 0=low, 1=medium, 2=high

  @HiveField(12)
  final int? estimatedMinutes;

  @HiveField(13)
  final DateTime? dueDate;

  @HiveField(14)
  final bool isRecurring;

  @HiveField(15)
  final DateTime? lastCompletedDate;

  @HiveField(16)
  final DateTime createdAt;

  @HiveField(17)
  DateTime updatedAt;

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
    // Новые параметры с значениями по умолчанию
    this.color,
    this.priority = 1, // medium по умолчанию
    this.estimatedMinutes,
    this.dueDate,
    this.isRecurring = false,
    this.lastCompletedDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  double get progress {
    if (type == TaskType.stepByStep) {
      return totalSteps > 0 ? completedSteps / totalSteps : 0.0;
    }
    return isCompleted ? 1.0 : 0.0;
  }

  // Фабричный метод для удобного создания
  factory Task.create({
    required String title,
    required String projectId,
    String? parentId,
    String description = '',
    TaskType type = TaskType.single,
    int totalSteps = 1,
    int? color,
    int priority = 1,
    int? estimatedMinutes,
    DateTime? dueDate,
    bool isRecurring = false,
  }) {
    return Task(
      id: 'task_${DateTime.now().millisecondsSinceEpoch}',
      parentId: parentId,
      projectId: projectId,
      title: title,
      description: description,
      type: type,
      totalSteps: totalSteps,
      color: color,
      priority: priority,
      estimatedMinutes: estimatedMinutes,
      dueDate: dueDate,
      isRecurring: isRecurring,
    );
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
    int? color,
    int? priority,
    int? estimatedMinutes,
    DateTime? dueDate,
    bool? isRecurring,
    DateTime? lastCompletedDate,
    DateTime? updatedAt,
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
      color: color ?? this.color,
      priority: priority ?? this.priority,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      dueDate: dueDate ?? this.dueDate,
      isRecurring: isRecurring ?? this.isRecurring,
      lastCompletedDate: lastCompletedDate ?? this.lastCompletedDate,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
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
      'color': color,
      'priority': priority,
      'estimatedMinutes': estimatedMinutes,
      'dueDate': dueDate?.millisecondsSinceEpoch,
      'isRecurring': isRecurring,
      'lastCompletedDate': lastCompletedDate?.millisecondsSinceEpoch,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
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
      color: json['color'] as int?,
      priority: json['priority'] as int? ?? 1,
      estimatedMinutes: json['estimatedMinutes'] as int?,
      dueDate: json['dueDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['dueDate'] as int)
          : null,
      isRecurring: json['isRecurring'] ?? false,
      lastCompletedDate: json['lastCompletedDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['lastCompletedDate'] as int)
          : null,
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int? ?? 0),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(json['updatedAt'] as int? ?? 0),
    );
  }
}