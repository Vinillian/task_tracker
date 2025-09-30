// test/models/project_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:task_tracker/models/project.dart';
import 'package:task_tracker/models/task.dart';

void main() {
  group('Project Model Tests', () {
    test('Project creation and basic properties', () {
      final project = Project(
        id: '1',
        name: 'Test Project',
        description: 'Test Description',
        tasks: [],
        createdAt: DateTime(2024, 1, 1),
      );

      expect(project.id, '1');
      expect(project.name, 'Test Project');
      expect(project.description, 'Test Description');
      expect(project.tasks, isEmpty);
      expect(project.createdAt, DateTime(2024, 1, 1));
    });

    test('Project progress calculation with no tasks', () {
      final project = Project(
        id: '1',
        name: 'Test Project',
        description: 'Test Description',
        tasks: [],
        createdAt: DateTime.now(),
      );

      expect(project.progress, 0.0);
    });

    test('Project progress calculation with tasks', () {
      final task1 = Task(id: '1', title: 'Task 1', description: '', isCompleted: true);
      final task2 = Task(id: '2', title: 'Task 2', description: '', isCompleted: false);

      final project = Project(
        id: '1',
        name: 'Test Project',
        description: 'Test Description',
        tasks: [task1, task2],
        createdAt: DateTime.now(),
      );

      expect(project.progress, 0.5); // (1.0 + 0.0) / 2 = 0.5
    });

    test('Project task counters', () {
      final completedTask = Task(id: '1', title: 'Completed', description: '', isCompleted: true);
      final pendingTask = Task(id: '2', title: 'Pending', description: '', isCompleted: false);

      final project = Project(
        id: '1',
        name: 'Test Project',
        description: 'Test Description',
        tasks: [completedTask, pendingTask],
        createdAt: DateTime.now(),
      );

      expect(project.totalTasks, 2);
      expect(project.completedTasks, 1);
    });

    test('Project copyWith method', () {
      final original = Project(
        id: '1',
        name: 'Original',
        description: 'Desc',
        tasks: [],
        createdAt: DateTime(2024, 1, 1),
      );

      final updated = original.copyWith(
        name: 'Updated',
        description: 'New Desc',
      );

      expect(updated.id, '1');
      expect(updated.name, 'Updated');
      expect(updated.description, 'New Desc');
      expect(updated.tasks, isEmpty);
      expect(updated.createdAt, DateTime(2024, 1, 1));
    });

    test('Project JSON serialization', () {
      final task = Task(id: '1', title: 'Test Task', description: '');
      final project = Project(
        id: '1',
        name: 'Test Project',
        description: 'Test Description',
        tasks: [task],
        createdAt: DateTime(2024, 1, 1),
      );

      final json = project.toJson();
      final deserialized = Project.fromJson(json);

      expect(deserialized.id, project.id);
      expect(deserialized.name, project.name);
      expect(deserialized.description, project.description);
      expect(deserialized.tasks.length, 1);
      expect(deserialized.tasks[0].title, 'Test Task');
    });
  });
}