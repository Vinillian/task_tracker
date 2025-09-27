// test/task_completion_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'test_helper.dart';

void main() {
  group('Basic Task Tests', () {
    test('Single-step task creation', () {
      final task = Task(
        name: 'Single Step Task',
        completedSteps: 0,
        totalSteps: 1,
        taskType: 'singleStep',
        isCompleted: false,
      );

      expect(task.name, 'Single Step Task');
      expect(task.taskType, 'singleStep');
      expect(task.isCompleted, false);
    });

    test('Step-by-step task creation', () {
      final task = Task(
        name: 'Step Task',
        completedSteps: 2,
        totalSteps: 5,
        taskType: 'stepByStep',
        isCompleted: false,
      );

      expect(task.name, 'Step Task');
      expect(task.taskType, 'stepByStep');
      expect(task.completedSteps, 2);
      expect(task.totalSteps, 5);
    });
  });

  group('Project Integration Tests', () {
    test('Project with tasks', () {
      final task1 = Task(
        name: 'Task 1',
        completedSteps: 0,
        totalSteps: 1,
        taskType: 'singleStep',
        isCompleted: false,
      );

      final task2 = Task(
        name: 'Task 2',
        completedSteps: 3,
        totalSteps: 5,
        taskType: 'stepByStep',
        isCompleted: false,
      );

      final project = Project(name: 'Test Project', tasks: [task1, task2]);

      expect(project.name, 'Test Project');
      expect(project.tasks.length, 2);
      expect(project.tasks[0].name, 'Task 1');
      expect(project.tasks[1].name, 'Task 2');
    });
  });

  // Упрощенные тесты без сложных сервисов
  group('Recurrence Tests', () {
    test('Recurrence creation', () {
      final recurrence = Recurrence(
        type: RecurrenceType.daily,
        interval: 1,
      );

      expect(recurrence.type, RecurrenceType.daily);
      expect(recurrence.interval, 1);
    });

    test('Task with recurrence', () {
      final task = Task(
        name: 'Recurring Task',
        completedSteps: 0,
        totalSteps: 1,
        taskType: 'singleStep',
        recurrence: Recurrence(type: RecurrenceType.daily, interval: 1),
        isCompleted: false,
      );

      expect(task.recurrence?.type, RecurrenceType.daily);
      expect(task.recurrence?.interval, 1);
    });
  });
}