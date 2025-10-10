// services/task_service.dart
import '../models/task.dart';
import '../models/task_type.dart';
import '../utils/logger.dart';

class TaskService {
  final List<Task> _tasks = [];

  void addTask(Task task) => _tasks.add(task);
  void removeTask(String taskId) => _tasks.removeWhere((t) => t.id == taskId);

  List<Task> getProjectTasks(String projectId) {
    return _tasks.where((task) => task.projectId == projectId).toList();
  }

  List<Task> getSubTasks(String parentId) {
    return _tasks.where((task) => task.parentId == parentId).toList();
  }

  List<Task> getAllSubTasks(String parentId) {
    final allSubTasks = <Task>[];
    final directSubTasks = getSubTasks(parentId);

    for (final subTask in directSubTasks) {
      allSubTasks.add(subTask);
      allSubTasks.addAll(getAllSubTasks(subTask.id));
    }

    return allSubTasks;
  }

  List<Task> getAllProjectTasks(String projectId) {
    final rootTasks = getProjectTasks(projectId).where((t) => t.parentId == null);
    final allTasks = <Task>[];

    for (final rootTask in rootTasks) {
      allTasks.add(rootTask);
      allTasks.addAll(getAllSubTasks(rootTask.id));
    }

    return allTasks;
  }

  double getProjectProgress(String projectId) {
    final allTasks = getAllProjectTasks(projectId);
    if (allTasks.isEmpty) return 0.0;

    final completedCount = allTasks.where((t) => t.isCompleted).length;
    return completedCount / allTasks.length;
  }

  int getProjectTotalTasks(String projectId) => getAllProjectTasks(projectId).length;
  int getProjectCompletedTasks(String projectId) =>
      getAllProjectTasks(projectId).where((t) => t.isCompleted).length;

  void updateTask(Task updatedTask) {
    final index = _tasks.indexWhere((t) => t.id == updatedTask.id);
    if (index != -1) {
      _tasks[index] = updatedTask;
    }
  }

  bool canAddSubTask(String parentId, {int maxDepth = 5}) {
    return _calculateTaskDepth(parentId) < maxDepth;
  }

  int _calculateTaskDepth(String taskId, {int currentDepth = 0}) {
    final subTasks = getSubTasks(taskId);
    if (subTasks.isEmpty) return currentDepth;

    final depths = subTasks.map((t) => _calculateTaskDepth(t.id, currentDepth: currentDepth + 1));
    return depths.reduce((a, b) => a > b ? a : b);
  }

  Task? getTaskById(String taskId) {
    return _tasks.firstWhere((task) => task.id == taskId, orElse: () => throw Exception('Task not found'));
  }

  List<Task> getRootTasks(String projectId) {
    return _tasks.where((task) => task.projectId == projectId && task.parentId == null).toList();
  }

  void updateTaskCompletion(String taskId, bool isCompleted) {
    final task = getTaskById(taskId);
    if (task != null) {
      final updatedTask = task.copyWith(isCompleted: isCompleted);
      updateTask(updatedTask);
    }
  }

  void clearAllTasks() {
    _tasks.clear();
  }

  List<Task> getAllTasks() {
    return List.from(_tasks);
  }

  void loadDemoTasks(String projectId) {
    _tasks.removeWhere((task) => task.projectId == projectId);

    final mainTask1 = Task(
      id: '${projectId}_task_1',
      parentId: null,
      projectId: projectId,
      title: 'Создать отчет',
      description: 'Подготовить еженедельный отчет',
      isCompleted: false,
      type: TaskType.single,
    );
    addTask(mainTask1);

    final subTask1 = Task(
      id: '${projectId}_task_1_1',
      parentId: '${projectId}_task_1',
      projectId: projectId,
      title: 'Собрать данные',
      description: 'Собрать статистику за неделю',
      isCompleted: false,
      type: TaskType.single,
    );
    addTask(subTask1);

    final subTask2 = Task(
      id: '${projectId}_task_1_2',
      parentId: '${projectId}_task_1',
      projectId: projectId,
      title: 'Написать выводы',
      description: 'Проанализировать собранные данные',
      isCompleted: true,
      type: TaskType.single,
    );
    addTask(subTask2);

    final mainTask2 = Task(
      id: '${projectId}_task_2',
      parentId: null,
      projectId: projectId,
      title: 'Изучить Flutter',
      description: 'Пройти обучение по Flutter',
      isCompleted: false,
      type: TaskType.stepByStep,
      totalSteps: 5,
      completedSteps: 2,
    );
    addTask(mainTask2);

    final subTask3 = Task(
      id: '${projectId}_task_2_1',
      parentId: '${projectId}_task_2',
      projectId: projectId,
      title: 'Изучить виджеты',
      description: 'Разобраться с основными виджетами',
      isCompleted: true,
      type: TaskType.single,
    );
    addTask(subTask3);

    Logger.success('Загружено демо-задач для проекта $projectId: ${getProjectTotalTasks(projectId)}');
  }

  bool hasSubTasks(String taskId) {
    return getSubTasks(taskId).isNotEmpty;
  }

  Task? getParentTask(String taskId) {
    final task = getTaskById(taskId);
    if (task?.parentId != null) {
      return getTaskById(task!.parentId!);
    }
    return null;
  }

  void removeProjectTasks(String projectId) {
    _tasks.removeWhere((task) => task.projectId == projectId);
  }
}