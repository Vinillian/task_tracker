import 'package:flutter_test/flutter_test.dart';
import 'package:task_tracker/models/task.dart';
import 'package:task_tracker/models/project.dart';
import 'package:task_tracker/models/task_type.dart';

void main() {
  group('Minimal Test Suite - Flat Structure', () {
    test('Task model basic functionality', () {
      final task = Task(
        id: '1',
        projectId: 'project_1',
        title: 'Test Task',
        description: 'Test Description',
      );

      expect(task.title, 'Test Task');
      expect(task.isCompleted, false);
      expect(task.progress, 0.0);
      expect(task.projectId, 'project_1');

      final completedTask = task.copyWith(isCompleted: true);
      expect(completedTask.isCompleted, true);
      expect(completedTask.progress, 1.0);
    });

    test('Project model basic functionality', () {
      final project = Project(
        id: '1',
        name: 'Test Project',
        description: 'Test Description',
        createdAt: DateTime.now(),
      );

      expect(project.name, 'Test Project');
      expect(project.progress, 0.0);
      expect(project.totalTasks, 0);
    });

    test('Step-by-step task progress', () {
      final stepTask = Task(
        id: '1',
        projectId: 'project_1',
        title: 'Step Task',
        description: 'Test Description',
        type: TaskType.stepByStep,
        totalSteps: 5,
        completedSteps: 3,
      );

      expect(stepTask.progress, 0.6); // 3/5 = 60%
    });
  });
}