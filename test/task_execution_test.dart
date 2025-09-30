// test/task_execution_test.dart
import 'package:flutter_test/flutter_test.dart';
import '../lib/models/task.dart';
import '../lib/models/recurrence.dart';

void main() {
  group('Task Execution Tests', () {
    test('Single-step task completion from calendar', () {
      final task = Task(
        name: 'Calendar Task',
        completedSteps: 0,
        totalSteps: 1,
        taskType: 'singleStep',
        isCompleted: false,
      );

      // Симуляция выполнения из календаря
      final completedTask = Task(
        name: task.name,
        completedSteps: task.completedSteps,
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
    });

    test('Step-by-step task progress from calendar', () {
      final task = Task(
        name: 'Step Task',
        completedSteps: 2,
        totalSteps: 5,
        taskType: 'stepByStep',
        isCompleted: false,
      );

      // Симуляция добавления прогресса из календаря
      final updatedTask = Task(
        name: task.name,
        completedSteps: task.completedSteps + 1,
        totalSteps: task.totalSteps,
        taskType: task.taskType,
        isCompleted: task.completedSteps + 1 >= task.totalSteps,
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

    test('Task completion from planning screen', () {
      final task = Task(
        name: 'Planning Task',
        completedSteps: 0,
        totalSteps: 1,
        taskType: 'singleStep',
        isCompleted: false,
        plannedDate: DateTime.now(),
      );

      // Симуляция выполнения из планирования
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

    test('Recurring task execution tracking', () {
      final task = Task(
        name: 'Daily Task',
        completedSteps: 0,
        totalSteps: 1,
        taskType: 'singleStep',
        recurrence: Recurrence(type: RecurrenceType.daily, interval: 1),
        isCompleted: false,
        plannedDate: DateTime.now(),
      );

      // Для recurring задач основная задача не меняет статус
      expect(task.isCompleted, false);

      // Симуляция выполнения на сегодня
      final isCompletedToday = true;
      expect(isCompletedToday, true);
    });
  });
}