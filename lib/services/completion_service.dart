import '../models/task.dart';
import '../models/stage.dart';
import '../models/step.dart' as custom_step;
import '../models/progress_history.dart';
import '../services/task_service.dart';
import '../services/recurrence_service.dart';
import '../models/recurrence.dart';

class CompletionService {
  // Обработка выполнения элемента и обновление прогресса
  static Map<String, dynamic> completeItem(
      dynamic item, {
        required int stepsAdded,
        required String itemName,
        required String itemType,
      }) {
    dynamic updatedItem;
    int actualSteps = stepsAdded;

    // Обновляем элемент в зависимости от его типа
    if (item is Task) {
      if (item.taskType == "singleStep") {
        updatedItem = TaskService.toggleTaskCompletion(item);
        actualSteps = updatedItem.isCompleted ? 1 : -1;
      } else {
        updatedItem = TaskService.addProgressToTask(item, stepsAdded);
      }
    } else if (item is Stage) {
      if (item.stageType == "singleStep") {
        updatedItem = TaskService.toggleStageCompletion(item);
        actualSteps = updatedItem.isCompleted ? 1 : -1;
      } else {
        updatedItem = TaskService.addProgressToStage(item, stepsAdded);
      }
    } else if (item is custom_step.Step) {
      if (item.stepType == "singleStep") {
        updatedItem = TaskService.toggleStepCompletion(item);
        actualSteps = updatedItem.isCompleted ? 1 : -1;
      } else {
        updatedItem = TaskService.addProgressToStep(item, stepsAdded);
      }
    }

    // Создаем запись в истории прогресса
    final progressHistory = ProgressHistory(
      date: DateTime.now(),
      itemName: itemName,
      stepsAdded: actualSteps,
      itemType: itemType,
    );

    return {
      'updatedItem': updatedItem,
      'progressHistory': progressHistory,
    };
  }

  // Получение типа элемента для истории
  static String getItemType(dynamic item) {
    if (item is Task) return 'task';
    if (item is Stage) return 'stage';
    if (item is custom_step.Step) return 'step';
    return 'unknown';
  }

  // Получение имени элемента для истории
  static String getItemName(dynamic item) {
    return item.name;
  }

  static Map<String, dynamic> completeItemWithHistory({
    required dynamic item,
    required int stepsAdded,
    required String itemName,
    required String itemType,
    required List<dynamic> currentHistory,
  }) {
    final result = completeItem(
      item,
      stepsAdded: stepsAdded,
      itemName: itemName,
      itemType: itemType,
    );

    // Добавляем в историю только если были реальные изменения
    if (result['progressHistory'].stepsAdded != 0) {
      final updatedHistory = List<dynamic>.from(currentHistory)
        ..add(result['progressHistory']);

      return {
        'updatedItem': result['updatedItem'],
        'updatedHistory': updatedHistory,
      };
    }

    return {
      'updatedItem': result['updatedItem'],
      'updatedHistory': currentHistory,
    };
  }

  // Обработка выполнения с автоматическим переносом daily задач
  // В lib/services/completion_service.dart
  // В lib/services/completion_service.dart
  static Map<String, dynamic> completeItemWithAutoMove({
    required dynamic item,
    required int stepsAdded,
    required String itemName,
    required String itemType,
    required List<dynamic> currentHistory,
  }) {
    final result = completeItemWithHistory(
      item: item,
      stepsAdded: stepsAdded,
      itemName: itemName,
      itemType: itemType,
      currentHistory: currentHistory,
    );

    // Для recurring задач сбрасываем прогресс и переносим на следующую дату
    final updatedItem = _handleRecurringItemCompletion(result['updatedItem']);

    return {
      'updatedItem': updatedItem,
      'updatedHistory': result['updatedHistory'],
    };
  }

  static dynamic _handleRecurringItemCompletion(dynamic item) {
    // Для recurring задач сбрасываем статус выполнения и переносим на следующую дату
    if (item is Task && item.recurrence != null && item.plannedDate != null) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final plannedDay = DateTime(item.plannedDate!.year, item.plannedDate!.month, item.plannedDate!.day);

      // Если задача запланирована на сегодня - переносим на следующий occurrence
      if (plannedDay.isAtSameMomentAs(today)) {
        final nextDate = RecurrenceService.generateOccurrences(
          recurrence: item.recurrence!,
          startDate: item.plannedDate!,
          count: 2, // Берем следующий occurrence после текущего
        ).elementAt(1); // Первый - сегодняшний, второй - следующий

        print('🔄 Перенос recurring задачи "${item.name}" с ${item.plannedDate} на $nextDate');

        return Task(
          name: item.name,
          completedSteps: 0, // СБРАСЫВАЕМ ПРОГРЕСС
          totalSteps: item.totalSteps,
          stages: item.stages.map((stage) => _resetStageProgress(stage)).toList(), // Сбрасываем прогресс этапов
          taskType: item.taskType,
          recurrence: item.recurrence,
          dueDate: item.dueDate,
          isCompleted: false, // СБРАСЫВАЕМ ВЫПОЛНЕНИЕ
          description: item.description,
          plannedDate: nextDate, // Переносим на следующую дату
          colorValue: item.colorValue,
          isTracked: item.isTracked,
        );
      }
    }

