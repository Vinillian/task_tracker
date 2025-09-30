import 'package:hive/hive.dart';

part 'recurrence_completion.g.dart';

@HiveType(typeId: 9)
class RecurrenceCompletion {
  @HiveField(0)
  final String taskId;

  @HiveField(1)
  final DateTime occurrenceDate;

  @HiveField(2)
  final DateTime completedAt;

  RecurrenceCompletion({
    required this.taskId,
    required this.occurrenceDate,
    required this.completedAt,
  });

  // Метод для сравнения дат без времени
  static bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }
}