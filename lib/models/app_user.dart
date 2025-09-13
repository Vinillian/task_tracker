import 'project.dart';
import 'progress_history.dart';

class AppUser {
  String username;  // ← изменено с name на username
  String email;     // ← новое поле
  List<Project> projects;
  List<dynamic> progressHistory;

  AppUser({
    required this.username,  // ← изменено
    required this.email,     // ← добавлено
    required this.projects,
    required this.progressHistory,
  });

  Map<String, dynamic> toFirestore() {
    final migratedHistory = progressHistory.map((item) {
      if (item is ProgressHistory) {
        return item.toFirestore();
      }
      return item;
    }).toList();

    return {
      'username': username,  // ← изменено
      'email': email,        // ← добавлено
      'projects': projects.map((p) => p.toFirestore()).toList(),
      'progressHistory': migratedHistory,
    };
  }

  static AppUser fromFirestore(Map<String, dynamic> data) {
    return AppUser(
      username: data['username'] ?? '',  // ← изменено
      email: data['email'] ?? '',        // ← добавлено
      projects: (data['projects'] as List<dynamic>?)
          ?.map((p) => Project.fromFirestore(Map<String, dynamic>.from(p)))
          .toList() ?? [],
      progressHistory: data['progressHistory'] ?? [],
    );
  }

  static AppUser empty() => AppUser(
      username: '',
      email: '',
      projects: [],
      progressHistory: []
  );
}