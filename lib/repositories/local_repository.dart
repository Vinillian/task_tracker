import 'package:hive/hive.dart';
import '../models/task.dart';
import '../models/project.dart';
import '../models/app_user.dart';
import '../models/progress_history.dart';

class LocalRepository {
  static const String _projectsBox = 'projects';
  static const String _tasksBox = 'tasks';
  static const String _userBox = 'user';
  static const String _progressHistoryBox = 'progress_history';

  late Box<Project> _projectsBoxInstance;
  late Box<Task> _tasksBoxInstance;
  late Box<AppUser> _userBoxInstance;
  late Box<ProgressHistory> _progressHistoryBoxInstance;

  Future<void> init() async {
    _projectsBoxInstance = await Hive.openBox<Project>(_projectsBox);
    _tasksBoxInstance = await Hive.openBox<Task>(_tasksBox);
    _userBoxInstance = await Hive.openBox<AppUser>(_userBox);
    _progressHistoryBoxInstance = await Hive.openBox<ProgressHistory>(_progressHistoryBox);
  }

  // === PROJECT METHODS ===

  Future<List<Project>> getProjects() async {
    return _projectsBoxInstance.values.toList();
  }

  Future<Project?> getProject(String projectId) async {
    return _projectsBoxInstance.get(projectId);
  }

  Future<void> saveProject(Project project) async {
    await _projectsBoxInstance.put(project.id, project);
  }

  Future<void> saveProjects(List<Project> projects) async {
    final Map<String, Project> projectsMap = {
      for (var project in projects) project.id: project
    };
    await _projectsBoxInstance.putAll(projectsMap);
  }

  Future<void> deleteProject(String projectId) async {
    await _projectsBoxInstance.delete(projectId);
  }

  // === TASK METHODS ===

  Future<List<Task>> getTasks() async {
    return _tasksBoxInstance.values.toList();
  }

  Future<Task?> getTask(String taskId) async {
    return _tasksBoxInstance.get(taskId);
  }

  Future<void> saveTask(Task task) async {
    await _tasksBoxInstance.put(task.id, task);

    // Рекурсивно сохраняем подзадачи
    for (final subtask in task.subtasks) {
      await saveTask(subtask);
    }
  }

  Future<void> saveTasks(List<Task> tasks) async {
    for (final task in tasks) {
      await saveTask(task);
    }
  }

  Future<void> deleteTask(String taskId) async {
    final task = await getTask(taskId);
    if (task != null) {
      // Рекурсивно удаляем подзадачи
      for (final subtask in task.subtasks) {
        await deleteTask(subtask.id);
      }
      await _tasksBoxInstance.delete(taskId);
    }
  }

  // Получение всех задач проекта (включая подзадачи)
  Future<List<Task>> getProjectTasks(String projectId) async {
    final allTasks = await getTasks();
    return allTasks.where((task) => task.projectId == projectId).toList();
  }

  // === USER METHODS ===

  Future<AppUser?> getUser() async {
    return _userBoxInstance.get('current_user');
  }

  Future<void> saveUser(AppUser user) async {
    await _userBoxInstance.put('current_user', user);
  }

  Future<void> deleteUser() async {
    await _userBoxInstance.delete('current_user');
  }

  // === PROGRESS HISTORY METHODS ===

  Future<List<ProgressHistory>> getProgressHistory() async {
    return _progressHistoryBoxInstance.values.toList();
  }

  Future<void> saveProgressHistory(ProgressHistory history) async {
    await _progressHistoryBoxInstance.put(history.id, history);
  }

  Future<void> saveProgressHistoryList(List<ProgressHistory> historyList) async {
    final Map<String, ProgressHistory> historyMap = {
      for (var history in historyList) history.id: history
    };
    await _progressHistoryBoxInstance.putAll(historyMap);
  }

  Future<void> deleteProgressHistory(String historyId) async {
    await _progressHistoryBoxInstance.delete(historyId);
  }

  // Получение истории прогресса для задачи
  Future<List<ProgressHistory>> getTaskProgressHistory(String taskId) async {
    final allHistory = await getProgressHistory();
    return allHistory.where((history) => history.taskId == taskId).toList();
  }

  // === MIGRATION METHODS ===

  Future<void> clearAllData() async {
    await _projectsBoxInstance.clear();
    await _tasksBoxInstance.clear();
    await _userBoxInstance.clear();
    await _progressHistoryBoxInstance.clear();
  }

  Future<void> close() async {
    await _projectsBoxInstance.close();
    await _tasksBoxInstance.close();
    await _userBoxInstance.close();
    await _progressHistoryBoxInstance.close();
  }

  // Проверка наличия данных
  bool hasData() {
    return _projectsBoxInstance.isNotEmpty ||
        _tasksBoxInstance.isNotEmpty ||
        _userBoxInstance.isNotEmpty;
  }

  // Получение статистики
  Map<String, int> getStats() {
    return {
      'projects': _projectsBoxInstance.length,
      'tasks': _tasksBoxInstance.length,
      'progressHistory': _progressHistoryBoxInstance.length,
    };
  }
}