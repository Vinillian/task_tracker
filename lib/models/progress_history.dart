import 'package:intl/intl.dart';

class ProgressHistory {
  final DateTime date;
  final String itemName;
  final int stepsAdded;
  final String itemType;

  ProgressHistory({
    required this.date,
    required this.itemName,
    required this.stepsAdded,
    required this.itemType,
  });

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'itemName': itemName,
    'stepsAdded': stepsAdded,
    'itemType': itemType,
  };

  factory ProgressHistory.fromJson(Map<String, dynamic> json) {
    return ProgressHistory(
      date: DateTime.parse(json['date']),
      itemName: json['itemName'],
      stepsAdded: json['stepsAdded'],
      itemType: json['itemType'],
    );
  }
}