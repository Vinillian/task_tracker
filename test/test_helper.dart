import 'package:task_tracker/models/project.dart';
import 'package:task_tracker/models/task.dart';

// Вспомогательные функции для тестов (обновленные для плоской структуры)
Project createTestProject({String id = '1', String name = 'Test Project'}) {
  return Project(
    id: id,
    name: name,
    description: 'Test Description',
    createdAt: DateTime.now(),
  );
}

Task createTestTask({
  String id = '1',
  String projectId = 'project_1',
  String title = 'Test Task',
  bool isCompleted = false,
}) {
  return Task(
    id: id,
    projectId: projectId,
    title: title,
    description: 'Test Description',
    isCompleted: isCompleted,
  );
}