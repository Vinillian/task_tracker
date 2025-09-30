// models/project.dart
import 'task.dart';
import 'task_type.dart'; // ✅ ДОБАВЛЕН ИМПОРТ

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

  // ✅ ГИБРИДНАЯ ЛОГИКА: прогресс проекта учитывает ВСЕ задачи и подзадачи
  double get progress {
    if (tasks.isEmpty) return 0.0;

    // Рекурсивно собираем прогресс всех задач и подзадач
    double totalProgress = 0.0;
    int totalTasksCount = 0;

    void calculateTaskProgress(Task task) {
      // Добавляем прогресс текущей задачи
      totalProgress += _getTaskOwnProgress(task);
      totalTasksCount += 1;

      // Рекурсивно обрабатываем подзадачи
      for (final subTask in task.subTasks) {
        calculateTaskProgress(subTask);
      }
    }

    // Обрабатываем все прямые задачи проекта
    for (final task in tasks) {
      calculateTaskProgress(task);
    }

    return totalTasksCount > 0 ? totalProgress / totalTasksCount : 0.0;
  }

  // ✅ Вспомогательный метод: прогресс только самой задачи (без учета подзадач)
  double _getTaskOwnProgress(Task task) {
    if (task.type == TaskType.stepByStep) {
      return task.totalSteps > 0 ? task.completedSteps / task.totalSteps : 0.0;
    } else {
      return task.isCompleted ? 1.0 : 0.0;
    }
  }

  // ✅ Счетчики тоже учитывают ВСЕ задачи рекурсивно
  int get totalTasks {
    int count = 0;

    void countTasks(Task task) {
      count += 1;
      for (final subTask in task.subTasks) {
        countTasks(subTask);
      }
    }

    for (final task in tasks) {
      countTasks(task);
    }

    return count;
  }

  int get completedTasks {
    int completedCount = 0;

    void countCompletedTasks(Task task) {
      if (_isTaskCompleted(task)) {
        completedCount += 1;
      }

      for (final subTask in task.subTasks) {
        countCompletedTasks(subTask);
      }
    }

    for (final task in tasks) {
      countCompletedTasks(task);
    }

    return completedCount;
  }

  // ✅ Вспомогательный метод: проверка завершения задачи (только собственный статус)
  bool _isTaskCompleted(Task task) {
    if (task.type == TaskType.stepByStep) {
      return task.completedSteps == task.totalSteps;
    } else {
      return task.isCompleted;
    }
  }

  // Остальные методы без изменений...
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