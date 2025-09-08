import 'project.dart';
import 'progress_history.dart';

class User {
  String name;
  List<Project> projects;
  List<dynamic> progressHistory;

  User({
    required this.name,
    required this.projects,
    required this.progressHistory,
  });

  Map<String, dynamic> toFirestore() {
    // Принудительная миграция всех данных в Map
    final migratedHistory = progressHistory.map((item) {
      if (item is ProgressHistory) {
        print('Мигрируем ProgressHistory в Map');
        return item.toFirestore();
      }
      return item;
    }).toList();

    return {
      'name': name,
      'projects': projects.map((p) => p.toFirestore()).toList(),
      'progressHistory': migratedHistory,
    };
  }

  static User fromFirestore(Map<String, dynamic> data) {
    return User(
      name: data['name'] ?? '',
      projects: (data['projects'] as List<dynamic>?)
          ?.map((p) => Project.fromFirestore(Map<String, dynamic>.from(p)))
          .toList() ?? [],
      progressHistory: data['progressHistory'] ?? [],
    );
  }

  static User empty() => User(name: '', projects: [], progressHistory: []);
}