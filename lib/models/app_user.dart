import 'project.dart';
import 'progress_history.dart';

class AppUser {
  String name;
  List<Project> projects;
  List<dynamic> progressHistory;

  AppUser({
    required this.name,
    required this.projects,
    required this.progressHistory,
  });

  Map<String, dynamic> toFirestore() {
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

  static AppUser fromFirestore(Map<String, dynamic> data) {
    return AppUser(
      name: data['name'] ?? '',
      projects: (data['projects'] as List<dynamic>?)
          ?.map((p) => Project.fromFirestore(Map<String, dynamic>.from(p)))
          .toList() ?? [],
      progressHistory: data['progressHistory'] ?? [],
    );
  }

  static AppUser empty() => AppUser(name: '', projects: [], progressHistory: []);
}