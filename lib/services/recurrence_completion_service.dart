// lib/services/recurrence_completion_service.dart
import '../models/recurrence_completion.dart';
import '../models/task.dart';
import '../repositories/local_repository.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';


class RecurrenceCompletionService {
  static Future<bool> isOccurrenceCompleted(Task task, DateTime occurrenceDate, BuildContext context) async {
    final localRepo = Provider.of<LocalRepository>(context, listen: false);
    final completions = await _loadCompletions(localRepo);

    return completions.any((completion) =>
    completion.taskId == _getTaskId(task) &&
        RecurrenceCompletion.isSameDay(completion.occurrenceDate, occurrenceDate));
  }

  static Future<void> markOccurrenceCompleted(Task task, DateTime occurrenceDate, BuildContext context) async {
    final localRepo = Provider.of<LocalRepository>(context, listen: false);
    final completions = await _loadCompletions(localRepo);

    completions.add(RecurrenceCompletion(
      taskId: _getTaskId(task),
      occurrenceDate: DateTime(occurrenceDate.year, occurrenceDate.month, occurrenceDate.day),
      completedAt: DateTime.now(),
    ));

    await _saveCompletions(completions, localRepo);
  }

  static Future<void> unmarkOccurrenceCompleted(Task task, DateTime occurrenceDate, BuildContext context) async {
    final localRepo = Provider.of<LocalRepository>(context, listen: false);
    final completions = await _loadCompletions(localRepo);

    completions.removeWhere((completion) =>
    completion.taskId == _getTaskId(task) &&
        RecurrenceCompletion.isSameDay(completion.occurrenceDate, occurrenceDate));

    await _saveCompletions(completions, localRepo);
  }

  static String _getTaskId(Task task) {
    // Более уникальный идентификатор
    return '${task.name}_${task.totalSteps}_${task.plannedDate?.millisecondsSinceEpoch ?? 0}';
  }

  static Future<List<RecurrenceCompletion>> _loadCompletions(LocalRepository localRepo) async {
    Box<RecurrenceCompletion> box;
    if (Hive.isBoxOpen('recurrenceCompletions')) {
      box = Hive.box<RecurrenceCompletion>('recurrenceCompletions');
    } else {
      box = await Hive.openBox<RecurrenceCompletion>('recurrenceCompletions');
    }
    return box.values.toList();
  }


  static Future<void> _saveCompletions(List<RecurrenceCompletion> completions, LocalRepository localRepo) async {
    Box<RecurrenceCompletion> box;
    if (Hive.isBoxOpen('recurrenceCompletions')) {
      box = Hive.box<RecurrenceCompletion>('recurrenceCompletions');
    } else {
      box = await Hive.openBox<RecurrenceCompletion>('recurrenceCompletions');
    }

    await box.clear();
    await box.addAll(completions);
  }


}