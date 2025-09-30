import '../models/task.dart';
import '../models/project.dart';
import '../models/progress_history.dart';

class CompletionService {
  // Основной метод завершения задачи
  Task completeTask(Task task, {bool isCompleted = true}) {
    final updatedTask = task.copyWith(
      isCompleted: isCompleted,
      completedAt: isCompleted ? DateTime.now() : null,
    );

    // Обновляем прогресс родительской задачи
    return _updateTaskProgress(updatedTask);
  }

  // Завершение подзадачи
  Task completeSubtask(Task parentTask, String subtaskId, {bool isCompleted = true}) {
    final updatedSubtasks = parentTask.subtasks.map((subtask) {
      if (subtask.id == subtaskId) {
        return completeTask(subtask, isCompleted: isCompleted);
      }
      return subtask;
    }).toList();

    final updatedParent = parentTask.copyWith(subtasks: updatedSubtasks);
    return _updateTaskProgress(updatedParent);
  }

  // Рекурсивное обновление прогресса задачи
  Task _updateTaskProgress(Task task) {
    if (!task.hasSubtasks) {
      return task; // Задача без подзадач - возвращаем как есть
    }

    // Расчет прогресса на основе подзадач
    final completedSubtasks = task.calculateCompletedSubtasks();
    final totalSubtasks = task.calculateTotalSubtasks();
    final allSubtasksCompleted = task.subtasks.every((subtask) => subtask.isCompleted);

    return task.copyWith(
      isCompleted: allSubtasksCompleted,
      completedSubtasks: completedSubtasks,
      totalSubtasks: totalSubtasks,
      completedAt: allSubtasksCompleted ? DateTime.now() : null,
    );
  }

  // Обновление прогресса в проекте
  Project updateProjectProgress(Project project, String updatedTaskId, Task updatedTask) {
    return project.updateTask(updatedTaskId, updatedTask);
  }

  // Создание записи в истории прогресса
  ProgressHistory createProgressHistory(Task task, DateTime completedAt) {
    return ProgressHistory(
      id: '${task.id}_${completedAt.millisecondsSinceEpoch}',
      taskId: task.id,
      taskTitle: task.title,
      completedAt: completedAt,
      taskType: task.type,
      projectId: task.projectId,
      nestingLevel: task.nestingLevel,
    );
  }

  // Проверка валидности состояния задачи
  bool validateTaskState(Task task) {
    if (task.completedSubtasks > task.totalSubtasks) {
      return false;
    }
    if (task.isCompleted && task.totalSubtasks > 0 && task.completedSubtasks != task.totalSubtasks) {
      return false;
    }

    // Рекурсивная проверка подзадач
    for (final subtask in task.subtasks) {
      if (!validateTaskState(subtask)) {
        return false;
      }
    }

    return true;
  }

  // Исправление некорректного состояния задачи
  Task fixTaskState(Task task) {
    var fixedTask = task;

    // Исправляем completedSubtasks
    if (fixedTask.completedSubtasks > fixedTask.totalSubtasks) {
      fixedTask = fixedTask.copyWith(completedSubtasks: fixedTask.totalSubtasks);
    }

    // Исправляем isCompleted
    if (fixedTask.hasSubtasks) {
      final allSubtasksCompleted = fixedTask.subtasks.every((subtask) => subtask.isCompleted);
      if (fixedTask.isCompleted != allSubtasksCompleted) {
        fixedTask = fixedTask.copyWith(isCompleted: allSubtasksCompleted);
      }
    }

    // Рекурсивно исправляем подзадачи
    final fixedSubtasks = fixedTask.subtasks.map((subtask) => fixTaskState(subtask)).toList();
    fixedTask = fixedTask.copyWith(subtasks: fixedSubtasks);

    // Пересчитываем прогресс
    fixedTask = _updateTaskProgress(fixedTask);

    return fixedTask;
  }
}