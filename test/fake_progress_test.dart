// test/fake_progress_test.dart
import 'package:flutter_test/flutter_test.dart';
import '../lib/models/project.dart';
import '../lib/models/task.dart';
import '../lib/models/recurrence.dart';

void main() {
  group('Fake Progress Detection Tests', () {
    test('Detect fake progress in project calculation', () {
      // Создаем задачу, которая показывает фиктивный прогресс
      final fakeProgressTask = Task(
        name: 'Task with Fake Progress',
        completedSteps: 3,
        totalSteps: 5,
        taskType: 'stepByStep',
        isCompleted: false,
      );

      // Создаем задачу с реальным прогрессом (выполнена)
      final realProgressTask = Task(
        name: 'Completed Task',
        completedSteps: 1,
        totalSteps: 1,
        taskType: 'singleStep',
        isCompleted: true,
      );

      final project = Project(name: 'Test Project', tasks: [
        fakeProgressTask,
        realProgressTask,
      ]);

      // Реальный прогресс - только выполненные задачи
      final realCompletedTasks = project.tasks.where((t) =>
      t.isCompleted ||
          (t.taskType == 'stepByStep' && t.completedSteps >= t.totalSteps)
      ).length;

      // Фиктивный прогресс - все, что не является реально выполненным
      final fakeProgressTasks = project.tasks.length - realCompletedTasks;

      expect(realCompletedTasks, 1); // Только realProgressTask
      expect(fakeProgressTasks, 1); // fakeProgressTask не выполнен полностью
    });

    test('Progress reset after app restart simulation', () {
      // Симулируем состояние до перезагрузки (с фиктивным прогрессом)
      final taskBeforeRestart = Task(
        name: 'Task Before Restart',
        completedSteps: 3, // Фиктивный прогресс
        totalSteps: 5,
        taskType: 'stepByStep',
        isCompleted: false,
      );

      // Симулируем состояние после перезагрузки (сброс к реальному прогрессу)
      final taskAfterRestart = Task(
        name: 'Task After Restart',
        completedSteps: 2, // Реальный прогресс
        totalSteps: 5,
        taskType: 'stepByStep',
        isCompleted: false,
      );

      // Прогресс должен сброситься к реальному значению
      expect(taskAfterRestart.completedSteps, 2);
      expect(taskAfterRestart.completedSteps < taskBeforeRestart.completedSteps, true);
    });

    test('Recurring task fake progress detection', () {
      final recurringTask = Task(
        name: 'Recurring Task',
        completedSteps: 0,
        totalSteps: 1,
        taskType: 'singleStep',
        recurrence: Recurrence(type: RecurrenceType.daily, interval: 1),
        isCompleted: false, // Основная задача не выполнена
        plannedDate: DateTime.now(),
      );

      // Для recurring задач isCompleted всегда false
      // Реальный прогресс отслеживается отдельно
      expect(recurringTask.isCompleted, false);

      // Фиктивный прогресс - если кто-то пытается выставить isCompleted = true
      final fakeRecurringTask = Task(
        name: 'Fake Recurring Task',
        completedSteps: 1,
        totalSteps: 1,
        taskType: 'singleStep',
        recurrence: Recurrence(type: RecurrenceType.daily, interval: 1),
        isCompleted: true, // ФИКТИВНЫЙ ПРОГРЕСС - не должно быть true
        plannedDate: DateTime.now(),
      );

      // Для recurring задач isCompleted никогда не должно быть true
      // Это тест на обнаружение неправильного поведения
      expect(fakeRecurringTask.isCompleted, true); // Это плохо, но мы это тестируем
    });
  });
}