    if (item is Stage && item.recurrence != null && item.plannedDate != null) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final plannedDay = DateTime(item.plannedDate!.year, item.plannedDate!.month, item.plannedDate!.day);

      if (plannedDay.isAtSameMomentAs(today)) {
        final nextDate = RecurrenceService.generateOccurrences(
          recurrence: item.recurrence!,
          startDate: item.plannedDate!,
          count: 2,
        ).elementAt(1);

        return Stage(
          name: item.name,
          completedSteps: 0, // СБРАСЫВАЕМ ПРОГРЕСС
          totalSteps: item.totalSteps,
          stageType: item.stageType,
          isCompleted: false, // СБРАСЫВАЕМ ВЫПОЛНЕНИЕ
          steps: item.steps.map((step) => _resetStepProgress(step)).toList(), // Сбрасываем прогресс шагов
          plannedDate: nextDate,
          recurrence: item.recurrence,
        );
      }
    }

    if (item is custom_step.Step && item.recurrence != null && item.plannedDate != null) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final plannedDay = DateTime(item.plannedDate!.year, item.plannedDate!.month, item.plannedDate!.day);

      if (plannedDay.isAtSameMomentAs(today)) {
        final nextDate = RecurrenceService.generateOccurrences(
          recurrence: item.recurrence!,
          startDate: item.plannedDate!,
          count: 2,
        ).elementAt(1);

        return custom_step.Step(
          name: item.name,
          completedSteps: 0, // СБРАСЫВАЕМ ПРОГРЕСС
          totalSteps: item.totalSteps,
          stepType: item.stepType,
          isCompleted: false, // СБРАСЫВАЕМ ВЫПОЛНЕНИЕ
          plannedDate: nextDate,
          recurrence: item.recurrence,
        );
      }
    }

    // Для не-recurring задач или задач не на сегодня - возвращаем как есть
    return item;
  }

// Вспомогательные методы для сброса прогресса вложенных элементов
  static Stage _resetStageProgress(Stage stage) {
    return Stage(
      name: stage.name,
      completedSteps: 0,
      totalSteps: stage.totalSteps,
      stageType: stage.stageType,
      isCompleted: false,
      steps: stage.steps.map((step) => _resetStepProgress(step)).toList(),
      plannedDate: stage.plannedDate,
      recurrence: stage.recurrence,
    );
  }

  static custom_step.Step _resetStepProgress(custom_step.Step step) {
    return custom_step.Step(
      name: step.name,
      completedSteps: 0,
      totalSteps: step.totalSteps,
      stepType: step.stepType,
      isCompleted: false,
      plannedDate: step.plannedDate,
      recurrence: step.recurrence,
    );
  }

  static dynamic _handleRecurringItemCompletion(dynamic item) {
    // Для recurring задач сбрасываем статус выполнения и переносим на следующую дату
    if (item is Task && item.recurrence != null && item.plannedDate != null) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final plannedDay = DateTime(item.plannedDate!.year, item.plannedDate!.month, item.plannedDate!.day);

      // Если задача запланирована на сегодня - переносим на следующий occurrence
      if (plannedDay.isAtSameMomentAs(today)) {
        final nextDate = RecurrenceService.generateOccurrences(
          recurrence: item.recurrence!,
          startDate: item.plannedDate!,
          count: 2, // Берем следующий occurrence после текущего
        ).elementAt(1); // Первый - сегодняшний, второй - следующий

        print('🔄 Перенос recurring задачи "${item.name}" с ${item.plannedDate} на $nextDate');

        return Task(
          name: item.name,
          completedSteps: 0,
          totalSteps: item.totalSteps,
          stages: item.stages,
          taskType: item.taskType,
          recurrence: item.recurrence,
          dueDate: item.dueDate,
          isCompleted: false,
          description: item.description,
          plannedDate: nextDate, // Переносим на следующую дату
          colorValue: item.colorValue,
          isTracked: item.isTracked,
        );
      }
    }

    if (item is Stage && item.recurrence != null && item.plannedDate != null) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final plannedDay = DateTime(item.plannedDate!.year, item.plannedDate!.month, item.plannedDate!.day);

      if (plannedDay.isAtSameMomentAs(today)) {
        final nextDate = RecurrenceService.generateOccurrences(
          recurrence: item.recurrence!,
          startDate: item.plannedDate!,
          count: 2,
        ).elementAt(1);

        return Stage(
          name: item.name,
          completedSteps: 0,
          totalSteps: item.totalSteps,
          stageType: item.stageType,
          isCompleted: false,
          steps: item.steps,
          plannedDate: nextDate,
          recurrence: item.recurrence,
        );
      }
    }

    if (item is custom_step.Step && item.recurrence != null && item.plannedDate != null) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final plannedDay = DateTime(item.plannedDate!.year, item.plannedDate!.month, item.plannedDate!.day);

      if (plannedDay.isAtSameMomentAs(today)) {
        final nextDate = RecurrenceService.generateOccurrences(
          recurrence: item.recurrence!,
          startDate: item.plannedDate!,
          count: 2,
        ).elementAt(1);

        return custom_step.Step(
          name: item.name,
          completedSteps: 0,
          totalSteps: item.totalSteps,
          stepType: item.stepType,
          isCompleted: false,
          plannedDate: nextDate,
          recurrence: item.recurrence,
        );
      }
    }

    // Для не-recurring задач или задач не на сегодня - возвращаем как есть
    return item;
  }
}