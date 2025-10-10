import 'package:flutter_test/flutter_test.dart';
import 'package:task_tracker/models/task.dart';
import 'package:task_tracker/models/project.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Basic Smoke Tests - Flat Structure', () {
    test('Task model basic functionality', () {
      final task = Task(
        id: '1',
        projectId: 'project_1',
        title: 'Test Task',
        description: 'Test Description',
      );

      expect(task.title, 'Test Task');
      expect(task.isCompleted, false);
      expect(task.projectId, 'project_1');

      final completedTask = task.copyWith(isCompleted: true);
      expect(completedTask.isCompleted, true);
    });

    test('Project model basic functionality', () {
      final project = Project(
        id: '1',
        name: 'Test Project',
        description: 'Test Description',
        createdAt: DateTime.now(),
      );

      expect(project.name, 'Test Project');
      expect(project.progress, 0.0); // Temporary stub
      expect(project.totalTasks, 0); // Temporary stub
    });
  });
}