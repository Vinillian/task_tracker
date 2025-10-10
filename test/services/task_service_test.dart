import 'package:flutter_test/flutter_test.dart';
import 'package:task_tracker/models/task.dart';
import 'package:task_tracker/services/task_service.dart';

void main() {
  group('TaskService Tests', () {
    late TaskService taskService;

    setUp(() {
      taskService = TaskService();
    });

    test('Add and retrieve task', () {
      final task = Task(
        id: 'test_1',
        projectId: 'project_1',
        title: 'Test Task',
        description: 'Test Description',
      );

      taskService.addTask(task);
      final tasks = taskService.getProjectTasks('project_1');

      expect(tasks.length, 1);
      expect(tasks[0].title, 'Test Task');
    });

    test('Remove task', () {
      final task = Task(
        id: 'test_1',
        projectId: 'project_1',
        title: 'Test Task',
        description: 'Test Description',
      );

      taskService.addTask(task);
      taskService.removeTask('test_1');
      final tasks = taskService.getProjectTasks('project_1');

      expect(tasks.length, 0);
    });

    test('Get sub tasks', () {
      final parentTask = Task(
        id: 'parent_1',
        projectId: 'project_1',
        title: 'Parent Task',
        description: 'Parent Description',
      );

      final subTask = Task(
        id: 'sub_1',
        parentId: 'parent_1',
        projectId: 'project_1',
        title: 'Sub Task',
        description: 'Sub Description',
      );

      taskService.addTask(parentTask);
      taskService.addTask(subTask);

      final subTasks = taskService.getSubTasks('parent_1');

      expect(subTasks.length, 1);
      expect(subTasks[0].title, 'Sub Task');
    });

    test('Get all project tasks including sub tasks', () {
      final task1 = Task(id: 'task_1', projectId: 'project_1', title: 'Task 1', description: '');
      final task2 = Task(id: 'task_2', projectId: 'project_1', title: 'Task 2', description: '');
      final subTask = Task(id: 'sub_1', parentId: 'task_1', projectId: 'project_1', title: 'Sub Task', description: '');

      taskService.addTask(task1);
      taskService.addTask(task2);
      taskService.addTask(subTask);

      final allTasks = taskService.getAllProjectTasks('project_1');

      expect(allTasks.length, 3);
    });

    test('Project progress calculation', () {
      final completedTask = Task(
        id: 'task_1',
        projectId: 'project_1',
        title: 'Completed Task',
        description: '',
        isCompleted: true,
      );

      final pendingTask = Task(
        id: 'task_2',
        projectId: 'project_1',
        title: 'Pending Task',
        description: '',
        isCompleted: false,
      );

      taskService.addTask(completedTask);
      taskService.addTask(pendingTask);

      final progress = taskService.getProjectProgress('project_1');

      expect(progress, 0.5); // 1 completed out of 2 tasks
    });

    test('Update task', () {
      final task = Task(
        id: 'task_1',
        projectId: 'project_1',
        title: 'Original Title',
        description: 'Original Description',
      );

      taskService.addTask(task);

      final updatedTask = task.copyWith(title: 'Updated Title');
      taskService.updateTask(updatedTask);

      final tasks = taskService.getProjectTasks('project_1');
      expect(tasks[0].title, 'Updated Title');
    });

    test('Can add sub task check', () {
      final task = Task(
        id: 'task_1',
        projectId: 'project_1',
        title: 'Test Task',
        description: '',
      );

      taskService.addTask(task);

      final canAdd = taskService.canAddSubTask('task_1');
      expect(canAdd, true);
    });
  });
}