// lib/services/task_service.dart
import '../models/project.dart';
import '../models/task.dart';
import 'firestore_service.dart';

class TaskService {
  final FirestoreService _firestoreService;

  TaskService(this._firestoreService);

  // ========== STREAMS ==========
  Stream<List<Project>> watchProjects() {
    return _firestoreService.watchProjects();
  }

  Stream<List<Task>> watchProjectTasks(String projectId) {
    return _firestoreService.watchProjectTasks(projectId);
  }

  Stream<List<Task>> watchSubTasks(String projectId, String parentTaskId) {
    return _firestoreService.watchSubTasks(projectId, parentTaskId);
  }

  // ========== TASK OPERATIONS ==========
  Future<void> addTask(String projectId, Task task) async {
    await _firestoreService.addTask(projectId, task);
  }

  Future<void> updateTask(String projectId, Task task) async {
    await _firestoreService.updateTask(projectId, task);
  }

  Future<void> deleteTask(String projectId, String taskId) async {
    await _firestoreService.deleteTask(projectId, taskId);
  }

  Future<void> moveTask(String projectId, String taskId, String? newParentTaskId) async {
    await _firestoreService.moveTask(projectId, taskId, newParentTaskId);
  }

  // ========== COMPLETION METHODS ==========
  Future<void> completeTask(String projectId, Task task) async {
    final updatedTask = task.copyWith(isCompleted: true);
    await _firestoreService.updateTask(projectId, updatedTask);
  }

  Future<void> uncompleteTask(String projectId, Task task) async {
    final updatedTask = task.copyWith(isCompleted: false);
    await _firestoreService.updateTask(projectId, updatedTask);
  }

  // ========== PROJECT OPERATIONS ==========
  Future<void> addProject(Project project) async {
    await _firestoreService.addProject(project);
  }

  Future<void> updateProject(Project project) async {
    await _firestoreService.updateProject(project);
  }

  Future<void> deleteProject(String projectId) async {
    await _firestoreService.deleteProject(projectId);
  }

  // ========== UTILITY METHODS ==========
  Future<List<Task>> getAllTasksForDate(DateTime date) async {
    final projects = await _firestoreService.watchProjects().first;
    final allTasks = <Task>[];

    void collectTasks(List<Task> tasks) {
      for (final task in tasks) {
        if (_isTaskForDate(task, date)) {
          allTasks.add(task);
        }
        collectTasks(task.subTasks);
      }
    }

    for (final project in projects) {
      collectTasks(project.tasks);
    }

    return allTasks;
  }

  bool _isTaskForDate(Task task, DateTime date) {
    if (task.dueDate == null) return false;

    final taskDate = DateTime(
      task.dueDate!.year,
      task.dueDate!.month,
      task.dueDate!.day,
    );

    final targetDate = DateTime(date.year, date.month, date.day);

    return taskDate == targetDate;
  }

  Future<void> completeTaskWithSubtasks(String projectId, Task task, bool completeSubtasks) async {
    if (completeSubtasks) {
      // Complete all subtasks recursively
      await _completeTaskAndSubtasks(projectId, task);
    } else {
      // Complete only the main task
      final updatedTask = task.copyWith(isCompleted: true);
      await _firestoreService.updateTask(projectId, updatedTask);
    }
  }

  Future<void> _completeTaskAndSubtasks(String projectId, Task task) async {
    // Complete current task
    final updatedTask = task.copyWith(isCompleted: true);
    await _firestoreService.updateTask(projectId, updatedTask);

    // Complete all subtasks recursively
    for (final subtask in task.subTasks) {
      await _completeTaskAndSubtasks(projectId, subtask);
    }
  }
}