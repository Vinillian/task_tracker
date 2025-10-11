import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:task_tracker/models/task.dart';
import 'package:task_tracker/providers/task_provider.dart';
import 'package:task_tracker/services/task_service.dart';

// Создаем мок для TaskService
class MockTaskService extends Mock implements TaskService {}

void main() {
  group('TaskProvider Tests', () {
    late MockTaskService mockTaskService;
    late TaskNotifier taskNotifier;

    setUp(() {
      mockTaskService = MockTaskService();
      taskNotifier = TaskNotifier(mockTaskService);
    });

    test('initial state is empty', () {
      expect(taskNotifier.state, isEmpty);
    });

    test('addTask calls taskService and updates state', () {
      // Arrange
      final task = Task(
        id: 'test_1',
        projectId: 'project_1',
        title: 'Test Task',
        description: 'Test Description',
      );

      when(() => mockTaskService.addTask(task)).thenReturn(null);
      when(() => mockTaskService.getAllTasks()).thenReturn([task]);

      // Act
      taskNotifier.addTask(task);

      // Assert
      verify(() => mockTaskService.addTask(task)).called(1);
      expect(taskNotifier.state.length, 1);
      expect(taskNotifier.state[0].title, 'Test Task');
    });

    test('updateTask calls taskService and updates state', () {
      // Arrange
      final updatedTask = Task(
        id: 'task_1',
        projectId: 'project_1',
        title: 'Updated Title',
        description: 'Updated Description',
      );

      when(() => mockTaskService.updateTask(updatedTask)).thenReturn(null);
      when(() => mockTaskService.getAllTasks()).thenReturn([updatedTask]);

      // Act
      taskNotifier.updateTask(updatedTask);

      // Assert
      verify(() => mockTaskService.updateTask(updatedTask)).called(1);
      expect(taskNotifier.state.length, 1);
      expect(taskNotifier.state[0].title, 'Updated Title');
    });

    test('removeTask calls taskService and updates state', () {
      // Arrange
      when(() => mockTaskService.removeTask('task_1')).thenReturn(null);
      when(() => mockTaskService.getAllTasks()).thenReturn([]);

      // Act
      taskNotifier.removeTask('task_1');

      // Assert
      verify(() => mockTaskService.removeTask('task_1')).called(1);
      expect(taskNotifier.state.isEmpty, true);
    });

    test('loadDemoTasks calls taskService and updates state', () {
      // Arrange
      final demoTask = Task(
        id: 'demo_1',
        projectId: 'project_1',
        title: 'Demo Task',
        description: 'Demo Description',
      );

      when(() => mockTaskService.loadDemoTasks('project_1')).thenReturn(null);
      when(() => mockTaskService.getAllTasks()).thenReturn([demoTask]);

      // Act
      taskNotifier.loadDemoTasks('project_1');

      // Assert
      verify(() => mockTaskService.loadDemoTasks('project_1')).called(1);
      expect(taskNotifier.state.length, 1);
      expect(taskNotifier.state[0].title, 'Demo Task');
    });
  });
}