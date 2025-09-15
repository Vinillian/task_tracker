import '../models/task.dart';
import '../models/subtask.dart';

class TaskService {
  static Task createTask(String name, int steps) =>
      Task(name: name, totalSteps: steps, completedSteps: 0, subtasks: []);

  static Subtask createSubtask(String name, int steps) =>
      Subtask(name: name, totalSteps: steps, completedSteps: 0);

  static void updateTask(Task task, String name, int steps) {
    task.name = name;
    task.totalSteps = steps;
    if (task.completedSteps > steps) task.completedSteps = steps;
  }

  static void updateSubtask(Subtask subtask, String name, int steps) {
    subtask.name = name;
    subtask.totalSteps = steps;
    if (subtask.completedSteps > steps) subtask.completedSteps = steps;
  }

  // Новый метод для добавления прогресса
  static void addProgressToTask(Task task, int steps) {
    task.completedSteps = (task.completedSteps + steps).clamp(0, task.totalSteps);
  }

  // Новый метод для добавления прогресса подзадачи
  static void addProgressToSubtask(Subtask subtask, int steps) {
    subtask.completedSteps = (subtask.completedSteps + steps).clamp(0, subtask.totalSteps);
  }
}