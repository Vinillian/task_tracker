import '../models/recurrence_completion.dart';
import '../models/task.dart';

class RecurrenceCompletionService {
  static final List<RecurrenceCompletion> _completions = [];

  static bool isOccurrenceCompleted(Task task, DateTime occurrenceDate) {
    return _completions.any((completion) =>
    completion.taskId == _getTaskId(task) &&
        RecurrenceCompletion.isSameDay(completion.occurrenceDate, occurrenceDate));
  }

  static void markOccurrenceCompleted(Task task, DateTime occurrenceDate) {
    _completions.add(RecurrenceCompletion(
      taskId: _getTaskId(task),
      occurrenceDate: DateTime(occurrenceDate.year, occurrenceDate.month, occurrenceDate.day),
      completedAt: DateTime.now(),
    ));
  }

  static void unmarkOccurrenceCompleted(Task task, DateTime occurrenceDate) {
    _completions.removeWhere((completion) =>
    completion.taskId == _getTaskId(task) &&
        RecurrenceCompletion.isSameDay(completion.occurrenceDate, occurrenceDate));
  }

  static String _getTaskId(Task task) {
    return '${task.name}_${task.totalSteps}';
  }

  static void reset() {
    _completions.clear();
  }

}