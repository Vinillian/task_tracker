import '../models/task.dart';
import '../models/project.dart';
import 'completion_service.dart';

class TaskService {
  final CompletionService _completionService;

  TaskService(this._completionService);

  // Создание новой задачи
  Task createTask({
    required String title,
    required String projectId,
    TaskType type = TaskType.single,
    String? description,
    int priority = 1,
    DateTime? dueDate,
    int estimatedMinutes = 0,
    int nestingLevel = 0,
  }) {
    return Task(
      id: 'task_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      description: description,
      isCompleted: false,
      completedSubtasks: 0,
      totalSubtasks: 0,
      subtasks: [],
      type: type,
      priority: priority,
      dueDate: dueDate,
      estimatedMinutes: estimatedMinutes,
      projectId: projectId,
      nestingLevel: nestingLevel,
      createdAt: DateTime.now(),
    );
  }

  // Создание подзадачи
  Task createSubtask(Task parentTask, String title) {
    if (!parentTask.canAddSubtask()) {
      throw Exception('Cannot add subtask: maximum nesting level reached');
    }

    return Task(
      id: 'subtask_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      isCompleted: false,
      completedSubtasks: 0,
      totalSubtasks: 0,
      subtasks: [],
      type: TaskType.single,
      priority: parentTask.priority,
      projectId: parentTask.projectId,
      nestingLevel: parentTask.nestingLevel + 1,
      createdAt: DateTime.now(),
    );
  }

  // Завершение задачи
  Task completeTask(Task task) {
    return _completionService.completeTask(task, isCompleted: true);
  }

  // Отмена завершения задачи
  Task uncompleteTask(Task task) {
    return _completionService.completeTask(task, isCompleted: false);
  }

  // Завершение подзадачи
  Task completeSubtask(Task parentTask, String subtaskId) {
    return _completionService.completeSubtask(parentTask, subtaskId, isCompleted: true);
  }

  // Добавление подзадачи к родительской задаче
  Task addSubtaskToParent(Task parentTask, Task subtask) {
    return parentTask.addSubtask(subtask);
  }

  // Удаление подзадачи
  Task removeSubtask(Task parentTask, String subtaskId) {
    return parentTask.removeSubtask(subtaskId);
  }

  // Обновление заголовка задачи
  Task updateTaskTitle(Task task, String newTitle) {
    return task.copyWith(title: newTitle);
  }

  // Обновление описания задачи
  Task updateTaskDescription(Task task, String newDescription) {
    return task.copyWith(description: newDescription);
  }

  // Обновление приоритета задачи
  Task updateTaskPriority(Task task, int newPriority) {
    return task.copyWith(priority: newPriority);
  }

  // Обновление даты выполнения
  Task updateTaskDueDate(Task task, DateTime? newDueDate) {
    return task.copyWith(dueDate: newDueDate);
  }

  // Получение всех подзадач (рекурсивно)
  List<Task> getAllSubtasks(Task task) {
    final allSubtasks = <Task>[];
    _collectSubtasksRecursively(task, allSubtasks);
    return allSubtasks;
  }

  void _collectSubtasksRecursively(Task task, List<Task> result) {
    for (final subtask in task.subtasks) {
      result.add(subtask);
      _collectSubtasksRecursively(subtask, result);
    }
  }

  // Поиск задачи по ID (рекурсивно)
  Task? findTaskById(List<Task> tasks, String taskId) {
    for (final task in tasks) {
      if (task.id == taskId) return task;
      final found = _findInSubtasks(task, taskId);
      if (found != null) return found;
    }
    return null;
  }

  Task? _findInSubtasks(Task parentTask, String taskId) {
    for (final subtask in parentTask.subtasks) {
      if (subtask.id == taskId) return subtask;
      final found = _findInSubtasks(subtask, taskId);
      if (found != null) return found;
    }
    return null;
  }

  // Проверка валидности структуры задач
  bool validateTaskStructure(Task task) {
    // Проверяем уровень вложенности
    if (task.nestingLevel > 2) {
      return false;
    }

    // Проверяем подзадачи
    for (final subtask in task.subtasks) {
      if (subtask.nestingLevel != task.nestingLevel + 1) {
        return false;
      }
      if (!validateTaskStructure(subtask)) {
        return false;
      }
    }

    return true;
  }

  // Исправление структуры задач
  Task fixTaskStructure(Task task) {
    var fixedTask = _completionService.fixTaskState(task);

    // Исправляем уровень вложенности подзадач
    final fixedSubtasks = fixedTask.subtasks.map((subtask) {
      var fixedSubtask = fixTaskStructure(subtask);
      if (fixedSubtask.nestingLevel != fixedTask.nestingLevel + 1) {
        fixedSubtask = fixedSubtask.copyWith(nestingLevel: fixedTask.nestingLevel + 1);
      }
      return fixedSubtask;
    }).toList();

    return fixedTask.copyWith(subtasks: fixedSubtasks);
  }

  // Получение прогресса задачи
  double getTaskProgress(Task task) {
    return task.progress;
  }

  // Проверка, можно ли добавить подзадачу
  bool canAddSubtask(Task task) {
    return task.canAddSubtask();
  }
}