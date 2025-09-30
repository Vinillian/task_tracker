// test/basic_smoke_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:task_tracker/models/task.dart';
import 'package:task_tracker/models/project.dart';

void main() {
  // Инициализируем binding для тестов
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Basic Smoke Tests', () {
    test('Task model basic functionality', () {
      final task = Task(
        id: '1',
        title: 'Test Task',
        description: 'Test Description',
      );

      expect(task.title, 'Test Task');
      expect(task.isCompleted, false);

      final completedTask = task.copyWith(isCompleted: true);
      expect(completedTask.isCompleted, true);
    });

    test('Project model basic functionality', () {
      final project = Project(
        id: '1',
        name: 'Test Project',
        description: 'Test Description',
        tasks: [],
        createdAt: DateTime.now(),
      );

      expect(project.name, 'Test Project');
      expect(project.progress, 0.0);
      expect(project.totalTasks, 0);
    });

    test('Project with tasks progress calculation', () {
      final task1 = Task(id: '1', title: 'Task 1', description: '', isCompleted: true);
      final task2 = Task(id: '2', title: 'Task 2', description: '', isCompleted: false);

      final project = Project(
        id: '1',
        name: 'Test Project',
        description: 'Test Description',
        tasks: [task1, task2],
        createdAt: DateTime.now(),
      );

      expect(project.totalTasks, 2);
      expect(project.completedTasks, 1);
      expect(project.progress, 0.5);
    });
  });
}