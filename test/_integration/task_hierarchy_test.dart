import 'package:flutter_test/flutter_test.dart';
import 'package:task_tracker/models/task.dart';
import 'package:task_tracker/services/task_service.dart';

void main() {
  group('Task Hierarchy Integration Tests', () {
    late TaskService taskService;

    setUp(() {
      taskService = TaskService();
    });

    test('Complex task hierarchy with progress calculation', () {
      const projectId = 'test_project';

      // Создаем сложную иерархию задач
      final rootTask1 = Task(
        id: 'root_1',
        projectId: projectId,
        title: 'Root Task 1',
        description: 'Main task',
      );

      final subTask1 = Task(
        id: 'sub_1',
        parentId: 'root_1',
        projectId: projectId,
        title: 'Sub Task 1',
        description: 'First sub task',
      );

      final subTask2 = Task(
        id: 'sub_2',
        parentId: 'root_1',
        projectId: projectId,
        title: 'Sub Task 2',
        description: 'Second sub task',
        isCompleted: true,
      );

      final subSubTask = Task(
        id: 'sub_sub_1',
        parentId: 'sub_1',
        projectId: projectId,
        title: 'Sub Sub Task',
        description: 'Deeply nested task',
      );

      // Добавляем все задачи
      taskService.addTask(rootTask1);
      taskService.addTask(subTask1);
      taskService.addTask(subTask2);
      taskService.addTask(subSubTask);

      // Проверяем структуру
      final rootTasks = taskService.getProjectTasks(projectId)
          .where((task) => task.parentId == null)
          .toList();
      expect(rootTasks.length, 1);

      final subTasks = taskService.getSubTasks('root_1');
      expect(subTasks.length, 2);

      final allTasks = taskService.getAllProjectTasks(projectId);
      expect(allTasks.length, 4);

      // Проверяем прогресс (1 из 4 задач завершена)
      final progress = taskService.getProjectProgress(projectId);
      expect(progress, 0.25);
    });

    test('Task depth validation', () {
      const projectId = 'depth_test_project';

      // Создаем цепочку задач для проверки глубины
      String currentParent = 'root';
      for (int i = 0; i < 5; i++) {
        final task = Task(
          id: 'task_$i',
          parentId: currentParent == 'root' ? null : currentParent,
          projectId: projectId,
          title: 'Task Level $i',
          description: 'Task at level $i',
        );

        taskService.addTask(task);
        currentParent = 'task_$i';

        // Проверяем можно ли добавить подзадачу
        final canAddMore = taskService.canAddSubTask('task_$i');
        if (i < 4) {
          expect(canAddMore, true, reason: 'Should be able to add subtask at level $i');
        }
      }
    });
  });
}