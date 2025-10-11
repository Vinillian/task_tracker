import 'package:flutter_test/flutter_test.dart';
import 'package:task_tracker/models/task.dart';
import 'package:task_tracker/services/task_service.dart';

void main() {
  group('TaskService Tests', () {
    late TaskService taskService;

    setUp(() {
      taskService = TaskService();
    });

    test('addTask and getProjectTasks work correctly', () {
      // Arrange
      final task = Task(
        id: 'test_1',
        projectId: 'project_1',
        title: 'Test Task',
        description: 'Test Description',
      );

      // Act
      taskService.addTask(task);
      final tasks = taskService.getProjectTasks('project_1');

      // Assert
      expect(tasks.length, 1);
      expect(tasks[0].title, 'Test Task');
      expect(tasks[0].projectId, 'project_1');
    });

    test('removeTask removes task correctly', () {
      // Arrange
      final task = Task(
        id: 'test_1',
        projectId: 'project_1',
        title: 'Test Task',
        description: 'Test Description',
      );
      taskService.addTask(task);

      // Act
      taskService.removeTask('test_1');
      final tasks = taskService.getProjectTasks('project_1');

      // Assert
      expect(tasks.length, 0);
    });

    test('getSubTasks returns correct sub tasks', () {
      // Arrange
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

      // Act
      final subTasks = taskService.getSubTasks('parent_1');

      // Assert
      expect(subTasks.length, 1);
      expect(subTasks[0].title, 'Sub Task');
      expect(subTasks[0].parentId, 'parent_1');
    });

    test('updateTask updates task correctly', () {
      // Arrange
      final task = Task(
        id: 'task_1',
        projectId: 'project_1',
        title: 'Original Title',
        description: 'Original Description',
      );
      taskService.addTask(task);

      // Act
      final updatedTask = task.copyWith(title: 'Updated Title');
      taskService.updateTask(updatedTask);

      // Assert
      final tasks = taskService.getProjectTasks('project_1');
      expect(tasks[0].title, 'Updated Title');
    });

    test('getProjectProgress calculates progress correctly', () {
      // Arrange
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

      // Act
      final progress = taskService.getProjectProgress('project_1');

      // Assert
      expect(progress, 0.5); // 1 completed out of 2 tasks
    });
  });
}