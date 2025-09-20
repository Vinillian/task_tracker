import 'package:flutter/material.dart';
import '../models/recurrence.dart';

class RecurrenceService {
  // Генерацияoccurrences (вхождений) повторяющейся задачи
  static List<DateTime> generateOccurrences({
    required Recurrence recurrence,
    required DateTime startDate,
    int count = 10, // Сколькоoccurrences сгенерировать
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
        // Для пользовательского повторения (например, определенные дни недели)
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

    // Ищем следующий день, который есть в списке дней недели
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
      untilDate: today.add(const Duration(days: 1)), // Генерируем до завтра
    );

    // Проверяем, есть ли сегодня в сгенерированныхoccurrences
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
      count: 2, // Нужен только следующий occurrence
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
}