import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/project.dart';
import '../utils/storage_helper.dart';
import '../utils/logger.dart';

final projectsProvider = StateNotifierProvider<ProjectNotifier, List<Project>>((ref) {
  return ProjectNotifier();
});

class ProjectNotifier extends StateNotifier<List<Project>> {
  ProjectNotifier() : super([]);

  Future<void> loadProjects() async {
    try {
      final savedProjects = await StorageHelper.loadProjects();
      if (savedProjects.isNotEmpty) {
        final projects = savedProjects.map((projectData) => Project.fromJson(projectData)).toList();
        state = projects;
      }
    } catch (e) {
      Logger.error('Ошибка загрузки проектов', e);
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
    StorageHelper.clearData();
  }

  Future<void> _saveProjects() async {
    final projectsData = state.map((project) => project.toJson()).toList();
    await StorageHelper.saveProjects(projectsData);
  }
}