import '../models/task.dart';
import '../models/recurrence_completion.dart';
import 'completion_service.dart';

class RecurrenceCompletionService {
  final CompletionService _completionService;

  RecurrenceCompletionService(this._completionService);

  // Отмечает выполнение повторяющейся задачи на конкретную дату
  RecurrenceCompletion completeRecurrenceTask(
      Task task,
      DateTime completionDate,
      ) {
    // Создаем запись о выполнении
    final completion = RecurrenceCompletion(
      id: '${task.id}_${completionDate.millisecondsSinceEpoch}',
      originalTaskId: task.id,
      taskTitle: task.title,
      completedAt: completionDate,
      taskType: task.type,
      projectId: task.projectId,
    );

    // TODO: Сохранить completion в репозитории

    return completion;
  }

  // Отменяет выполнение повторяющейся задачи
  void uncompleteRecurrenceTask(String completionId) {
    // TODO: Удалить запись о выполнении из репозитории
  }

  // Получает историю выполнений для повторяющейся задачи
  List<DateTime> getCompletionHistory(
      String taskId,
      List<RecurrenceCompletion> allCompletions
      ) {
    return allCompletions
        .where((completion) => completion.originalTaskId == taskId)
        .map((completion) => completion.completedAt)
        .toList();
  }

  // Проверяет, выполнена ли задача на конкретную дату
  bool isTaskCompletedOnDate(
      String taskId,
      DateTime date,
      List<RecurrenceCompletion> allCompletions
      ) {
    final dateKey = DateTime(date.year, date.month, date.day);

    return allCompletions.any((completion) {
      if (completion.originalTaskId != taskId) return false;

      final completedDate = completion.completedAt;
      final completedDateKey = DateTime(
          completedDate.year,
          completedDate.month,
          completedDate.day
      );

      return completedDateKey == dateKey;
    });
  }

  // Получает статистику выполнений для задачи
  Map<String, dynamic> getCompletionStats(
  String taskId,
  List<RecurrenceCompletion> allCompletions,
  int daysBack = 30
  ) {
  final taskCompletions = allCompletions
      .where((completion) => completion.originalTaskId == taskId)
      .toList();

  final now = DateTime.now();
  final startDate = now.subtract(Duration(days: daysBack));

  final recentCompletions = taskCompletions
      .where((completion) => completion.completedAt.isAfter(startDate))
      .length;

  return {
  'totalCompletions': taskCompletions.length,
  'recentCompletions': recentCompletions,
  'completionRate': daysBack > 0 ? recentCompletions / daysBack : 0,
  'lastCompletion': taskCompletions.isNotEmpty
  ? taskCompletions.last.completedAt
      : null,
  };
  }
}