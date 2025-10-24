// lib/services/storage_service.dart
import '../models/project.dart';

abstract class StorageService {
  Future<void> init();
  Future<void> saveProjects(List<Project> projects);
  Future<List<Project>> loadProjects();
  Future<void> clear();
  Future<void> close();
}