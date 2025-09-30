import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'task_type.dart';

part 'task.g.dart';

@JsonSerializable()
class Task {
  final String id;
  final String title;
  final String? description;
  final bool isCompleted;
  final int completedSubtasks;
  final int totalSubtasks;
  final List<Task> subtasks;
  final TaskType type;
  final int priority;
  final DateTime? dueDate;
  final int estimatedMinutes;
  final String projectId;
  final int nestingLevel;
  final DateTime createdAt;
  final DateTime? completedAt;

  Task({
    required this.id,
    required this.title,
    this.description,
    required this.isCompleted,
    required this.completedSubtasks,
    required this.totalSubtasks,
    required this.subtasks,
    required this.type,
    this.priority = 1,
    this.dueDate,
    this.estimatedMinutes = 0,
    required this.projectId,
    this.nestingLevel = 0,
    required this.createdAt,
    this.completedAt,
  });

  factory Task.fromJson(Map<String, dynamic> json) => _$TaskFromJson(json);
  Map<String, dynamic> toJson() => _$TaskToJson(this);

  // === РЕКУРСИВНЫЕ МЕТОДЫ ===

  Task copyWith({
    String? id,
    String? title,
    String? description,
    bool? isCompleted,
    int? completedSubtasks,
    int? totalSubtasks,
    List<Task>? subtasks,
    TaskType? type,
    int? priority,
    DateTime? dueDate,
    int? estimatedMinutes,
    String? projectId,
    int? nestingLevel,
    DateTime? createdAt,
    DateTime? completedAt,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      completedSubtasks: completedSubtasks ?? this.completedSubtasks,
      totalSubtasks: totalSubtasks ?? this.totalSubtasks,
      subtasks: subtasks ?? this.subtasks,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      dueDate: dueDate ?? this.dueDate,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      projectId: projectId ?? this.projectId,
      nestingLevel: nestingLevel ?? this.nestingLevel,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  // Добавление подзадачи
  Task addSubtask(Task subtask) {
    final newSubtasks = List<Task>.from(subtasks)..add(subtask);
    return copyWith(
      subtasks: newSubtasks,
      totalSubtasks: totalSubtasks + 1,
    );
  }

  // Обновление подзадачи
  Task updateSubtask(String subtaskId, Task updatedSubtask) {
    final newSubtasks = subtasks.map((subtask) {
      return subtask.id == subtaskId ? updatedSubtask : subtask;
    }).toList();

    return copyWith(subtasks: newSubtasks);
  }

  // Удаление подзадачи
  Task removeSubtask(String subtaskId) {
    final newSubtasks = subtasks.where((subtask) => subtask.id != subtaskId).toList();
    return copyWith(
      subtasks: newSubtasks,
      totalSubtasks: totalSubtasks - 1,
    );
  }

  // Рекурсивный расчет выполненных подзадач
  int calculateCompletedSubtasks() {
    return subtasks.fold(0, (count, subtask) {
      return count + (subtask.isCompleted ? 1 : 0) + subtask.calculateCompletedSubtasks();
    });
  }

  // Рекурсивный расчет общего количества подзадач
  int calculateTotalSubtasks() {
    return subtasks.fold(0, (count, subtask) {
      return count + 1 + subtask.calculateTotalSubtasks();
    });
  }

  // Проверка возможности добавления подзадачи
  bool canAddSubtask() {
    return nestingLevel < 2; // Максимум 3 уровня (0, 1, 2)
  }

  // Создание новой подзадачи
  Task createNewSubtask(String title) {
    return Task(
      id: '${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      isCompleted: false,
      completedSubtasks: 0,
      totalSubtasks: 0,
      subtasks: [],
      type: TaskType.single,
      projectId: projectId,
      nestingLevel: nestingLevel + 1,
      createdAt: DateTime.now(),
    );
  }

  // Проверка на наличие подзадач
  bool get hasSubtasks => subtasks.isNotEmpty;

  // Прогресс в процентах
  double get progress {
    if (totalSubtasks == 0) return isCompleted ? 1.0 : 0.0;
    return completedSubtasks / totalSubtasks;
  }

  // Для Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'isCompleted': isCompleted,
      'completedSubtasks': completedSubtasks,
      'totalSubtasks': totalSubtasks,
      'subtasks': subtasks.map((subtask) => subtask.toFirestore()).toList(),
      'type': type.toString(),
      'priority': priority,
      'dueDate': dueDate,
      'estimatedMinutes': estimatedMinutes,
      'projectId': projectId,
      'nestingLevel': nestingLevel,
      'createdAt': Timestamp.fromDate(createdAt),
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
    };
  }

  factory Task.fromFirestore(Map<String, dynamic> data) {
    return Task(
      id: data['id'],
      title: data['title'],
      description: data['description'],
      isCompleted: data['isCompleted'],
      completedSubtasks: data['completedSubtasks'],
      totalSubtasks: data['totalSubtasks'],
      subtasks: (data['subtasks'] as List).map((subtaskData) => Task.fromFirestore(subtaskData)).toList(),
      type: TaskType.values.firstWhere((e) => e.toString() == data['type']),
      priority: data['priority'],
      dueDate: data['dueDate'] != null ? (data['dueDate'] as Timestamp).toDate() : null,
      estimatedMinutes: data['estimatedMinutes'],
      projectId: data['projectId'],
      nestingLevel: data['nestingLevel'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      completedAt: data['completedAt'] != null ? (data['completedAt'] as Timestamp).toDate() : null,
    );
  }
}