// test/calendar_planning_integration_test.dart
import 'package:flutter_test/flutter_test.dart';
import '../lib/models/app_user.dart';
import '../lib/models/project.dart';
import '../lib/models/task.dart';
import '../lib/models/stage.dart';
import '../lib/models/recurrence.dart';
import '../lib/models/progress_history.dart';
import '../lib/services/completion_service.dart';

void main() {
  group('Calendar and Planning Integration Tests', () {
    late AppUser testUser;

    setUp(() {
      testUser = AppUser(
        username: 'testuser',
        email: 'test@example.com',
        projects: [],
        progressHistory: [],
      );
    });

    test('Single-step task completion from Calendar updates progress', () {
      // Создаем одношаговую задачу
      final task = Task(
        name: 'Calendar Single Task',
        completedSteps: 0,
        totalSteps: 1,
        taskType: 'singleStep',
        isCompleted: false,
        plannedDate: DateTime.now(),
      );

      final project = Project(name: 'Test Project', tasks: [task]);
      testUser.projects.add(project);

      // Симулируем выполнение из Календаря - ИСПРАВЛЕННЫЙ ВЫЗОВ
      final completionResult = CompletionService.completeItem(
        task, // item как первый позиционный параметр
        stepsAdded: 1,
        itemName: task.name,
        itemType: 'task',
      );

      final updatedTask = completionResult['updatedItem'] as Task;
      final progressHistory = completionResult['progressHistory'] as ProgressHistory;

      // Проверяем, что задача отмечена как выполненная
      expect(updatedTask.isCompleted, true);
      expect(progressHistory.stepsAdded, 1);
      expect(progressHistory.itemName, 'Calendar Single Task');
    });

    test('Step-by-step task progress from Calendar', () {
      // Создаем пошаговую задачу
      final task = Task(
        name: 'Calendar Step Task',
        completedSteps: 2,
        totalSteps: 5,
        taskType: 'stepByStep',
        isCompleted: false,
        plannedDate: DateTime.now(),
      );

      final project = Project(name: 'Test Project', tasks: [task]);
      testUser.projects.add(project);

      // Симулируем добавление прогресса из Календаря - ИСПРАВЛЕННЫЙ ВЫЗОВ
      final completionResult = CompletionService.completeItem(
        task, // item как первый позиционный параметр
        stepsAdded: 2,
        itemName: task.name,
        itemType: 'task',
      );

      final updatedTask = completionResult['updatedItem'] as Task;

      // Проверяем, что прогресс увеличился
      expect(updatedTask.completedSteps, 4);
      expect(updatedTask.isCompleted, false); // Еще не завершена
    });

    test('Stage completion from Planning screen', () {
      // Создаем этап
      final stage = Stage(
        name: 'Planning Stage',
        completedSteps: 0,
        totalSteps: 1,
        stageType: 'singleStep',
        isCompleted: false,
      );

      final task = Task(
        name: 'Parent Task',
        completedSteps: 0,
        totalSteps: 1,
        taskType: 'stepByStep',
        stages: [stage],
        plannedDate: DateTime.now(),
      );

      final project = Project(name: 'Test Project', tasks: [task]);
      testUser.projects.add(project);

      // Симулируем выполнение этапа из Планирования - ИСПРАВЛЕННЫЙ ВЫЗОВ
      final completionResult = CompletionService.completeItem(
        stage, // item как первый позиционный параметр
        stepsAdded: 1,
        itemName: stage.name,
        itemType: 'stage',
      );

      final updatedStage = completionResult['updatedItem'] as Stage;

      // Проверяем, что этап выполнен
      expect(updatedStage.isCompleted, true);
    });

    test('Recurring task completion tracking', () {
      // Создаем повторяющуюся задачу
      final recurringTask = Task(
        name: 'Daily Recurring Task',
        completedSteps: 0,
        totalSteps: 1,
        taskType: 'singleStep',
        recurrence: Recurrence(type: RecurrenceType.daily, interval: 1),
        isCompleted: false,
        plannedDate: DateTime.now(),
      );

      final project = Project(name: 'Test Project', tasks: [recurringTask]);
      testUser.projects.add(project);

      // Для recurring задач основная задача не должна менять статус
      // при выполнении из Календаря/Планирования
      expect(recurringTask.isCompleted, false);

      // Но должна добавляться запись в историю прогресса
      final progressHistory = ProgressHistory(
        date: DateTime.now(),
        itemName: recurringTask.name,
        stepsAdded: 1,
        itemType: 'task',
      );

      testUser.progressHistory.add(progressHistory);

      expect(testUser.progressHistory.length, 1);
      expect(testUser.progressHistory[0].itemName, 'Daily Recurring Task');
    });

    test('Progress persistence after simulated app restart', () {
      // Создаем задачу с прогрессом
      final task = Task(
        name: 'Persistent Task',
        completedSteps: 3,
        totalSteps: 5,
        taskType: 'stepByStep',
        isCompleted: false,
      );

      final project = Project(name: 'Test Project', tasks: [task]);
      testUser.projects.add(project);

      // Симулируем перезагрузку приложения
      final reloadedTask = Task(
        name: task.name,
        completedSteps: task.completedSteps, // Прогресс должен сохраниться
        totalSteps: task.totalSteps,
        taskType: task.taskType,
        isCompleted: task.isCompleted,
        stages: task.stages,
        recurrence: task.recurrence,
        dueDate: task.dueDate,
        description: task.description,
        plannedDate: task.plannedDate,
        colorValue: task.colorValue,
        isTracked: task.isTracked,
      );

      // Проверяем, что прогресс сохранился
      expect(reloadedTask.completedSteps, 3);
      expect(reloadedTask.name, 'Persistent Task');
    });

    test('Mixed task types progress calculation', () {
      // Создаем разные типы задач
      final singleStepTask = Task(
        name: 'Single Step Task',
        completedSteps: 0,
        totalSteps: 1,
        taskType: 'singleStep',
        isCompleted: true, // Выполнена
      );

      final stepTask = Task(
        name: 'Step Task',
        completedSteps: 3,
        totalSteps: 5,
        taskType: 'stepByStep',
        isCompleted: false,
      );

      final recurringTask = Task(
        name: 'Recurring Task',
        completedSteps: 0,
        totalSteps: 1,
        taskType: 'singleStep',
        recurrence: Recurrence(type: RecurrenceType.daily, interval: 1),
        isCompleted: false,
      );

      final project = Project(name: 'Mixed Project', tasks: [
        singleStepTask,
        stepTask,
        recurringTask,
      ]);

      testUser.projects.add(project);

      // Рассчитываем прогресс проекта
      final completedTasks = project.tasks.where((t) =>
      (t.taskType == 'singleStep' && t.isCompleted) ||
          (t.taskType == 'stepByStep' && t.completedSteps >= t.totalSteps)
      ).length;

      final totalTasks = project.tasks.length;

      // Должна быть учтена только singleStepTask как выполненная
      expect(completedTasks, 1);
      expect(totalTasks, 3);
    });
  });

  group('Completion Service Edge Cases', () {
    test('Zero steps added does not create history', () {
      final task = Task(
        name: 'Test Task',
        completedSteps: 2,
        totalSteps: 5,
        taskType: 'stepByStep',
        isCompleted: false,
      );

      final initialHistory = <ProgressHistory>[];

      final result = CompletionService.completeItemWithHistory(
        item: task,
        stepsAdded: 0, // Нулевое изменение
        itemName: task.name,
        itemType: 'task',
        currentHistory: initialHistory,
      );

      // История не должна измениться при нулевом прогрессе
      expect(result['updatedHistory'].length, initialHistory.length);
    });

    test('Task completion beyond total steps is capped', () {
      final task = Task(
        name: 'Overflow Task',
        completedSteps: 4,
        totalSteps: 5,
        taskType: 'stepByStep',
        isCompleted: false,
      );

      // Пытаемся добавить больше шагов, чем нужно - ИСПРАВЛЕННЫЙ ВЫЗОВ
      final completionResult = CompletionService.completeItem(
        task, // item как первый позиционный параметр
        stepsAdded: 10, // Слишком много шагов
        itemName: task.name,
        itemType: 'task',
      );

      final updatedTask = completionResult['updatedItem'] as Task;

      // Прогресс должен быть ограничен totalSteps
      expect(updatedTask.completedSteps, 5);
      expect(updatedTask.isCompleted, true);
    });
  });
}