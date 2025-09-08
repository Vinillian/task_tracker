import 'task.dart';

class Project {
  String name;
  List<Task> tasks;

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
