// test/test_helper.dart
import 'package:task_tracker/models/project.dart';
import 'package:task_tracker/models/task.dart';

// Вспомогательные функции для тестов
Project createTestProject({String id = '1', String name = 'Test Project', int taskCount = 2}) {
  final tasks = List<Task>.generate(taskCount, (index) => Task(
    id: '$id-$index',
    title: 'Task $index',
    description: 'Task Description $index',
    isCompleted: index.isEven, // Четные задачи выполнены
  ));

  return Project(
    id: id,
    name: name,
    description: 'Test Description',
    tasks: tasks,
    createdAt: DateTime.now(),
  );
}

Task createTestTask({
  String id = '1',
  String title = 'Test Task',
  bool isCompleted = false,
  int subTaskCount = 0,
}) {
  final subTasks = List<Task>.generate(subTaskCount, (index) => Task(
    id: '$id-$index',
    title: 'Sub Task $index',
    description: 'Sub Task Description',
  ));

  return Task(
    id: id,
    title: title,
    description: 'Test Description',
    isCompleted: isCompleted,
    subTasks: subTasks,
  );
}