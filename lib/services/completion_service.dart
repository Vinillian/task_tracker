// lib/services/completion_service.dart
import '../models/task.dart';
import '../models/stage.dart';
import '../models/step.dart' as custom_step;
import '../models/progress_history.dart';
import '../services/task_service.dart';

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

    print('🔄 Выполнение элемента: $itemName, тип: $itemType, шаги: $stepsAdded');

    // Обновляем элемент в зависимости от его типа
    if (item is Task) {
      if (item.taskType == "singleStep") {
        print('✅ Это одношаговая задача - переключаем выполнение');
        updatedItem = TaskService.toggleTaskCompletion(item);
        actualSteps = updatedItem.isCompleted ? 1 : -1;
        print('📊 Новый статус выполнения: ${updatedItem.isCompleted}');
      } else {
        print('✅ Это пошаговая задача - добавляем прогресс');
        updatedItem = TaskService.addProgressToTask(item, stepsAdded);
        actualSteps = stepsAdded;
      }
    } else if (item is Stage) {
      if (item.stageType == "singleStep") {
        print('✅ Это одношаговый этап - переключаем выполнение');
        updatedItem = TaskService.toggleStageCompletion(item);
        actualSteps = updatedItem.isCompleted ? 1 : -1;
      } else {
        print('✅ Это пошаговый этап - добавляем прогресс');
        updatedItem = TaskService.addProgressToStage(item, stepsAdded);
        actualSteps = stepsAdded;
      }
    } else if (item is custom_step.Step) {
      if (item.stepType == "singleStep") {
        print('✅ Это одношаговый шаг - переключаем выполнение');
        updatedItem = TaskService.toggleStepCompletion(item);
        actualSteps = updatedItem.isCompleted ? 1 : -1;
      } else {
        print('✅ Это пошаговый шаг - добавляем прогресс');
        updatedItem = TaskService.addProgressToStep(item, stepsAdded);
        actualSteps = stepsAdded;
      }
    } else {
      print('❌ Неизвестный тип элемента: ${item.runtimeType}');
      return {
        'updatedItem': item,
        'progressHistory': ProgressHistory(
          date: DateTime.now(),
          itemName: itemName,
          stepsAdded: 0,
          itemType: itemType,
        ),
      };
    }

    // Создаем запись в истории прогресса
    final progressHistory = ProgressHistory(
      date: DateTime.now(),
      itemName: itemName,
      stepsAdded: actualSteps,
      itemType: itemType,
    );

    print('📝 Создана запись истории: $itemName, шагов: $actualSteps');

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

      print('✅ Добавлено в историю прогресса');

      return {
        'updatedItem': result['updatedItem'],
        'updatedHistory': updatedHistory,
      };
    }

    print('⚠️ Изменений нет, история не обновлена');

    return {
      'updatedItem': result['updatedItem'],
      'updatedHistory': currentHistory,
    };
  }

  // Обработка выполнения с автоматическим переносом daily задач

  static Map<String, dynamic> completeItemWithAutoMove({
    required dynamic item,
    required int stepsAdded,
    required String itemName,
    required String itemType,
    required List<dynamic> currentHistory,
  }) {
    print('🔄 Выполнение с авто-переносом: $itemName');

    // Для recurring задач - просто выполняем без изменений оригинала
    // Статус будет сбрасываться отдельным механизмом
    return completeItemWithHistory(
      item: item,
      stepsAdded: stepsAdded,
      itemName: itemName,
      itemType: itemType,
      currentHistory: currentHistory,
    );
  }

  // Добавьте этот метод в CompletionService
  static Map<String, dynamic> completeRecurringTask(Task task, int stepsAdded) {
    //final bool wasCompleted = task.isCompleted;


    // Для recurring задач просто добавляем прогресс в историю
    // но не меняем основной статус выполнения
    final progressHistory = ProgressHistory(
      date: DateTime.now(),
      itemName: task.name,
      stepsAdded: stepsAdded,
      itemType: 'task',
    );

    return {
      'updatedItem': task, // Не меняем задачу для recurring
      'progressHistory': progressHistory,
    };
  }
}