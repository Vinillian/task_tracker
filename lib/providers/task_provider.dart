import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/task.dart';
import '../services/task_service.dart';
import 'project_provider.dart';

final taskServiceProvider = Provider<TaskService>((ref) {
  final storageService = ref.watch(storageServiceProvider);
  return TaskService(storageService);
});

final tasksProvider = StateNotifierProvider<TaskNotifier, List<Task>>((ref) {
  final taskService = ref.watch(taskServiceProvider);
  return TaskNotifier(taskService);
});

class TaskNotifier extends StateNotifier<List<Task>> {
  final TaskService _taskService;

  TaskNotifier(this._taskService) : super([]);

  Future<void> loadTasks() async {
    await _taskService.loadTasksFromStorage();
    state = _taskService.getAllTasks();
  }

  void addTask(Task task) {
    _taskService.addTask(task);
    state = _taskService.getAllTasks();
  }

  void updateTask(Task updatedTask) {
    _taskService.updateTask(updatedTask);
    state = _taskService.getAllTasks();
  }

  void removeTask(String taskId) {
    _taskService.removeTask(taskId);
    state = _taskService.getAllTasks();
  }

  void loadDemoTasks(String projectId) {
    _taskService.loadDemoTasks(projectId);
    state = _taskService.getAllTasks();
  }

  void clearAllTasks() {
    _taskService.clearAllTasks();
    state = [];
  }

  // ✅ НОВЫЕ МЕТОДЫ ДЛЯ УПРАВЛЕНИЯ СОСТОЯНИЕМ
  void toggleTaskCompletion(String taskId) {
    final task = _taskService.getTaskById(taskId);
    if (task != null) {
      final updatedTask = task.copyWith(
        isCompleted: !task.isCompleted,
        lastCompletedDate: !task.isCompleted ? DateTime.now() : null,
        updatedAt: DateTime.now(),
      );
      updateTask(updatedTask);
    }
  }

  void updateTaskSteps(String taskId, int completedSteps) {
    final task = _taskService.getTaskById(taskId);
    if (task != null) {
      final updatedTask = task.copyWith(
        completedSteps: completedSteps,
        isCompleted: completedSteps >= task.totalSteps,
        updatedAt: DateTime.now(),
      );
      updateTask(updatedTask);
    }
  }
}

// ✅ Провайдер для получения задачи по ID
final taskByIdProvider = Provider.family<Task?, String>((ref, taskId) {
  final tasks = ref
      .watch(tasksProvider); // ✅ ДОБАВЛЕНО: следим за изменениями списка задач
  try {
    return tasks.firstWhere((task) => task.id == taskId);
  } catch (e) {
    return null;
  }
});
