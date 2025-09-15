import 'task.dart';

import 'package:hive/hive.dart';
part 'project.g.dart';

@HiveType(typeId: 1)
class Project {
  @HiveField(0)
  final String name;

  @HiveField(1)
  final List<Task> tasks;

  Project({required this.name, required this.tasks});

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'tasks': tasks.map((t) => t.toFirestore()).toList(),
    };
  }

  static Project fromFirestore(Map<String, dynamic> data) {
    return Project(
      name: data['name'] ?? '',
      tasks: (data['tasks'] as List<dynamic>?)
          ?.map((t) => Task.fromFirestore(t))
          .toList() ??
          [],
    );
  }
}