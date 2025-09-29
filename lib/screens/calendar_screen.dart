import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/app_user.dart';
import '../models/task.dart';
import '../models/stage.dart';
import '../models/step.dart' as custom_step;
import '../widgets/detailed_completion_dialog.dart';
import '../services/recurrence_service.dart';
import '../services/recurrence_completion_service.dart';

class CalendarScreen extends StatefulWidget {
  final AppUser? currentUser;
  final Function(Map<String, dynamic>) onItemCompleted;

  const CalendarScreen({
    super.key,
    required this.currentUser,
    required this.onItemCompleted,
  });

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  /// Построение списка задач
  Future<Map<DateTime, List<Map<String, dynamic>>>> _getPlannedItems() async {
    final plannedItems = <DateTime, List<Map<String, dynamic>>>{};

    if (widget.currentUser == null) return plannedItems;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    for (final project in widget.currentUser!.projects) {
      for (final task in project.tasks) {
        // Recurring задачи
        if (task.recurrence != null && task.plannedDate != null) {
          final occurrences = RecurrenceService.generateOccurrences(
            recurrence: task.recurrence!,
            startDate: task.plannedDate!,
            untilDate: DateTime.now().add(const Duration(days: 365)),
          );

          for (final occurrence in occurrences) {
            final date = DateTime(occurrence.year, occurrence.month, occurrence.day);

            if (date.isAfter(today.subtract(const Duration(days: 1))) || isSameDay(date, today)) {
              final isCompleted = await _isOccurrenceCompleted(task, occurrence);
              plannedItems.putIfAbsent(date, () => []).add({
                'type': 'task',
                'item': task,
                'project': project,
                'name': task.name,
                'isRecurring': true,
                'occurrenceDate': occurrence,
                'isCompleted': isCompleted,
                'originalPlannedDate': task.plannedDate,
              });
            }
          }
        }
        // Non-recurring задачи
        else if (task.plannedDate != null && task.recurrence == null && !task.isCompleted) {
          final date = DateTime(task.plannedDate!.year, task.plannedDate!.month, task.plannedDate!.day);
          if (!date.isBefore(today)) {
            plannedItems.putIfAbsent(date, () => []).add({
              'type': 'task',
              'item': task,
              'project': project,
              'name': task.name,
              'isRecurring': false,
              'isCompleted': task.isCompleted,
            });
          }
        }

        // Этапы
        for (final stage in task.stages) {
          if (stage.recurrence != null && stage.plannedDate != null) {
            final occurrences = RecurrenceService.generateOccurrences(
              recurrence: stage.recurrence!,
              startDate: stage.plannedDate!,
              untilDate: DateTime.now().add(const Duration(days: 365)),
            );

            for (final occurrence in occurrences) {
              final date = DateTime(occurrence.year, occurrence.month, occurrence.day);

              if (date.isAfter(today.subtract(const Duration(days: 1))) || isSameDay(date, today)) {
                final isCompleted = await _isOccurrenceCompletedForStage(stage, occurrence);
                plannedItems.putIfAbsent(date, () => []).add({
                  'type': 'stage',
                  'item': stage,
                  'project': project,
                  'task': task,
                  'name': stage.name,
                  'isRecurring': true,
                  'occurrenceDate': occurrence,
                  'isCompleted': isCompleted,
                  'originalPlannedDate': stage.plannedDate,
                });
              }
            }
          } else if (stage.plannedDate != null && stage.recurrence == null && !stage.isCompleted) {
            final date = DateTime(stage.plannedDate!.year, stage.plannedDate!.month, stage.plannedDate!.day);
            if (!date.isBefore(today)) {
              plannedItems.putIfAbsent(date, () => []).add({
                'type': 'stage',
                'item': stage,
                'project': project,
                'task': task,
                'name': stage.name,
                'isRecurring': false,
                'isCompleted': stage.isCompleted,
              });
            }
          }

          // Шаги
          for (final step in stage.steps) {
            if (step.recurrence != null && step.plannedDate != null) {
              final occurrences = RecurrenceService.generateOccurrences(
                recurrence: step.recurrence!,
                startDate: step.plannedDate!,
                untilDate: DateTime.now().add(const Duration(days: 365)),
              );

              for (final occurrence in occurrences) {
                final date = DateTime(occurrence.year, occurrence.month, occurrence.day);

                if (date.isAfter(today.subtract(const Duration(days: 1))) || isSameDay(date, today)) {
                  final isCompleted = await _isOccurrenceCompletedForStep(step, occurrence);
                  plannedItems.putIfAbsent(date, () => []).add({
                    'type': 'step',
                    'item': step,
                    'project': project,
                    'task': task,
                    'stage': stage,
                    'name': step.name,
                    'isRecurring': true,
                    'occurrenceDate': occurrence,
                    'isCompleted': isCompleted,
                    'originalPlannedDate': step.plannedDate,
                  });
                }
              }
            } else if (step.plannedDate != null && step.recurrence == null && !step.isCompleted) {
              final date = DateTime(step.plannedDate!.year, step.plannedDate!.month, step.plannedDate!.day);
              if (!date.isBefore(today)) {
                plannedItems.putIfAbsent(date, () => []).add({
                  'type': 'step',
                  'item': step,
                  'project': project,
                  'task': task,
                  'stage': stage,
                  'name': step.name,
                  'isRecurring': false,
                  'isCompleted': step.isCompleted,
                });
              }
            }
          }
        }
      }
    }

    return plannedItems;
  }

