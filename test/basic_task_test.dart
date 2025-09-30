// test/basic_task_test.dart
import 'package:flutter_test/flutter_test.dart';
import '../lib/models/task.dart';
import '../lib/models/project.dart';
import '../lib/models/recurrence.dart';

void main() {
  group('Basic Task Tests', () {
    test('Task creation and properties', () {
      final task = Task(
        name: 'Test Task',
        completedSteps: 0,
        totalSteps: 5,
        taskType: 'stepByStep',
        isCompleted: false,
      );

      expect(task.name, 'Test Task');
      expect(task.completedSteps, 0);
      expect(task.totalSteps, 5);
      expect(task.taskType, 'stepByStep');
      expect(task.isCompleted, false);
    });

    test('Single-step task creation', () {
      final task = Task(
        name: 'Single Task',
        completedSteps: 0,
        totalSteps: 1,
        taskType: 'singleStep',
        isCompleted: false,
      );

      expect(task.name, 'Single Task');
      expect(task.taskType, 'singleStep');
      expect(task.totalSteps, 1);
    });

    test('Task with recurrence', () {
      final recurrence = Recurrence(
        type: RecurrenceType.daily,
        interval: 1,
      );

      final task = Task(
        name: 'Recurring Task',
        completedSteps: 0,
        totalSteps: 1,
        taskType: 'singleStep',
        recurrence: recurrence,
        isCompleted: false,
      );

      expect(task.recurrence?.type, RecurrenceType.daily);
      expect(task.recurrence?.interval, 1);
    });

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

  group('Task Completion Logic', () {
    test('Single-step task completion', () {
      final task = Task(
        name: 'Complete Me',
        completedSteps: 0,
        totalSteps: 1,
        taskType: 'singleStep',
        isCompleted: false,
      );

      // Симуляция выполнения
      final completedTask = Task(
        name: task.name,
        completedSteps: 1,
        totalSteps: task.totalSteps,
        taskType: task.taskType,
        isCompleted: true,
        stages: task.stages,
        recurrence: task.recurrence,
        dueDate: task.dueDate,
        description: task.description,
        plannedDate: task.plannedDate,
        colorValue: task.colorValue,
        isTracked: task.isTracked,
      );

      expect(completedTask.isCompleted, true);
      expect(completedTask.completedSteps, 1);
    });

    test('Step-by-step task progress', () {
      final task = Task(
        name: 'Step Task',
        completedSteps: 2,
        totalSteps: 5,
        taskType: 'stepByStep',
        isCompleted: false,
      );

      // Симуляция добавления прогресса
      final updatedTask = Task(
        name: task.name,
        completedSteps: task.completedSteps + 1,
        totalSteps: task.totalSteps,
        taskType: task.taskType,
        isCompleted: (task.completedSteps + 1) >= task.totalSteps,
        stages: task.stages,
        recurrence: task.recurrence,
        dueDate: task.dueDate,
        description: task.description,
        plannedDate: task.plannedDate,
        colorValue: task.colorValue,
        isTracked: task.isTracked,
      );

      expect(updatedTask.completedSteps, 3);
      expect(updatedTask.isCompleted, false);
    });
  });
}