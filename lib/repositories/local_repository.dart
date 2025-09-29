// lib/repositories/local_repository.dart
import 'package:shared_preferences/shared_preferences.dart';
import '../models/project.dart';
import '../models/task.dart';
import '../models/app_user.dart';

class LocalRepository {
  static const String _projectsKey = 'projects';
  static const String _userKey = 'current_user';

  // User methods
  Future<void> saveUser(AppUser user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, json.encode(user.toJson()));
  }

  Future<AppUser?> loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userString = prefs.getString(_userKey);

    if (userString == null) return null;

    try {
      final userJson = json.decode(userString);
      return AppUser.fromJson(userJson);
    } catch (e) {
      print('Error loading user: $e');
      return null;
    }
  }

  Future<void> init() async {
    // Initialization logic if needed
  }

  // Project methods
  Future<void> saveProjects(List<Project> projects) async {
    final prefs = await SharedPreferences.getInstance();
    final projectsJson = projects.map((p) => p.toJson()).toList();
    await prefs.setString(_projectsKey, json.encode(projectsJson));
  }

  Future<List<Project>> loadProjects() async {
    final prefs = await SharedPreferences.getInstance();
    final projectsString = prefs.getString(_projectsKey);

    if (projectsString == null) {
      return [];
    }

    try {
      final List<dynamic> projectsJson = json.decode(projectsString);
      return projectsJson.map((json) => Project.fromJson(json)).toList();
    } catch (e) {
      print('Error loading projects: $e');
      return [];
    }
  }

  // Utility methods
  Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  Future<void> checkAndRecoverData() async {
    // Data recovery logic
  }

  // Export/Import methods
  Future<String> exportToJson() async {
    final projects = await loadProjects();
    final user = await loadUser();

    final exportData = {
      'user': user?.toJson(),
      'projects': projects.map((p) => p.toJson()).toList(),
      'exportedAt': DateTime.now().millisecondsSinceEpoch,
    };

    return json.encode(exportData);
  }

  Future<void> importFromJson(String jsonString) async {
    try {
      final importData = json.decode(jsonString);

      if (importData['user'] != null) {
        final user = AppUser.fromJson(importData['user']);
        await saveUser(user);
      }

      if (importData['projects'] != null) {
        final projects = (importData['projects'] as List<dynamic>)
            .map((p) => Project.fromJson(p))
            .toList();
        await saveProjects(projects);
      }
    } catch (e) {
      print('Error importing data: $e');
      throw Exception('Failed to import data');
    }
  }
}

// JSON encoding/decoding
import 'dart:convert';