  Future<bool> _isOccurrenceCompleted(Task task, DateTime occurrenceDate) async {
    if (task.recurrence != null) {
      return await RecurrenceCompletionService.isOccurrenceCompleted(task, occurrenceDate, context);
    }
    final today = DateTime.now();
    return isSameDay(occurrenceDate, DateTime(today.year, today.month, today.day)) && task.isCompleted;
  }

  Future<bool> _isOccurrenceCompletedForStage(Stage stage, DateTime occurrenceDate) async {
    final today = DateTime.now();
    return isSameDay(occurrenceDate, DateTime(today.year, today.month, today.day)) && stage.isCompleted;
  }

  Future<bool> _isOccurrenceCompletedForStep(custom_step.Step step, DateTime occurrenceDate) async {
    final today = DateTime.now();
    return isSameDay(occurrenceDate, DateTime(today.year, today.month, today.day)) && step.isCompleted;
  }

  Future<void> _handleItemCompletion(Map<String, dynamic> completionResult) async {
    final item = completionResult['item'];
    final occurrenceDate = completionResult['occurrenceDate'] as DateTime?;
    final isRecurring = completionResult['isRecurring'] == true;

    if (isRecurring && occurrenceDate != null && item is Task) {
      if (await RecurrenceCompletionService.isOccurrenceCompleted(item, occurrenceDate, context)) {
        await RecurrenceCompletionService.unmarkOccurrenceCompleted(item, occurrenceDate, context);
      } else {
        await RecurrenceCompletionService.markOccurrenceCompleted(item, occurrenceDate, context);
      }
    }
    widget.onItemCompleted(completionResult);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<DateTime, List<Map<String, dynamic>>>>(
      future: _getPlannedItems(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final plannedItems = snapshot.data!;
        final selectedItems = _selectedDay != null
            ? plannedItems.entries
            .where((entry) => isSameDay(entry.key, _selectedDay))
            .expand((entry) => entry.value)
            .toList()
            : [];

        return Scaffold(
          body: Column(
            children: [
              TableCalendar(
                firstDay: DateTime.now().subtract(const Duration(days: 365)),
                lastDay: DateTime.now().add(const Duration(days: 365)),
                focusedDay: _focusedDay,
                calendarFormat: _calendarFormat,
                eventLoader: (day) => plannedItems[day] ?? [],
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                ),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                },
                onPageChanged: (focusedDay) {
                  _focusedDay = focusedDay;
                },
              ),
              Expanded(
                child: _selectedDay == null
                    ? const Center(child: Text('Выберите день для просмотра задач'))
                    : ListView.builder(
                  itemCount: selectedItems.length,
                  itemBuilder: (context, index) {
                    final item = selectedItems[index];
                    final isCompleted = item['isCompleted'] == true;
                    final isRecurring = item['isRecurring'] == true;
                    final occurrenceDate = item['occurrenceDate'];

                    final bool canComplete = isRecurring
                        ? isSameDay(occurrenceDate, DateTime.now()) && !isCompleted
                        : !isCompleted;

                    return ListTile(
                      leading: Icon(
                        item['type'] == 'task'
                            ? Icons.task
                            : item['type'] == 'stage'
                            ? Icons.album
                            : Icons.star,
                        color: canComplete ? Colors.blue : Colors.grey,
                      ),
                      title: Text(
                        item['name'],
                        style: TextStyle(
                          decoration: isCompleted
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                        ),
                      ),
                      subtitle: Text('Тип: ${item['type']}'),
                      trailing: IconButton(
                        icon: Icon(Icons.check,
                            color: canComplete ? Colors.green : Colors.grey),
                        onPressed: canComplete
                            ? () => _showCompletionDialog(context, item)
                            : null,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showCompletionDialog(BuildContext context, Map<String, dynamic> itemData) {
    showDialog(
      context: context,
      builder: (context) => DetailedCompletionDialog(
        item: itemData['item'],
        project: itemData['project'],
        task: itemData['task'],
        stage: itemData['stage'],
        occurrenceDate: itemData['occurrenceDate'],
      ),
    ).then((result) {
      if (result != null) {
        _handleItemCompletion(result);
        widget.onItemCompleted(result);
      }
    });
  }
}
