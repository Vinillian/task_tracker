import 'project.dart';
import 'progress_history.dart';

class AppUser {
  String username;
  String email;
  List<Project> projects;
  List<dynamic> progressHistory;

  AppUser({
    required this.username,
    required this.email,
    required this.projects,
    required this.progressHistory,
  });

  // В models/app_user.dart
  Map<String, dynamic> toFirestore() {
    final migratedHistory = progressHistory.map((item) {
      if (item is ProgressHistory) {
        return item.toFirestore();
      }
      return item;
    }).toList();

    return {
      'username': username,
      'email': email,
      'projects': projects.map((p) => p.toFirestore()).toList(),
      'progressHistory': migratedHistory,
    };
  }

  static AppUser fromFirestore(Map<String, dynamic> data) {
    print('📥 Загружаем данные пользователя: ${data['username'] ?? 'неизвестно'}');

    // Обработка проектов
    List<Project> projects = [];
    if (data['projects'] != null && data['projects'] is List) {
      try {
        projects = (data['projects'] as List).map<Project>((p) {
          if (p is Map<String, dynamic>) {
            return Project.fromFirestore(p);
          } else if (p is Project) {
            return p;
          } else {
            return Project(name: 'Неизвестный проект', tasks: []);
          }
        }).toList();
      } catch (e) {
        print('Ошибка при загрузке проектов: $e');
        projects = [];
      }
    }

    // Обработка истории прогресса
    List<dynamic> progressHistory = [];
    if (data['progressHistory'] != null && data['progressHistory'] is List) {
      progressHistory = (data['progressHistory'] as List).map((item) {
        try {
          if (item is Map<String, dynamic>) {
            return ProgressHistory.fromFirestore(item);
          } else {
            return item;
          }
        } catch (e) {
          print('Ошибка при загрузке истории: $e');
          return item;
        }
      }).toList();
    }

    print('✅ Загружено ${projects.length} проектов и ${progressHistory.length} записей истории');

    return AppUser(
      username: data['username']?.toString() ?? '',
      email: data['email']?.toString() ?? '',
      projects: projects,
      progressHistory: progressHistory,
    );
  }

  static AppUser empty() => AppUser(
    username: '',
    email: '',
    projects: <Project>[],
    progressHistory: [],
  );
}