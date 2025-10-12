import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/task.dart';
import '../services/task_service.dart';
import 'project_provider.dart'; // ✅ ДОБАВИТЬ этот импорт для storageServiceProvider

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
}