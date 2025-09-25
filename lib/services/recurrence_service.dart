import 'package:flutter/material.dart';
import '../models/recurrence.dart';

class RecurrenceService {
  // Генерация occurrences (вхождений) повторяющейся задачи
  static List<DateTime> generateOccurrences({
    required Recurrence recurrence,
    required DateTime startDate,
    int count = 10, // Сколько occurrences сгенерировать
    DateTime? untilDate, // Альтернатива count - генерировать до определенной даты
  }) {
    final occurrences = <DateTime>[];
    var currentDate = startDate;
    int generatedCount = 0;

    while (generatedCount < count && (untilDate == null || currentDate.isBefore(untilDate))) {
      occurrences.add(currentDate);
      generatedCount++;

      // Вычисляем следующую дату в зависимости от типа повторения
      switch (recurrence.type) {
        case RecurrenceType.daily:
          currentDate = currentDate.add(Duration(days: recurrence.interval));
          break;
        case RecurrenceType.weekly:
          currentDate = currentDate.add(Duration(days: 7 * recurrence.interval));
          break;
        case RecurrenceType.monthly:
          currentDate = DateTime(currentDate.year, currentDate.month + recurrence.interval, currentDate.day);
          break;
        case RecurrenceType.yearly:
          currentDate = DateTime(currentDate.year + recurrence.interval, currentDate.month, currentDate.day);
          break;
        case RecurrenceType.custom:
          if (recurrence.daysOfWeek.isNotEmpty) {
            currentDate = _getNextCustomDate(currentDate, recurrence);
          } else {
            currentDate = currentDate.add(Duration(days: recurrence.interval));
          }
          break;
      }
    }

    return occurrences;
  }

  // Вспомогательный метод для пользовательского повторения (дни недели)
  static DateTime _getNextCustomDate(DateTime currentDate, Recurrence recurrence) {
    var nextDate = currentDate.add(const Duration(days: 1));

    while (!recurrence.daysOfWeek.contains(nextDate.weekday)) {
      nextDate = nextDate.add(const Duration(days: 1));
    }

    return nextDate;
  }

  // Проверка, должна ли задача повторяться сегодня
  static bool shouldOccurToday(Recurrence recurrence, DateTime startDate) {
    final today = DateTime.now();
    final occurrences = generateOccurrences(
      recurrence: recurrence,
      startDate: startDate,
      untilDate: today.add(const Duration(days: 1)),
    );

    return occurrences.any((date) =>
    date.year == today.year &&
        date.month == today.month &&
        date.day == today.day);
  }

  // Получение следующей даты выполнения
  static DateTime? getNextOccurrence(Recurrence recurrence, DateTime lastOccurrence) {
    final occurrences = generateOccurrences(
      recurrence: recurrence,
      startDate: lastOccurrence,
      count: 2,
    );

    return occurrences.length > 1 ? occurrences[1] : null;
  }

  // Валидация правил повторения
  static String? validateRecurrence(Recurrence recurrence) {
    if (recurrence.interval < 1) {
      return 'Интервал должен быть положительным числом';
    }

    if (recurrence.type == RecurrenceType.custom && recurrence.daysOfWeek.isEmpty) {
      return 'Для пользовательского повторения выберите хотя бы один день недели';
    }

    return null;
  }

  // Автоматический перенос ежедневных задач на следующий день
  static DateTime? getNextOccurrenceForDailyTask(DateTime currentDate, Recurrence recurrence) {
    if (recurrence.type != RecurrenceType.daily) return null;
    return currentDate.add(Duration(days: recurrence.interval));
  }

  static bool shouldMoveToNextDay(DateTime plannedDate, Recurrence? recurrence) {
    if (recurrence == null) return false;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final plannedDay = DateTime(plannedDate.year, plannedDate.month, plannedDate.day);

    return plannedDay.isBefore(today) && recurrence.type == RecurrenceType.daily;
  }

  static int getWeekOfMonth(DateTime date) {
    final firstDayOfMonth = DateTime(date.year, date.month, 1);
    final dayOfMonth = date.day;
    final firstDayWeekday = firstDayOfMonth.weekday;

    return ((dayOfMonth + firstDayWeekday - 2) ~/ 7) + 1;
  }

  static bool isOddWeek(DateTime date) {
    return getWeekOfMonth(date).isOdd;
  }

  static DateTime getCurrentPeriodStart() {
    final now = DateTime.now();
    final start = now.subtract(Duration(days: now.weekday - 1));
    return DateTime(start.year, start.month, start.day);
  }

  static DateTime getPeriodStartFromOddWeek() {
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final weekNumber = getWeekOfMonth(now);

    final startWeek = weekNumber.isOdd ? weekNumber : weekNumber - 1;
    return firstDayOfMonth.add(Duration(days: (startWeek - 1) * 7));
  }

  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  static bool isPastDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final checkDate = DateTime(date.year, date.month, date.day);
    return checkDate.isBefore(today);
  }

  static bool isFutureDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final checkDate = DateTime(date.year, date.month, date.day);
    return checkDate.isAfter(today);
  }

  static String getRecurrenceDisplayName(Recurrence recurrence) {
    switch (recurrence.type) {
      case RecurrenceType.daily:
        return recurrence.interval == 1 ? 'Ежедневно' : 'Каждые ${recurrence.interval} дней';
      case RecurrenceType.weekly:
        return recurrence.interval == 1 ? 'Еженедельно' : 'Каждые ${recurrence.interval} недель';
      case RecurrenceType.monthly:
        return recurrence.interval == 1 ? 'Ежемесячно' : 'Каждые ${recurrence.interval} месяцев';
      case RecurrenceType.yearly:
        return recurrence.interval == 1 ? 'Ежегодно' : 'Каждые ${recurrence.interval} лет';
      case RecurrenceType.custom:
        if (recurrence.daysOfWeek.isNotEmpty) {
          final days = recurrence.daysOfWeek.map((day) {
            switch (day) {
              case 1: return 'Пн';
              case 2: return 'Вт';
              case 3: return 'Ср';
              case 4: return 'Чт';
              case 5: return 'Пт';
              case 6: return 'Сб';
              case 7: return 'Вс';
              default: return '';
            }
          }).where((day) => day.isNotEmpty).toList();
          return 'По ${days.join(', ')}';
        }
        return 'По расписанию';
    }
  }

  static Recurrence createDailyRecurrence({int interval = 1}) {
    return Recurrence(type: RecurrenceType.daily, interval: interval);
  }

  static Recurrence createWeeklyRecurrence({int interval = 1}) {
    return Recurrence(type: RecurrenceType.weekly, interval: interval);
  }

  static Recurrence createMonthlyRecurrence({int interval = 1}) {
    return Recurrence(type: RecurrenceType.monthly, interval: interval);
  }

  static Recurrence createCustomRecurrence({required List<int> daysOfWeek, int interval = 1}) {
    return Recurrence(
      type: RecurrenceType.custom,
      interval: interval,
      daysOfWeek: daysOfWeek,
    );
  }

  static DateTime getNextOccurrenceAfterDate(Recurrence recurrence, DateTime startDate, DateTime afterDate) {
    final allOccurrences = generateOccurrences(
      recurrence: recurrence,
      startDate: startDate,
      untilDate: afterDate.add(const Duration(days: 365)),
    );

    for (final occurrence in allOccurrences) {
      if (occurrence.isAfter(afterDate)) {
        return occurrence;
      }
    }

    return allOccurrences.isNotEmpty
        ? allOccurrences.last.add(Duration(days: recurrence.interval))
        : afterDate.add(Duration(days: recurrence.interval));
  }
}
