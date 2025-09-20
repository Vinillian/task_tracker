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
}