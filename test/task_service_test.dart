// test/task_service_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:task_tracker/models/project.dart';
import 'package:task_tracker/models/task.dart';
import 'package:task_tracker/services/firestore_service.dart';
import 'package:task_tracker/services/task_service.dart';

import 'task_service_test.mocks.dart';

@GenerateMocks([FirestoreService])
void main() {
  late MockFirestoreService mockFirestoreService;
  late TaskService taskService;

  setUp(() {
    mockFirestoreService = MockFirestoreService();
    taskService = TaskService(mockFirestoreService);
  });

  group('TaskService', () {
    test('addTask should call firestore service', () async {
      final task = Task(
        title: 'Test Task',
        description: 'Test Description',
        priority: 1,
      );
      const projectId = 'project1';

      when(mockFirestoreService.addTask(projectId, task))
          .thenAnswer((_) async => 'task1');

      await taskService.addTask(projectId, task);

      verify(mockFirestoreService.addTask(projectId, task)).called(1);
    });

    test('updateTask should call firestore service', () async {
      final task = Task(
        id: 'task1',
        title: 'Updated Task',
        description: 'Updated Description',
        priority: 2,
      );
      const projectId = 'project1';

      when(mockFirestoreService.updateTask(projectId, task))
          .thenAnswer((_) async {});

      await taskService.updateTask(projectId, task);

      verify(mockFirestoreService.updateTask(projectId, task)).called(1);
    });

    test('deleteTask should call firestore service', () async {
      const projectId = 'project1';
      const taskId = 'task1';

      when(mockFirestoreService.deleteTask(projectId, taskId))
          .thenAnswer((_) async {});

      await taskService.deleteTask(projectId, taskId);

      verify(mockFirestoreService.deleteTask(projectId, taskId)).called(1);
    });
  });

  group('Task completion', () {
    test('completeTaskWithSubtasks without completing subtasks', () async {
      const projectId = 'project1';
      final task = Task(
        id: 'task1',
        title: 'Main Task',
        subTasks: [
          Task(id: 'sub1', title: 'Subtask 1', isCompleted: false),
        ],
      );

      when(mockFirestoreService.updateTask(projectId, any))
          .thenAnswer((_) async {});

      await taskService.completeTaskWithSubtasks(projectId, task, false);

      verify(mockFirestoreService.updateTask(projectId, any)).called(1);
    });
  });
}