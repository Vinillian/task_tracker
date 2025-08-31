import 'task.dart';

class Project {
  String name;
  List<Task> tasks;

  Project({required this.name, required this.tasks});

  Map<String, dynamic> toJson() => {
    'name': name,
    'tasks': tasks.map((t) => t.toJson()).toList(),
  };

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      name: json['name'],
      tasks: (json['tasks'] as List).map((t) => Task.fromJson(t)).toList(),
    );
  }
}