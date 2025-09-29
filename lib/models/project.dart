import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'task.dart';

part 'project.g.dart';

@JsonSerializable()
class Project {
  final String id;
  final String name;
  final String? description;
  final List<Task> tasks;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isCompleted;

  Project({
    required this.id,
    required this.name,
    this.description,
    required this.tasks,
    required this.createdAt,
    this.updatedAt,
    required this.isCompleted,
  });

  factory Project.fromJson(Map<String, dynamic> json) => _$ProjectFromJson(json);
  Map<String, dynamic> toJson() => _$ProjectToJson(this);

  // === НОВЫЕ МЕТОДЫ ДЛЯ РЕКУРСИВНЫХ ЗАДАЧ ===

  Project copyWith({
    String? id,
    String? name,
    String? description,
    List<Task>? tasks,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isCompleted,
  }) {
    return Project(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      tasks: tasks ?? this.tasks,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  // Добавление задачи
  Project addTask(Task task) {
    final newTasks = List<Task>.from(tasks)..add(task);
    return copyWith(tasks: newTasks, updatedAt: DateTime.now());
  }

  // Обновление задачи (рекурсивно)
  Project updateTask(String taskId, Task updatedTask) {
    final newTasks = tasks.map((task) {
      if (task.id == taskId) {
        return updatedTask;
      }
      // Рекурсивно ищем в подзадачах
      return _updateTaskInSubtasks(task, taskId, updatedTask);
    }).toList();

    return copyWith(tasks: newTasks, updatedAt: DateTime.now());
  }

  Task _updateTaskInSubtasks(Task parentTask, String taskId, Task updatedTask) {
    if (parentTask.subtasks.any((subtask) => subtask.id == taskId)) {
      final updatedSubtasks = parentTask.subtasks.map((subtask) {
        return subtask.id == taskId ? updatedTask : subtask;
      }).toList();
      return parentTask.copyWith(subtasks: updatedSubtasks);
    }

    // Рекурсивно ищем глубже
    final updatedSubtasks = parentTask.subtasks.map((subtask) {
      return _updateTaskInSubtasks(subtask, taskId, updatedTask);
    }).toList();

    return parentTask.copyWith(subtasks: updatedSubtasks);
  }

  // Удаление задачи (рекурсивно)
  Project removeTask(String taskId) {
    final newTasks = _removeTaskRecursively(tasks, taskId);
    return copyWith(tasks: newTasks, updatedAt: DateTime.now());
  }

  List<Task> _removeTaskRecursively(List<Task> tasks, String taskId) {
    return tasks.where((task) => task.id != taskId).map((task) {
      final updatedSubtasks = _removeTaskRecursively(task.subtasks, taskId);
      return task.copyWith(subtasks: updatedSubtasks);
    }).toList();
  }

  // Получение всех задач (включая подзадачи)
  List<Task> get allTasks {
    final all = <Task>[];
    for (final task in tasks) {
      all.add(task);
      _addSubtasksRecursively(task, all);
    }
    return all;
  }

  void _addSubtasksRecursively(Task task, List<Task> result) {
    for (final subtask in task.subtasks) {
      result.add(subtask);
      _addSubtasksRecursively(subtask, result);
    }
  }

  // Расчет прогресса проекта
  double get progress {
    if (tasks.isEmpty) return 0.0;

    final allTasksList = allTasks;
    final completedTasks = allTasksList.where((task) => task.isCompleted).length;

    return completedTasks / allTasksList.length;
  }

  // Получение задачи по ID (рекурсивно)
  Task? getTaskById(String taskId) {
    for (final task in tasks) {
      if (task.id == taskId) return task;
      final found = _findTaskInSubtasks(task, taskId);
      if (found != null) return found;
    }
    return null;
  }

  Task? _findTaskInSubtasks(Task parentTask, String taskId) {
    for (final subtask in parentTask.subtasks) {
      if (subtask.id == taskId) return subtask;
      final found = _findTaskInSubtasks(subtask, taskId);
      if (found != null) return found;
    }
    return null;
  }

  // Для Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'tasks': tasks.map((task) => task.toFirestore()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'isCompleted': isCompleted,
    };
  }

  factory Project.fromFirestore(Map<String, dynamic> data) {
    return Project(
      id: data['id'],
      name: data['name'],
      description: data['description'],
      tasks: (data['tasks'] as List).map((taskData) => Task.fromFirestore(taskData)).toList(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null ? (data['updatedAt'] as Timestamp).toDate() : null,
      isCompleted: data['isCompleted'],
    );
  }
}