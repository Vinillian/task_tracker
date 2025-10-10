import 'package:flutter_test/flutter_test.dart';
import 'package:task_tracker/models/task.dart';
import 'package:task_tracker/models/task_type.dart';

void main() {
  group('Task Model Tests - Flat Structure', () {
    test('Task creation with parentId', () {
      final task = Task(
        id: '1',
        parentId: 'parent_1',
        projectId: 'project_1',
        title: 'Test Task',
        description: 'Test Description',
      );

      expect(task.id, '1');
      expect(task.parentId, 'parent_1');
      expect(task.projectId, 'project_1');
      expect(task.title, 'Test Task');
    });

    test('Task progress calculation for single task', () {
      final incompleteTask = Task(
        id: '1',
        projectId: 'project_1',
        title: 'Incomplete Task',
        description: '',
        isCompleted: false,
      );

      final completeTask = Task(
        id: '2',
        projectId: 'project_1',
        title: 'Complete Task',
        description: '',
        isCompleted: true,
      );

      expect(incompleteTask.progress, 0.0);
      expect(completeTask.progress, 1.0);
    });

    test('Task progress calculation for step-by-step task', () {
      final stepTask = Task(
        id: '1',
        projectId: 'project_1',
        title: 'Step Task',
        description: '',
        type: TaskType.stepByStep,
        totalSteps: 5,
        completedSteps: 3,
      );

      expect(stepTask.progress, 0.6); // 3/5 = 60%
    });

    test('Task JSON serialization', () {
      final task = Task(
        id: '1',
        parentId: 'parent_1',
        projectId: 'project_1',
        title: 'Test Task',
        description: 'Test Description',
        type: TaskType.stepByStep,
        totalSteps: 5,
        completedSteps: 2,
      );

      final json = task.toJson();
      final deserialized = Task.fromJson(json);

      expect(deserialized.id, '1');
      expect(deserialized.parentId, 'parent_1');
      expect(deserialized.projectId, 'project_1');
      expect(deserialized.title, 'Test Task');
      expect(deserialized.type, TaskType.stepByStep);
      expect(deserialized.totalSteps, 5);
      expect(deserialized.completedSteps, 2);
    });
  });
}