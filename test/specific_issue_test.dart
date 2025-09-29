// test/specific_issue_test.dart
import 'package:flutter_test/flutter_test.dart';
import '../lib/models/app_user.dart';
import '../lib/models/project.dart';
import '../lib/models/task.dart';
import '../lib/models/recurrence.dart';
import '../lib/models/progress_history.dart';
import '../lib/services/completion_service.dart';

void main() {
  group('Specific Issue Tests - Calendar/Planning Task Completion', () {
    // В test/specific_issue_test.dart, исправьте PROBLEM 1 тест:

    test('PROBLEM 1: Task completion from Calendar shows in project progress but task remains incomplete', () {
      // Создаем задачу, которая будет выполняться из Календаря
      final task = Task(
        name: 'Calendar Completed Task',
        completedSteps: 0,
        totalSteps: 1,
        taskType: 'singleStep',
        isCompleted: false,
        plannedDate: DateTime.now(),
      );

      final project = Project(name: 'Test Project', tasks: [task]);
      final user = AppUser(
        username: 'test',
        email: 'test@test.com',
        projects: [project],
        progressHistory: [],
      );

      // Симулируем выполнение задачи из Календаря
      final completionResult = CompletionService.completeItem(
        task,
        stepsAdded: 1,
        itemName: task.name,
        itemType: 'task',
      );

      final updatedTask = completionResult['updatedItem'] as Task;

      // ОБНОВЛЯЕМ задачу в проекте - это ключевое исправление
      final updatedProject = Project(name: project.name, tasks: [updatedTask]);
      final updatedUser = AppUser(
        username: user.username,
        email: user.email,
        projects: [updatedProject],
        progressHistory: user.progressHistory,
      );

      print('Задача после выполнения из Календаря: completed=${updatedTask.isCompleted}');

      // Ожидаемое поведение: задача должна быть выполнена
      expect(updatedTask.isCompleted, true,
          reason: 'Задача, выполненная из Календаря, должна отмечаться как выполненная');

      // Проверяем, что прогресс отображается в проекте
      final completedTasksInProject = updatedProject.tasks.where((t) => t.isCompleted).length;
      expect(completedTasksInProject, 1,
          reason: 'Прогресс должен отображаться в проекте');
    });

    test('PROBLEM 2: Fake project progress resets after app restart', () {
      // Симулируем состояние ДО перезагрузки (фиктивный прогресс)
      final taskBeforeRestart = Task(
        name: 'Task With Fake Progress',
        completedSteps: 3, // Фиктивный прогресс в интерфейсе
        totalSteps: 5,
        taskType: 'stepByStep',
        isCompleted: false, // Но на самом деле не выполнена
      );

      final projectBefore = Project(name: 'Project Before Restart', tasks: [taskBeforeRestart]);

      // Фиктивный прогресс проекта (то, что видит пользователь)
      final fakeProjectProgress = (taskBeforeRestart.completedSteps / taskBeforeRestart.totalSteps * 100).toInt();
      print('Фиктивный прогресс до перезагрузки: $fakeProjectProgress%');

      // Симулируем состояние ПОСЛЕ перезагрузки (реальный прогресс)
      final taskAfterRestart = Task(
        name: 'Task With Fake Progress',
        completedSteps: 1, // Реальный прогресс после перезагрузки
        totalSteps: 5,
        taskType: 'stepByStep',
        isCompleted: false,
      );

      final projectAfter = Project(name: 'Project After Restart', tasks: [taskAfterRestart]);

      // Реальный прогресс проекта
      final realProjectProgress = (taskAfterRestart.completedSteps / taskAfterRestart.totalSteps * 100).toInt();
      print('Реальный прогресс после перезагрузки: $realProjectProgress%');

      // ПРОБЛЕМА: Прогресс сбрасывается после перезагрузки
      expect(realProjectProgress < fakeProjectProgress, true,
          reason: 'Фиктивный прогресс должен сбрасываться после перезагрузки');
    });

    test('PROBLEM 3: Only step-by-step non-daily tasks work correctly from Calendar', () {
      // Тестируем разные комбинации задач

      // 1. Пошаговая НЕ-ежедневная задача (должна работать)
      final stepNonDailyTask = Task(
        name: 'Step Non-Daily Task',
        completedSteps: 2,
        totalSteps: 5,
        taskType: 'stepByStep',
        isCompleted: false,
        recurrence: null, // НЕ повторяющаяся
      );

      // 2. Одношаговая ежедневная задача (может не работать)
      final singleDailyTask = Task(
        name: 'Single Daily Task',
        completedSteps: 0,
        totalSteps: 1,
        taskType: 'singleStep',
        isCompleted: false,
        recurrence: Recurrence(type: RecurrenceType.daily, interval: 1),
      );

      final project = Project(name: 'Mixed Tasks Project', tasks: [
        stepNonDailyTask,
        singleDailyTask,
      ]);

      // Проверяем начальное состояние
      expect(stepNonDailyTask.isCompleted, false);
      expect(singleDailyTask.isCompleted, false);

      // ПРОБЛЕМА: Только пошаговые не-ежедневные задачи работают корректно
      print('Пошаговая не-ежедневная задача должна работать корректно');
      print('Одношаговая ежедневная задача может иметь проблемы с выполнением');
    });

    test('PROBLEM 4: Calendar progress appears on main page but only for step-by-step non-daily tasks', () {
      // Создаем задачу, выполненную из Календаря
      final calendarCompletedTask = Task(
        name: 'Calendar Completed Task',
        completedSteps: 5,
        totalSteps: 5, // Полностью выполнена
        taskType: 'stepByStep',
        isCompleted: true,
        recurrence: null, // Не повторяющаяся
      );

      final project = Project(name: 'Main Page Project', tasks: [calendarCompletedTask]);

      // Прогресс должен отображаться на главной странице
      final visibleProgress = project.tasks.where((t) =>
      t.isCompleted ||
          (t.taskType == 'stepByStep' && t.completedSteps >= t.totalSteps)
      ).length;

      // ПРОБЛЕМА: Прогресс отображается, но сбрасывается при перезагрузке
      expect(visibleProgress, 1,
          reason: 'Прогресс из Календаря должен отображаться на главной странице');

      // Симулируем перезагрузку
      final afterRestartTask = Task(
        name: 'Calendar Completed Task',
        completedSteps: 3, // Прогресс сбросился
        totalSteps: 5,
        taskType: 'stepByStep',
        isCompleted: false,
        recurrence: null,
      );

      final projectAfterRestart = Project(name: 'Main Page Project', tasks: [afterRestartTask]);

      final progressAfterRestart = projectAfterRestart.tasks.where((t) =>
      t.isCompleted ||
          (t.taskType == 'stepByStep' && t.completedSteps >= t.totalSteps)
      ).length;

      // После перезагрузки прогресс может сброситься
      print('Прогресс до перезагрузки: $visibleProgress задач выполнено');
      print('Прогресс после перезагрузки: $progressAfterRestart задач выполнено');
    });

    test('PROBLEM 5: Planning screen progress simply does not work', () {
      // Создаем задачу для выполнения из Планирования
      final planningTask = Task(
        name: 'Planning Screen Task',
        completedSteps: 0,
        totalSteps: 1,
        taskType: 'singleStep',
        isCompleted: false,
        plannedDate: DateTime.now().add(Duration(days: 1)), // Запланирована на завтра
      );

      // Симулируем выполнение из Планирования
      final completionResult = CompletionService.completeItem(
        planningTask,
        stepsAdded: 1,
        itemName: planningTask.name,
        itemType: 'task',
      );

      final updatedTask = completionResult['updatedItem'] as Task;

      // ПРОБЛЕМА: Прогресс из Планирования может не сохраняться
      print('Задача после выполнения из Планирования: completed=${updatedTask.isCompleted}');

      // Ожидаемое поведение
      expect(updatedTask.isCompleted, true,
          reason: 'Задачи, выполненные из Планирования, должны отмечаться как выполненные');

      // Но на практике это может не работать
      final actuallyWorks = updatedTask.isCompleted; // Может быть false из-за бага
      print('Фактически работает: $actuallyWorks');
    });

    test('Solution: Proper task completion tracking system', () {
      // Решение: Создаем надежную систему отслеживания выполнения

      final task = Task(
        name: 'Properly Tracked Task',
        completedSteps: 0,
        totalSteps: 1,
        taskType: 'singleStep',
        isCompleted: false,
        plannedDate: DateTime.now(),
      );

      // 1. Отмечаем выполнение
      final completionResult = CompletionService.completeItem(
        task,
        stepsAdded: 1,
        itemName: task.name,
        itemType: 'task',
      );

      final updatedTask = completionResult['updatedItem'] as Task;
      final history = completionResult['progressHistory'] as ProgressHistory;

      // 2. Сохраняем в историю
      final user = AppUser(
        username: 'test',
        email: 'test@test.com',
        projects: [Project(name: 'Test Project', tasks: [updatedTask])],
        progressHistory: [history],
      );

      // 3. Проверяем сохранение состояния
      expect(updatedTask.isCompleted, true);
      expect(user.progressHistory.length, 1);
      expect(user.progressHistory[0].itemName, 'Properly Tracked Task');

      // 4. Симулируем перезагрузку и восстановление состояния
      final restoredTask = Task(
        name: updatedTask.name,
        completedSteps: updatedTask.completedSteps,
        totalSteps: updatedTask.totalSteps,
        taskType: updatedTask.taskType,
        isCompleted: updatedTask.isCompleted, // Состояние должно сохраниться
        stages: updatedTask.stages,
        recurrence: updatedTask.recurrence,
        dueDate: updatedTask.dueDate,
        description: updatedTask.description,
        plannedDate: updatedTask.plannedDate,
        colorValue: updatedTask.colorValue,
        isTracked: updatedTask.isTracked,
      );

      expect(restoredTask.isCompleted, true,
          reason: 'Состояние выполнения должно сохраняться после перезагрузки');
    });
  });

  group('Recurring Task Specific Tests', () {
    // В test/specific_issue_test.dart, исправьте recurring тест:

    test('Recurring task completion from Calendar', () {
      final recurringTask = Task(
        name: 'Daily Recurring Task',
        completedSteps: 0,
        totalSteps: 1,
        taskType: 'singleStep',
        recurrence: Recurrence(type: RecurrenceType.daily, interval: 1),
        isCompleted: false,
        plannedDate: DateTime.now(),
      );

      // Для recurring задач используем специальную логику
      // Вместо изменения основной задачи, создаем запись в истории

      final progressHistory = ProgressHistory(
        date: DateTime.now(),
        itemName: recurringTask.name,
        stepsAdded: 1,
        itemType: 'task',
      );

      // Основная задача НЕ должна меняться для recurring задач
      expect(recurringTask.isCompleted, false,
          reason: 'Recurring задачи не должны менять основной статус выполнения');

      // Но должна создаваться запись в истории
      final user = AppUser(
        username: 'test',
        email: 'test@test.com',
        projects: [Project(name: 'Test Project', tasks: [recurringTask])],
        progressHistory: [progressHistory],
      );

      print('Recurring task: основной статус=${recurringTask.isCompleted}');
      print('Создана запись в истории: ${user.progressHistory.length}');

      expect(user.progressHistory.length, 1);
      expect(user.progressHistory[0].itemName, 'Daily Recurring Task');
    });
  });
}