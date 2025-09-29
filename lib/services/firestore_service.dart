import '../models/task.dart';
import '../models/recurrence.dart';

class RecurrenceService {
  // Проверяет, нужно ли создавать новое выполнение для повторяющейся задачи
  bool shouldCreateRecurrenceInstance(Task task, DateTime date) {
    if (!task.type.isRecurring) return false;
    if (task.recurrencePattern == null) return false;

    final pattern = task.recurrencePattern!;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final checkDate = DateTime(date.year, date.month, date.day);

    switch (pattern.frequency) {
      case RecurrenceFrequency.daily:
        return _isDailyRecurrence(checkDate, pattern);
      case RecurrenceFrequency.weekly:
        return _isWeeklyRecurrence(checkDate, pattern);
      case RecurrenceFrequency.monthly:
        return _isMonthlyRecurrence(checkDate, pattern);
      case RecurrenceFrequency.yearly:
        return _isYearlyRecurrence(checkDate, pattern);
      default:
        return false;
    }
  }

  // Создает экземпляр выполнения для повторяющейся задачи
  Task createRecurrenceInstance(Task originalTask, DateTime date) {
    return originalTask.copyWith(
      id: '${originalTask.id}_${date.millisecondsSinceEpoch}',
      isCompleted: false,
      completedSubtasks: 0,
      // Сбрасываем прогресс подзадач для нового экземпляра
      subtasks: originalTask.subtasks.map((subtask) =>
          subtask.copyWith(
            isCompleted: false,
            completedSubtasks: 0,
          )
      ).toList(),
      createdAt: date,
      completedAt: null,
    );
  }

  // Получает все даты, когда должна появляться повторяющаяся задача
  List<DateTime> getRecurrenceDates(Task task, {int daysAhead = 30}) {
    if (!task.type.isRecurring || task.recurrencePattern == null) {
      return [];
    }

    final dates = <DateTime>[];
    final now = DateTime.now();
    final endDate = now.add(Duration(days: daysAhead));

    DateTime currentDate = DateTime(now.year, now.month, now.day);

    while (currentDate.isBefore(endDate)) {
      if (shouldCreateRecurrenceInstance(task, currentDate)) {
        dates.add(currentDate);
      }
      currentDate = currentDate.add(Duration(days: 1));
    }

    return dates;
  }

  // Проверяет, выполнена ли уже повторяющаяся задача на конкретную дату
  bool isRecurrenceCompletedForDate(
      Task task,
      DateTime date,
      List<Task> completionHistory
      ) {
    final dateKey = DateTime(date.year, date.month, date.day);

    return completionHistory.any((completedTask) {
      if (completedTask.originalTaskId != task.id) return false;

      final completedDate = completedTask.completedAt;
      if (completedDate == null) return false;

      final completedDateKey = DateTime(
          completedDate.year,
          completedDate.month,
          completedDate.day
      );

      return completedDateKey == dateKey;
    });
  }

  // === ПРИВАТНЫЕ МЕТОДЫ ДЛЯ ПРОВЕРКИ ПОВТОРЕНИЙ ===

  bool _isDailyRecurrence(DateTime date, RecurrencePattern pattern) {
    final now = DateTime.now();
    final startDate = pattern.startDate ?? now;
    final startDateKey = DateTime(startDate.year, startDate.month, startDate.day);
    final dateKey = DateTime(date.year, date.month, date.day);

    // Проверяем, что дата после startDate
    if (dateKey.isBefore(startDateKey)) return false;

    // Проверяем интервал
    final daysSinceStart = dateKey.difference(startDateKey).inDays;
    return daysSinceStart % pattern.interval == 0;
  }

  bool _isWeeklyRecurrence(DateTime date, RecurrencePattern pattern) {
    final now = DateTime.now();
    final startDate = pattern.startDate ?? now;
    final startDateKey = DateTime(startDate.year, startDate.month, startDate.day);
    final dateKey = DateTime(date.year, date.month, date.day);

    if (dateKey.isBefore(startDateKey)) return false;

    // Проверяем день недели
    if (pattern.daysOfWeek != null &&
        pattern.daysOfWeek!.isNotEmpty &&
        !pattern.daysOfWeek!.contains(date.weekday)) {
      return false;
    }

    // Проверяем интервал в неделях
    final weeksSinceStart = dateKey.difference(startDateKey).inDays ~/ 7;
    return weeksSinceStart % pattern.interval == 0;
  }

