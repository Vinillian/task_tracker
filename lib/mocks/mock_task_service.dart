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

  // Clear mock data
  void clearMockData() {
    _mockTasks.clear();
  }
}