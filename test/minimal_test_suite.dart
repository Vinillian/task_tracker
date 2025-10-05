import 'package:flutter_test/flutter_test.dart';
import 'package:task_tracker/models/task.dart';
import 'package:task_tracker/models/project.dart';
import 'package:task_tracker/models/task_type.dart';

void main() {
  group('Minimal Test Suite - Core Models', () {
    test('Task model basic functionality', () {
      final task = Task(
        id: '1',
        title: 'Test Task',
        description: 'Test Description',
      );

      expect(task.title, 'Test Task');
      expect(task.isCompleted, false);
      expect(task.progress, 0.0);

      final completedTask = task.copyWith(isCompleted: true);
      expect(completedTask.isCompleted, true);
      expect(completedTask.progress, 1.0);
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

    test('Project progress with tasks', () {
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

    test('Step-by-step task progress', () {
      final stepTask = Task(
        id: '1',
        title: 'Step Task',
        description: 'Test Description',
        type: TaskType.stepByStep,
        totalSteps: 5,
        completedSteps: 3,
      );

      expect(stepTask.progress, 0.6); // 3/5 = 60%
    });

    test('Task depth calculation', () {
      final flatTask = Task(id: '1', title: 'Flat Task', description: '');
      expect(flatTask.calculateDepth(), 0);

      final nestedTask = Task(
        id: '1',
        title: 'Parent Task',
        description: '',
        subTasks: [
          Task(id: '1-1', title: 'Child Task', description: ''),
        ],
      );
      expect(nestedTask.calculateDepth(), 1);
    });
  });
}