  bool _isMonthlyRecurrence(DateTime date, RecurrencePattern pattern) {
    final now = DateTime.now();
    final startDate = pattern.startDate ?? now;
    final startDateKey = DateTime(startDate.year, startDate.month, startDate.day);
    final dateKey = DateTime(date.year, date.month, date.day);

    if (dateKey.isBefore(startDateKey)) return false;

    // Проверяем день месяца
    if (pattern.dayOfMonth != null && pattern.dayOfMonth != date.day) {
      return false;
    }

    // Проверяем интервал в месяцах
    final monthsSinceStart = (date.year - startDate.year) * 12 +
        date.month - startDate.month;
    return monthsSinceStart % pattern.interval == 0;
  }

  bool _isYearlyRecurrence(DateTime date, RecurrencePattern pattern) {
    final now = DateTime.now();
    final startDate = pattern.startDate ?? now;
    final startDateKey = DateTime(startDate.year, startDate.month, startDate.day);
    final dateKey = DateTime(date.year, date.month, date.day);

    if (dateKey.isBefore(startDateKey)) return false;

    // Проверяем день и месяц
    if (pattern.dayOfMonth != null && pattern.dayOfMonth != date.day) {
      return false;
    }
    if (pattern.monthOfYear != null && pattern.monthOfYear != date.month) {
      return false;
    }

    // Проверяем интервал в годах
    final yearsSinceStart = date.year - startDate.year;
    return yearsSinceStart % pattern.interval == 0;
  }

  // Валидация паттерна повторения
  bool validateRecurrencePattern(RecurrencePattern pattern) {
    if (pattern.interval < 1) return false;
    if (pattern.startDate != null && pattern.endDate != null) {
      if (pattern.startDate!.isAfter(pattern.endDate!)) return false;
    }

    switch (pattern.frequency) {
      case RecurrenceFrequency.weekly:
        if (pattern.daysOfWeek != null) {
          for (final day in pattern.daysOfWeek!) {
            if (day < 1 || day > 7) return false;
          }
        }
        break;
      case RecurrenceFrequency.monthly:
      case RecurrenceFrequency.yearly:
        if (pattern.dayOfMonth != null &&
            (pattern.dayOfMonth! < 1 || pattern.dayOfMonth! > 31)) {
          return false;
        }
        break;
      case RecurrenceFrequency.yearly:
        if (pattern.monthOfYear != null &&
            (pattern.monthOfYear! < 1 || pattern.monthOfYear! > 12)) {
          return false;
        }
        break;
      default:
        break;
    }

    return true;
  }

  // Создает дефолтный паттерн повторения
  RecurrencePattern createDefaultRecurrencePattern() {
    return RecurrencePattern(
      frequency: RecurrenceFrequency.daily,
      interval: 1,
      startDate: DateTime.now(),
    );
  }

  // Получает описание паттерна для UI
  String getRecurrenceDescription(RecurrencePattern pattern) {
    switch (pattern.frequency) {
      case RecurrenceFrequency.daily:
        return pattern.interval == 1
            ? 'Ежедневно'
            : 'Каждые ${pattern.interval} дней';

      case RecurrenceFrequency.weekly:
        if (pattern.daysOfWeek != null && pattern.daysOfWeek!.isNotEmpty) {
          final days = pattern.daysOfWeek!.map(_getDayName).join(', ');
          return pattern.interval == 1
              ? 'Еженедельно по $days'
              : 'Каждые ${pattern.interval} недель по $days';
        }
        return pattern.interval == 1
            ? 'Еженедельно'
            : 'Каждые ${pattern.interval} недель';

      case RecurrenceFrequency.monthly:
        final dayDesc = pattern.dayOfMonth != null
            ? '${pattern.dayOfMonth}-го числа'
            : 'в этот же день';
        return pattern.interval == 1
            ? 'Ежемесячно $dayDesc'
            : 'Каждые ${pattern.interval} месяцев $dayDesc';

      case RecurrenceFrequency.yearly:
        final monthDesc = pattern.monthOfYear != null
            ? '${_getMonthName(pattern.monthOfYear!)}'
            : 'в этот же месяц';
        final dayDesc = pattern.dayOfMonth != null
            ? '${pattern.dayOfMonth}-го числа'
            : 'в этот же день';
        return pattern.interval == 1
            ? 'Ежегодно $dayDesc $monthDesc'
            : 'Каждые ${pattern.interval} лет $dayDesc $monthDesc';
    }
  }

  String _getDayName(int day) {
    const days = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
    return days[day - 1];
  }

  String _getMonthName(int month) {
    const months = [
      'Января', 'Февраля', 'Марта', 'Апреля', 'Мая', 'Июня',
      'Июля', 'Августа', 'Сентября', 'Октября', 'Ноября', 'Декабря'
    ];
    return months[month - 1];
  }
}