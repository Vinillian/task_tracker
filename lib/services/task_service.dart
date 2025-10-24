// services/task_service.dart
import '../models/task.dart';
import '../models/task_type.dart';
import '../utils/logger.dart';
import 'hive_storage_service.dart';

class TaskService {
  final List<Task> _tasks = [];
  final HiveStorageService? _storageService;

  // ✅ Кэш для улучшения производительности
  final Map<String, List<Task>> _projectTasksCache = {};
  final Map<String, double> _progressCache = {};
  bool _isCacheDirty = true;

  TaskService([this._storageService]); // ✅ ДОБАВИТЬ конструктор

  void _invalidateCache() {
    _isCacheDirty = true;
    _projectTasksCache.clear();
    _progressCache.clear();
  }

  // ✅ ОБНОВЛЕННЫЕ методы с сохранением в хранилище
  void addTask(Task task) {
    _invalidateCache();
    _tasks.add(task);
    _saveTasksToStorage(); // ✅ ДОБАВИТЬ сохранение
  }

  void removeTask(String taskId) {
    _invalidateCache();
    _tasks.removeWhere((t) => t.id == taskId);
    _saveTasksToStorage(); // ✅ ДОБАВИТЬ сохранение
  }

  // Добавить в класс TaskService в task_service.dart
  List<Task> getTasksForDate(DateTime date) {
    return _tasks.where((task) {
      if (task.dueDate == null) return false;
      return _isSameDay(task.dueDate!, date);
    }).toList();
  }

  // Добавить в класс TaskService в task_service.dart
  List<Task> getOverdueTasks(DateTime currentDate) {
    return _tasks.where((task) {
      if (task.dueDate == null || task.isCompleted) return false;
      return task.dueDate!.isBefore(DateTime(
        currentDate.year,
        currentDate.month,
        currentDate.day,
      ));
    }).toList();
  }

  // Добавить в класс TaskService в task_service.dart
  void moveTaskToNextDay(Task task) {
    if (task.dueDate != null) {
      final updatedTask = task.copyWith(
        dueDate: task.dueDate!.add(const Duration(days: 1)),
        updatedAt: DateTime.now(),
      );
      updateTask(updatedTask);
    }
  }

  // Добавить в класс TaskService в task_service.dart
  void resetRecurringTasks(DateTime today) {
    for (final task in _tasks) {
      if (task.isRecurring &&
          task.lastCompletedDate != null &&
          !_isSameDay(task.lastCompletedDate!, today)) {
        final updatedTask = task.copyWith(
          isCompleted: false,
          completedSteps: 0,
          updatedAt: DateTime.now(),
        );
        updateTask(updatedTask);
      }
    }
  }

  // Добавить в класс TaskService в task_service.dart
  Map<int, int> getTasksByPriority(String projectId) {
    final projectTasks = getProjectTasks(projectId);
    final result = <int, int>{0: 0, 1: 0, 2: 0};

    for (final task in projectTasks) {
      final priority = task.priority ?? 1;
      result[priority] = (result[priority] ?? 0) + 1;
    }

    return result;
  }

  // Добавить в класс TaskService в task_service.dart
  Map<DateTime, int> getCompletionCountByDate() {
    final result = <DateTime, int>{};

    for (final task in _tasks) {
      if (task.isCompleted && task.lastCompletedDate != null) {
        final date = DateTime(
          task.lastCompletedDate!.year,
          task.lastCompletedDate!.month,
          task.lastCompletedDate!.day,
        );
        result[date] = (result[date] ?? 0) + 1;
      }
    }

    return result;
  }

