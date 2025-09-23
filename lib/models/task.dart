import 'stage.dart';
import 'package:hive/hive.dart';
import 'task_type.dart';
import 'recurrence.dart';
import 'package:flutter/material.dart'; // ← ДОБАВИТЬ ЭТУ СТРОКУ
part 'task.g.dart';

@HiveType(typeId: 2)
class Task {
  @HiveField(0)
  final String name;

  @HiveField(1)
  final int completedSteps;

  @HiveField(2)
  final int totalSteps;

  @HiveField(3)
  final List<Stage> stages; // ← ИЗМЕНИЛИ с subtasks на stages

  @HiveField(4)
  final String taskType;

  @HiveField(5)
  final Recurrence? recurrence;

  @HiveField(6)
  final DateTime? dueDate;

  @HiveField(7)
  final bool isCompleted;

  @HiveField(8)
  final String? description;

  @HiveField(9)
  final DateTime? plannedDate;

  @HiveField(10) // Новое поле - следующий доступный номер
  final int colorValue; // Будем хранить как int (цвет в формате 0xAARRGGBB)


  Task({
    required this.name,
    this.completedSteps = 0,
    required this.totalSteps,
    List<Stage>? stages,
    this.taskType = 'stepByStep',
    this.recurrence,
    this.dueDate,
    this.isCompleted = false,
    this.description,
    this.plannedDate,
    this.colorValue = 0xFF2196F3, // Синий по умолчанию
  }) : stages = stages ?? [];

  // Добавляем геттер для удобства
  Color get color => Color(colorValue);

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'completedSteps': completedSteps,
      'totalSteps': totalSteps,
      'stages': stages.map((s) => s.toFirestore()).toList(),
      'taskType': taskType.toString(),
      'recurrence': recurrence?.toMap(),
      'dueDate': dueDate?.toIso8601String(),
      'isCompleted': isCompleted,
      'description': description,
      'plannedDate': plannedDate?.toIso8601String(), // Добавлено
      'colorValue': colorValue, // Добавляем цвет
    };
  }

  static Task fromFirestore(Map<String, dynamic> data) {
    return Task(
      name: data['name'] ?? '',
      completedSteps: data['completedSteps'] ?? 0,
      totalSteps: data['totalSteps'] ?? 1,
      stages: (data['stages'] as List<dynamic>?)
          ?.map((s) => Stage.fromFirestore(s))
          .toList() ?? [],
      taskType: data['taskType'] ?? 'stepByStep',
      recurrence: data['recurrence'] != null
          ? Recurrence.fromMap(data['recurrence'])
          : null,
      dueDate: data['dueDate'] != null
          ? DateTime.parse(data['dueDate'])
          : null,
      isCompleted: data['isCompleted'] ?? false,
      description: data['description'],
      plannedDate: data['plannedDate'] != null // Добавлено
          ? DateTime.parse(data['plannedDate'])
          : null,
      colorValue: data['colorValue'] ?? 0xFF2196F3, // Новое поле
    );
  }
}