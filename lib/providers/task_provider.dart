import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/task.dart';
import '../services/task_service.dart';

final taskServiceProvider = Provider<TaskService>((ref) {
  return TaskService();
});

final tasksProvider = StateNotifierProvider<TaskNotifier, List<Task>>((ref) {
  final taskService = ref.watch(taskServiceProvider);
  return TaskNotifier(taskService);
});

class TaskNotifier extends StateNotifier<List<Task>> {
  final TaskService _taskService;

  TaskNotifier(this._taskService) : super([]);

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
}