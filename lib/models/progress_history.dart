import 'package:cloud_firestore/cloud_firestore.dart';

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

  Map<String, dynamic> toFirestore() => {
    'date': Timestamp.fromDate(date),
    'itemName': itemName,
    'stepsAdded': stepsAdded,
    'itemType': itemType,
  };

  factory ProgressHistory.fromFirestore(Map<String, dynamic> data) {
    final dynamic rawDate = data['date'];
    final date = rawDate is Timestamp
        ? rawDate.toDate()
        : rawDate is String
        ? DateTime.parse(rawDate)
        : DateTime.now();

    return ProgressHistory(
      date: date,
      itemName: data['itemName'] ?? '',
      stepsAdded: data['stepsAdded'] ?? 0,
      itemType: data['itemType'] ?? '',
    );
  }

  factory ProgressHistory.fromJson(Map<String, dynamic> json) => ProgressHistory(
    date: DateTime.parse(json['date']),
    itemName: json['itemName'],
    stepsAdded: json['stepsAdded'],
    itemType: json['itemType'],
  );
}