// lib/models/task.dart
import 'task_type.dart';

class Task {
  final String id;
  final String title;
  final String description;
  bool isCompleted;
  final List<Task> subTasks;
  final TaskType type;
  final int totalSteps;
  int completedSteps;
  final int maxDepth;

  Task({
    required this.id,
    required this.title,
    required this.description,
    this.isCompleted = false,
    this.subTasks = const [],
    this.type = TaskType.single,
    this.totalSteps = 1,
    this.completedSteps = 0,
    this.maxDepth = 5,
  });

  // ✅ СОБСТВЕННЫЙ прогресс задачи (без учета подзадач)
  double get ownProgress {
    if (type == TaskType.stepByStep) {
      return totalSteps > 0 ? completedSteps / totalSteps : 0.0;
    }
    return isCompleted ? 1.0 : 0.0;
  }

  // ✅ ОБЩИЙ прогресс (с учетом подзадач) - ИСПРАВЛЕННАЯ ЛОГИКА
  double get progress {
    if (type == TaskType.stepByStep) {
      return totalSteps > 0 ? completedSteps / totalSteps : 0.0;
    }

    if (subTasks.isEmpty) {
      return isCompleted ? 1.0 : 0.0;
    }

    final allTasks = getAllTasks();
    final completedCount = allTasks.where((task) => task.isCompleted).length;

    return allTasks.isEmpty ? 0.0 : completedCount / allTasks.length;
  }

  // ✅ Публичный метод для получения всех задач всех уровней
  List<Task> getAllTasks() {
    final allTasks = <Task>[this];
    for (final subTask in subTasks) {
      allTasks.addAll(subTask.getAllTasks());
    }
    return allTasks;
  }

  // ✅ Получить количество всех задач (включая подзадачи)
  int get totalTasksCount => getAllTasks().length;

  // ✅ Получить количество выполненных задач (включая подзадачи)
  int get completedTasksCount =>
      getAllTasks().where((task) => task.isCompleted).length;

  bool get canAddSubTask => calculateDepth() < maxDepth;

  int calculateDepth([int currentDepth = 0]) {
    if (subTasks.isEmpty) return currentDepth;
    final depths =
        subTasks.map((task) => task.calculateDepth(currentDepth + 1));
    return depths.reduce((a, b) => a > b ? a : b);
  }

  // ✅ Метод для автоматического завершения при 100% прогрессе
  void updateCompletionStatus() {
    if (type == TaskType.stepByStep) {
      if (completedSteps >= totalSteps && totalSteps > 0) {
        isCompleted = true;
      }
    } else if (subTasks.isNotEmpty) {
      final allSubTasks = getAllSubTasks();
      final allCompleted = allSubTasks.every((task) => task.isCompleted);
      if (allCompleted && allSubTasks.isNotEmpty) {
        isCompleted = true;
      }
    }
  }

  // ✅ Получить все подзадачи (включая вложенные)
  List<Task> getAllSubTasks() {
    final allSubTasks = <Task>[];
    for (final subTask in subTasks) {
      allSubTasks.add(subTask);
      allSubTasks.addAll(subTask.getAllSubTasks());
    }
    return allSubTasks;
  }

  Task copyWith({
    String? id,
    String? title,
    String? description,
    bool? isCompleted,
    List<Task>? subTasks,
    TaskType? type,
    int? totalSteps,
    int? completedSteps,
    int? maxDepth,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      subTasks: subTasks ?? this.subTasks,
      type: type ?? this.type,
      totalSteps: totalSteps ?? this.totalSteps,
      completedSteps: completedSteps ?? this.completedSteps,
      maxDepth: maxDepth ?? this.maxDepth,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'isCompleted': isCompleted,
      'subTasks': subTasks.map((task) => task.toJson()).toList(),
      'type': type.index,
      'totalSteps': totalSteps,
      'completedSteps': completedSteps,
      'maxDepth': maxDepth,
    };
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      isCompleted: json['isCompleted'] ?? false,
      subTasks: (json['subTasks'] as List<dynamic>?)
              ?.map((taskJson) => Task.fromJson(taskJson))
              .toList() ??
          [],
      type: TaskType.values[json['type'] as int? ?? 0],
      totalSteps: json['totalSteps'] as int? ?? 1,
      completedSteps: json['completedSteps'] as int? ?? 0,
      maxDepth: json['maxDepth'] as int? ?? 5,
    );
  }
}
