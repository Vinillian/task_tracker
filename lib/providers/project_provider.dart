import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/project.dart';
import '../services/hive_storage_service.dart';
import '../utils/logger.dart';

final storageServiceProvider = Provider<HiveStorageService>((ref) {
  throw UnimplementedError('StorageService should be overridden in main.dart');
});

final projectsProvider = StateNotifierProvider<ProjectNotifier, List<Project>>((ref) {
  final storageService = ref.watch(storageServiceProvider);
  return ProjectNotifier(storageService);
});

class ProjectNotifier extends StateNotifier<List<Project>> {
  final HiveStorageService _storageService;

  ProjectNotifier(this._storageService) : super([]);

  Future<void> loadProjects() async {
    try {
      final savedProjects = await _storageService.loadProjects();
      if (savedProjects.isNotEmpty) {
        state = savedProjects;
        Logger.success('Проекты загружены из Hive');
      }
    } catch (e) {
      Logger.error('Ошибка загрузки проектов из Hive', e);
    }
  }

  void addProject(Project project) {
    state = [...state, project];
    _saveProjects();
  }

  void updateProject(int index, Project updatedProject) {
    final updatedProjects = List<Project>.from(state);
    updatedProjects[index] = updatedProject;
    state = updatedProjects;
    _saveProjects();
  }

  void clearAllProjects() {
    state = [];
    _storageService.clear();
  }

  Future<void> _saveProjects() async {
    try {
      await _storageService.saveProjects(state);
    } catch (e) {
      Logger.error('Ошибка сохранения проектов в Hive', e);
    }
  }
}