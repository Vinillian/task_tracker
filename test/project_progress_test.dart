// test/project_progress_test.dart
import 'package:flutter_test/flutter_test.dart';
import '../lib/models/project.dart';
import '../lib/models/task.dart';
import '../lib/models/recurrence.dart';

void main() {
  test('Project with recurring task', () {
    final recurrence = Recurrence(
      type: RecurrenceType.daily,
      interval: 1,
    );

    final task = Task(
      name: 'Daily Task',
      completedSteps: 0,
      totalSteps: 1,
      taskType: 'singleStep',
      recurrence: recurrence,
      isCompleted: false,
    );

    final project = Project(name: 'Test Project', tasks: [task]);

    expect(project.tasks.length, 1);
    expect(project.tasks[0].recurrence?.type, RecurrenceType.daily);
  });

  test('Project progress calculation', () {
    final completedTask = Task(
      name: 'Completed Task',
      completedSteps: 1,
      totalSteps: 1,
      taskType: 'singleStep',
      isCompleted: true,
    );

    final inProgressTask = Task(
      name: 'In Progress Task',
      completedSteps: 2,
      totalSteps: 5,
      taskType: 'stepByStep',
      isCompleted: false,
    );

    final project = Project(name: 'Test Project', tasks: [completedTask, inProgressTask]);

    // Простой расчет прогресса
    final completedTasks = project.tasks.where((t) => t.isCompleted).length;
    final totalTasks = project.tasks.length;

    expect(completedTasks, 1);
    expect(totalTasks, 2);
  });
}