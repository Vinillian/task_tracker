import 'package:hive/hive.dart';

part 'recurrence.g.dart';

/// Модель повторения задач для Hive + Firestore
@HiveType(typeId: 5)
class Recurrence {
  @HiveField(0)
  final RecurrenceType type;

  @HiveField(1)
  final int interval;

  /// Для custom-типа: список дней недели (1 = Пн, 7 = Вс)
  @HiveField(2)
  final List<int> daysOfWeek;

  Recurrence({
    required this.type,
    this.interval = 1,
    this.daysOfWeek = const [],
  });

  /// Преобразование в Map (например, для Firestore)
  Map<String, dynamic> toMap() {
    return {
      'type': type.toString(),
      'interval': interval,
      'daysOfWeek': daysOfWeek,
    };
  }

  /// Восстановление из Map (например, из Firestore)
  static Recurrence fromMap(Map<String, dynamic> data) {
    return Recurrence(
      type: RecurrenceType.fromString(data['type'] ?? 'daily'),
      interval: data['interval'] ?? 1,
      daysOfWeek: List<int>.from(data['daysOfWeek'] ?? []),
    );
  }

  /// Красивое отображение для UI
  String get displayText {
    switch (type) {
      case RecurrenceType.daily:
        return interval == 1 ? 'Ежедневно' : 'Каждые $interval дней';
      case RecurrenceType.weekly:
        return interval == 1 ? 'Еженедельно' : 'Каждые $interval недель';
      case RecurrenceType.monthly:
        return interval == 1 ? 'Ежемесячно' : 'Каждые $interval месяцев';
      case RecurrenceType.yearly:
        return interval == 1 ? 'Ежегодно' : 'Каждые $interval лет';
      case RecurrenceType.custom:
        if (daysOfWeek.isNotEmpty) {
          final days = daysOfWeek.map((day) {
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
          }).where((d) => d.isNotEmpty).toList();
          return 'По ${days.join(', ')}';
        }
        return 'По расписанию';
    }
  }
}

@HiveType(typeId: 6)
enum RecurrenceType {
  @HiveField(0)
  daily,
  @HiveField(1)
  weekly,
  @HiveField(2)
  monthly,
  @HiveField(3)
  yearly,
  @HiveField(4)
  custom;

  /// Преобразование из строки (например, при загрузке из Firestore)
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

  /// Для сохранения в Firestore
  @override
  String toString() => name;
}