  // Добавить в класс TaskService в task_service.dart (в конец класса)
  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

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
      // ✅ ИСПРАВЛЕНО: передаем ID подзадачи, а не родительской задачи
      allSubTasks.addAll(getAllSubTasks(subTask.id));
    }

    return allSubTasks;
  }

  List<Task> getAllProjectTasks(String projectId) {
    final rootTasks =
        getProjectTasks(projectId).where((t) => t.parentId == null);
    final allTasks = <Task>[];

    for (final rootTask in rootTasks) {
      allTasks.add(rootTask);
      allTasks.addAll(getAllSubTasks(rootTask.id));
    }

    return allTasks;
  }

  double getProjectProgress(String projectId) {
    // ✅ Используем кэш если данные актуальны
    if (!_isCacheDirty && _progressCache.containsKey(projectId)) {
      return _progressCache[projectId]!;
    }

    final allTasks = getAllProjectTasks(projectId);
    if (allTasks.isEmpty) {
      _progressCache[projectId] = 0.0;
      return 0.0;
    }

    final completedCount = allTasks.where((t) => t.isCompleted).length;
    final progress = completedCount / allTasks.length;

    _progressCache[projectId] = progress;
    _isCacheDirty = false;
    return progress;
  }

  int getProjectTotalTasks(String projectId) =>
      getAllProjectTasks(projectId).length;

  int getProjectCompletedTasks(String projectId) =>
      getAllProjectTasks(projectId).where((t) => t.isCompleted).length;

  void updateTask(Task updatedTask) {
    _invalidateCache();
    final index = _tasks.indexWhere((t) => t.id == updatedTask.id);
    if (index != -1) {
      _tasks[index] =
          updatedTask.copyWith(updatedAt: DateTime.now()); // ✅ Важно!
    }
    _saveTasksToStorage();
  }

  bool canAddSubTask(String parentId, {int maxDepth = 5}) {
    return _calculateTaskDepth(parentId) < maxDepth;
  }

  int _calculateTaskDepth(String taskId, {int currentDepth = 0}) {
    final subTasks = getSubTasks(taskId);
    if (subTasks.isEmpty) return currentDepth;

    final depths = subTasks
        .map((t) => _calculateTaskDepth(t.id, currentDepth: currentDepth + 1));
    return depths.reduce((a, b) => a > b ? a : b);
  }

  Task? getTaskById(String taskId) {
    return _tasks.firstWhere((task) => task.id == taskId,
        orElse: () => throw Exception('Task not found'));
  }

  List<Task> getRootTasks(String projectId) {
    return _tasks
        .where((task) => task.projectId == projectId && task.parentId == null)
        .toList();
  }

  void updateTaskCompletion(String taskId, bool isCompleted) {
    final task = getTaskById(taskId);
    if (task != null) {
      final updatedTask = task.copyWith(isCompleted: isCompleted);
      updateTask(updatedTask);
    }
  }

  void clearAllTasks() {
    _invalidateCache();
    _tasks.clear();
    _saveTasksToStorage(); // ✅ ДОБАВИТЬ сохранение
  }

  List<Task> getAllTasks() {
    return List.from(_tasks);
  }

  void loadDemoTasks(String projectId) {
    _invalidateCache();
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

    _saveTasksToStorage(); // ✅ ДОБАВИТЬ сохранение
    Logger.success(
        'Загружено демо-задач для проекта $projectId: ${getProjectTotalTasks(projectId)}');
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
    _invalidateCache();
    _tasks.removeWhere((task) => task.projectId == projectId);
    _saveTasksToStorage(); // ✅ ДОБАВИТЬ сохранение
  }

  // ✅ Методы для работы с Hive хранилищем
  Future<void> loadTasksFromStorage() async {
    if (_storageService != null) {
      try {
        final savedTasks = await _storageService!.loadTasks();
        _tasks.clear();
        _tasks.addAll(savedTasks);
        _invalidateCache();
      } catch (e) {
        Logger.error('Ошибка загрузки задач из Hive', e);
        // Продолжаем работу с пустым списком задач
      }
    }
  }

  Future<void> _saveTasksToStorage() async {
    if (_storageService != null) {
      try {
        await _storageService!.saveTasks(_tasks);
      } catch (e) {
        Logger.error('Ошибка сохранения задач в Hive', e);
        // Продолжаем работу без сохранения
      }
    }
  }
}
