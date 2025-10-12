import 'package:task_tracker/models/task.dart';
import 'package:task_tracker/services/task_service.dart';

class MockTaskService extends TaskService {
  final List<Task> _mockTasks = [];

  @override
  void addTask(Task task) {
    _mockTasks.add(task);
  }

  @override
  List<Task> getProjectTasks(String projectId) {
    return _mockTasks.where((task) => task.projectId == projectId).toList();
  }

  @override
  List<Task> getSubTasks(String parentId) {
    return _mockTasks.where((task) => task.parentId == parentId).toList();
  }

  @override
  bool canAddSubTask(String parentId, {int maxDepth = 5}) {
    return true; // Always allow for tests
  }

  @override
  void updateTask(Task updatedTask) {
    final index = _mockTasks.indexWhere((t) => t.id == updatedTask.id);
    if (index != -1) {
      _mockTasks[index] = updatedTask;
    }
  }

  @override
  int getProjectTotalTasks(String projectId) {
    return _mockTasks.where((task) => task.projectId == projectId).length;
  }

  @override
  int getProjectCompletedTasks(String projectId) {
    return _mockTasks.where((task) => task.projectId == projectId && task.isCompleted).length;
  }

  @override
  double getProjectProgress(String projectId) {
    final projectTasks = _mockTasks.where((task) => task.projectId == projectId).toList();
    if (projectTasks.isEmpty) return 0.0;

    final completedCount = projectTasks.where((task) => task.isCompleted).length;
    return completedCount / projectTasks.length;
  }

  // Clear mock data
  void clearMockData() {
    _mockTasks.clear();
  }
}