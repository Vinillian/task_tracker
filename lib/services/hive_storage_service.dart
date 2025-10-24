// lib/services/hive_storage_service.dart
import 'package:hive_flutter/hive_flutter.dart';
import '../models/project.dart';
import '../models/task.dart';
import '../models/task_type.dart'; // ✅ Импортируем для регистрации адаптера
import 'storage_service.dart';

class HiveStorageService implements StorageService {
  static const String _projectsBoxName = 'projects';
  static const String _tasksBoxName = 'tasks';

  late Box<Project> _projectsBox;
  late Box<Task> _tasksBox;

  @override
  Future<void> init() async {
    await Hive.initFlutter();

    // ✅ Регистрируем ВСЕ адаптеры включая TaskType
    Hive.registerAdapter(ProjectAdapter());
    Hive.registerAdapter(TaskAdapter());
    Hive.registerAdapter(TaskTypeAdapter()); // ✅ Теперь этот адаптер существует!

    // Открываем Box'ы
    _projectsBox = await Hive.openBox<Project>(_projectsBoxName);
    _tasksBox = await Hive.openBox<Task>(_tasksBoxName);
  }

  @override
  Future<void> saveProjects(List<Project> projects) async {
    await _projectsBox.clear();

    for (final project in projects) {
      await _projectsBox.put(project.id, project);
    }
  }

  @override
  Future<List<Project>> loadProjects() async {
    return _projectsBox.values.toList();
  }

  // ✅ ДОБАВИТЬ методы для работы с задачами
  Future<void> saveTasks(List<Task> tasks) async {
    await _tasksBox.clear();

    for (final task in tasks) {
      await _tasksBox.put(task.id, task);
    }
  }

  Future<List<Task>> loadTasks() async {
    return _tasksBox.values.toList();
  }

  @override
  Future<void> clear() async {
    await _projectsBox.clear();
    await _tasksBox.clear();
  }

  @override
  Future<void> close() async {
    await _projectsBox.close();
    await _tasksBox.close();
  }
}