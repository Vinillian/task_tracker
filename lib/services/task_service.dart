import '../models/task.dart';
import '../models/subtask.dart';
import '../models/task_type.dart';
import '../models/recurrence.dart';

class TaskService {
  static Task createTask({
    required String name,
    required int steps,
    TaskType taskType = TaskType.stepByStep,
    Recurrence? recurrence,
    DateTime? dueDate,
    String? description,
  }) {
    return Task(
      name: name,
      totalSteps: steps,
      completedSteps: 0,
      subtasks: [],
      taskType: taskType.toString(),
      recurrence: recurrence,
      dueDate: dueDate,
      description: description,
      isCompleted: false,
    );
  }

  // services/task_service.dart
  static Subtask createSubtask(String name, int steps, {String subtaskType = 'stepByStep'}) {
    return Subtask(
      name: name,
      totalSteps: steps,
      completedSteps: 0,
      subtaskType: subtaskType,
      isCompleted: false,
    );
  }

  static Subtask toggleSubtaskCompletion(Subtask subtask) {
    return Subtask(
      name: subtask.name,
      completedSteps: subtask.completedSteps,
      totalSteps: subtask.totalSteps,
      subtaskType: subtask.subtaskType,
      isCompleted: !subtask.isCompleted,
    );
  }

  static Subtask addProgressToSubtask(Subtask subtask, int steps) {
    if (subtask.subtaskType == 'singleStep') {
      return toggleSubtaskCompletion(subtask);
    }

    return Subtask(
      name: subtask.name,
      completedSteps: (subtask.completedSteps + steps).clamp(0, subtask.totalSteps),
      totalSteps: subtask.totalSteps,
      subtaskType: subtask.subtaskType,
      isCompleted: subtask.isCompleted,
    );
  }

  static Subtask updateSubtask(Subtask oldSubtask, String name, int steps) {
    return Subtask(
      name: name,
      completedSteps: oldSubtask.completedSteps.clamp(0, steps),
      totalSteps: steps,
      subtaskType: oldSubtask.subtaskType, // ← ДОБАВИТЬ
      isCompleted: oldSubtask.isCompleted, // ← ДОБАВИТЬ
    );
  }

  static Task updateTask(Task oldTask, String name, int steps) {
    return Task(
      name: name,
      completedSteps: oldTask.completedSteps.clamp(0, steps),
      totalSteps: steps,
      subtasks: oldTask.subtasks,
      taskType: oldTask.taskType,
      recurrence: oldTask.recurrence,
      dueDate: oldTask.dueDate,
      isCompleted: oldTask.isCompleted,
      description: oldTask.description,
    );
  }

  static Task addProgressToTask(Task task, int steps) {
    final newCompletedSteps = (task.completedSteps + steps).clamp(0, task.totalSteps);
    final isCompleted = newCompletedSteps >= task.totalSteps;

    return Task(
      name: task.name,
      completedSteps: newCompletedSteps,
      totalSteps: task.totalSteps,
      subtasks: task.subtasks,
      taskType: task.taskType,
      recurrence: task.recurrence,
      dueDate: task.dueDate,
      isCompleted: isCompleted,
      description: task.description,
    );
  }

  static Task toggleTaskCompletion(Task task) {
    return Task(
      name: task.name,
      completedSteps: task.completedSteps,
      totalSteps: task.totalSteps,
      subtasks: task.subtasks,
      taskType: task.taskType,
      recurrence: task.recurrence,
      dueDate: task.dueDate,
      isCompleted: !task.isCompleted,
      description: task.description,
    );
  }
}