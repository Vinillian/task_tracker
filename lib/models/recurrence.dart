import 'package:hive/hive.dart';

part 'recurrence.g.dart';

@HiveType(typeId: 5)
class Recurrence {
  @HiveField(0)
  final RecurrenceType type;

  @HiveField(1)
  final int interval;

  @HiveField(2)
  final List<int> daysOfWeek;

  Recurrence({
    required this.type,
    this.interval = 1,
    this.daysOfWeek = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'type': type.toString(),
      'interval': interval,
      'daysOfWeek': daysOfWeek,
    };
  }

  static Recurrence fromMap(Map<String, dynamic> data) {
    return Recurrence(
      type: RecurrenceType.fromString(data['type'] ?? 'daily'),
      interval: data['interval'] ?? 1,
      daysOfWeek: List<int>.from(data['daysOfWeek'] ?? []),
    );
  }

  String get displayText {
    switch (type) {
      case RecurrenceType.daily:
        return interval == 1 ? 'Ежедневно' : 'Каждые $interval дней';
      case RecurrenceType.weekly:
        return 'Еженедельно';
      case RecurrenceType.monthly:
        return interval == 1 ? 'Ежемесячно' : 'Каждые $interval месяцев';
      case RecurrenceType.yearly:
        return interval == 1 ? 'Ежегодно' : 'Каждые $interval лет';
      case RecurrenceType.custom:
        return 'По расписанию';
    }
  }
}

enum RecurrenceType {
  daily,
  weekly,
  monthly,
  yearly,
  custom;

  static RecurrenceType fromString(String value) {
    switch (value) {
      case 'daily': return RecurrenceType.daily;
      case 'weekly': return RecurrenceType.weekly;
      case 'monthly': return RecurrenceType.monthly;
      case 'yearly': return RecurrenceType.yearly;
      case 'custom': return RecurrenceType.custom;
      default: return RecurrenceType.daily;
    }
  }

  @override
  String toString() => this.name;
}