import '../models/task.dart';
import '../models/subtask.dart';

class TaskService {
  static Task createTask(String name, int steps) =>
      Task(name: name, totalSteps: steps, completedSteps: 0, subtasks: []);

  static Subtask createSubtask(String name, int steps) =>
      Subtask(name: name, totalSteps: steps, completedSteps: 0);

  // Вместо изменения существующего объекта, создаем новый
  static Task updateTask(Task oldTask, String name, int steps) {
    return Task(
      name: name,
      completedSteps: oldTask.completedSteps.clamp(0, steps),
      totalSteps: steps,
      subtasks: oldTask.subtasks,
    );
  }

  static Subtask updateSubtask(Subtask oldSubtask, String name, int steps) {
    return Subtask(
      name: name,
      completedSteps: oldSubtask.completedSteps.clamp(0, steps),
      totalSteps: steps,
    );
  }

  // Новый метод для добавления прогресса
  static Task addProgressToTask(Task task, int steps) {
    return Task(
      name: task.name,
      completedSteps: (task.completedSteps + steps).clamp(0, task.totalSteps),
      totalSteps: task.totalSteps,
      subtasks: task.subtasks,
    );
  }

  // Новый метод для добавления прогресса подзадачи
  static Subtask addProgressToSubtask(Subtask subtask, int steps) {
    return Subtask(
      name: subtask.name,
      completedSteps: (subtask.completedSteps + steps).clamp(0, subtask.totalSteps),
      totalSteps: subtask.totalSteps,
    );
  }
}