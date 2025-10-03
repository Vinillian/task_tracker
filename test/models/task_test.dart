import 'package:flutter_test/flutter_test.dart';
import 'package:task_tracker/models/task.dart';
import 'package:task_tracker/models/task_type.dart';

void main() {
  group('Task Model Tests - Step Progress', () {
    test('Step-by-step task progress calculation', () {
      final task = Task(
        id: '1',
        title: 'Test Task',
        description: 'Test Description',
        type: TaskType.stepByStep,
        totalSteps: 5,
        completedSteps: 3,
      );

      expect(task.progress, 0.6); // 3/5 = 60%
    });

    test('Step-by-step task with zero steps', () {
      final task = Task(
        id: '1',
        title: 'Test Task',
        description: 'Test Description',
        type: TaskType.stepByStep,
        totalSteps: 0,
        completedSteps: 0,
      );

      expect(task.progress, 0.0); // Should handle division by zero
    });

    test('Single task progress calculation', () {
      final incompleteTask = Task(
        id: '1',
        title: 'Incomplete Task',
        description: 'Test Description',
        type: TaskType.single,
        isCompleted: false,
      );

      final completeTask = Task(
        id: '2',
        title: 'Complete Task',
        description: 'Test Description',
        type: TaskType.single,
        isCompleted: true,
      );

      expect(incompleteTask.progress, 0.0);
      expect(completeTask.progress, 1.0);
    });
  });
}