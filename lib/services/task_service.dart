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
  }) =>
      Task(
        name: name,
        totalSteps: steps,
        completedSteps: 0,
        subtasks: [],
        taskType: taskType,
        recurrence: recurrence,
        dueDate: dueDate,
        description: description,
      );

  static Subtask createSubtask(String name, int steps) =>
      Subtask(name: name, totalSteps: steps, completedSteps: 0);

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

  static Subtask updateSubtask(Subtask oldSubtask, String name, int steps) {
    return Subtask(
      name: name,
      completedSteps: oldSubtask.completedSteps.clamp(0, steps),
      totalSteps: steps,
    );
  }

  static Task addProgressToTask(Task task, int steps) {
    return Task(
      name: task.name,
      completedSteps: (task.completedSteps + steps).clamp(0, task.totalSteps),
      totalSteps: task.totalSteps,
      subtasks: task.subtasks,
      taskType: task.taskType,
      recurrence: task.recurrence,
      dueDate: task.dueDate,
      isCompleted: task.isCompleted,
      description: task.description,
    );
  }

  static Subtask addProgressToSubtask(Subtask subtask, int steps) {
    return Subtask(
      name: subtask.name,
      completedSteps: (subtask.completedSteps + steps).clamp(0, subtask.totalSteps),
      totalSteps: subtask.totalSteps,
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