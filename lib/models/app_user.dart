import 'project.dart';
import 'progress_history.dart';
// Добавляем аннотацию @HiveType для класса и @HiveField для каждого поля
import 'package:hive/hive.dart';

part 'app_user.g.dart'; // Файл будет сгенерирован автоматически

@HiveType(typeId: 0) // Уникальный ID для типа
class AppUser {
  @HiveField(0)
  final String username;

  @HiveField(1)
  final String email;

  @HiveField(2)
  final List<Project> projects;

  @HiveField(3)
  final List<dynamic> progressHistory;

// ... остальной код класса без изменений ...

  AppUser({
    required this.username,
    required this.email,
    required this.projects,
    required this.progressHistory,
  });

  // В models/app_user.dart
  Map<String, dynamic> toFirestore() {
    // Добавьте проверки на null и пустые значения
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