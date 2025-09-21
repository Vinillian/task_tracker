import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/app_user.dart';
import '../models/task.dart';
import '../models/stage.dart';
import '../models/step.dart' as custom_step;
import '../widgets/detailed_completion_dialog.dart';
import '../services/recurrence_service.dart';
import 'package:intl/intl.dart';

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

  Map<DateTime, List<dynamic>> _getPlannedItems() {
    print('🔄 Построение календаря для пользователя: ${widget.currentUser?.username}');
    final plannedItems = <DateTime, List<dynamic>>{};

    if (widget.currentUser == null) return plannedItems;

    for (final project in widget.currentUser!.projects) {
      for (final task in project.tasks) {
        // Обычные задачи с plannedDate
        if (task.plannedDate != null) {
          final date = DateTime(
            task.plannedDate!.year,
            task.plannedDate!.month,
            task.plannedDate!.day,
          );
          plannedItems.putIfAbsent(date, () => []).add({
            'type': 'task',
            'item': task,
            'project': project,
            'name': task.name,
            'isRecurring': false,
          });
        }

        // Повторяющиеся задачи
        if (task.recurrence != null && task.plannedDate != null) {
          final occurrences = RecurrenceService.generateOccurrences(
            recurrence: task.recurrence!,
            startDate: task.plannedDate!,
            untilDate: DateTime.now().add(const Duration(days: 365)),
          );

          for (final occurrence in occurrences) {
            final date = DateTime(
              occurrence.year,
              occurrence.month,
              occurrence.day,
            );
            plannedItems.putIfAbsent(date, () => []).add({
              'type': 'task',
              'item': task,
              'project': project,
              'name': task.name,
              'isRecurring': true,
            });
          }
        }

        // Этапы
        for (final stage in task.stages) {
          // Обычные этапы
          if (stage.plannedDate != null) {
            final date = DateTime(
              stage.plannedDate!.year,
              stage.plannedDate!.month,
              stage.plannedDate!.day,
            );
            plannedItems.putIfAbsent(date, () => []).add({
              'type': 'stage',
              'item': stage,
              'project': project,
              'task': task,
              'name': stage.name,
              'isRecurring': false,
            });
          }

          // Повторяющиеся этапы
          if (stage.recurrence != null && stage.plannedDate != null) {
            final occurrences = RecurrenceService.generateOccurrences(
              recurrence: stage.recurrence!,
              startDate: stage.plannedDate!,
              untilDate: DateTime.now().add(const Duration(days: 365)),
            );

            for (final occurrence in occurrences) {
              final date = DateTime(
                occurrence.year,
                occurrence.month,
                occurrence.day,
              );
              plannedItems.putIfAbsent(date, () => []).add({
                'type': 'stage',
                'item': stage,
                'project': project,
                'task': task,
                'name': stage.name,
                'isRecurring': true,
              });
            }
          }

          // Шаги
          for (final step in stage.steps) {
            // Обычные шаги
            if (step.plannedDate != null) {
              final date = DateTime(
                step.plannedDate!.year,
                step.plannedDate!.month,
                step.plannedDate!.day,
              );
              plannedItems.putIfAbsent(date, () => []).add({
                'type': 'step',
                'item': step,
                'project': project,
                'task': task,
                'stage': stage,
                'name': step.name,
                'isRecurring': false,
              });
            }

            // Повторяющиеся шаги
            if (step.recurrence != null && step.plannedDate != null) {
              final occurrences = RecurrenceService.generateOccurrences(
                recurrence: step.recurrence!,
                startDate: step.plannedDate!,
                untilDate: DateTime.now().add(const Duration(days: 365)),
              );

              for (final occurrence in occurrences) {
                final date = DateTime(
                  occurrence.year,
                  occurrence.month,
                  occurrence.day,
                );
                plannedItems.putIfAbsent(date, () => []).add({
                  'type': 'step',
                  'item': step,
                  'project': project,
                  'task': task,
                  'stage': stage,
                  'name': step.name,
                  'isRecurring': true,
                });
              }
            }
          }
        }
      }
    }

    print('📅 Найдено запланированных дней: ${plannedItems.length}');
    plannedItems.forEach((date, items) {
      print('   $date: ${items.length} задач');
    });
    return plannedItems;
  }

  @override
  Widget build(BuildContext context) {
    final plannedItems = _getPlannedItems();
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
            // ДОБАВЬ ЭТОТ БЛОК:
            onDaySelected: (selectedDay, focusedDay) {
              print('📅 Выбран день: $selectedDay');
              print('🔍 Ищем задачи для: ${DateTime(selectedDay.year, selectedDay.month, selectedDay.day)}');
              print('📊 Все доступные даты: ${plannedItems.keys.toList()}');

              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            onFormatChanged: (format) {
              setState(() {
                _calendarFormat = format;
              });
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, day, events) {
                if (events.isNotEmpty) {
                  // Приводим тип events к List<Map<String, dynamic>>
                  final typedEvents = events.cast<Map<String, dynamic>>();

                  final taskCount = typedEvents.where((e) => e['type'] == 'task').length;
                  final stageCount = typedEvents.where((e) => e['type'] == 'stage').length;
                  final stepCount = typedEvents.where((e) => e['type'] == 'step').length;

                  return Stack(
                    children: [
                      if (taskCount > 0)
                        Positioned(
                          right: 1,
                          bottom: 1,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      if (stageCount > 0)
                        Positioned(
                          right: 11,
                          bottom: 1,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      if (stepCount > 0)
                        Positioned(
                          right: 21,
                          bottom: 1,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                    ],
                  );
                }
                return null;
              },
            ),
          ),
          Expanded(
            child: _selectedDay == null
                ? const Center(child: Text('Выберите день для просмотра задач'))
                : Column(
              children: [
                Text('Задачи на ${DateFormat('dd.MM.yyyy').format(_selectedDay!)}: ${selectedItems.length}'),
                Expanded(
                  child: ListView.builder(
                    itemCount: selectedItems.length,
                    itemBuilder: (context, index) {
                      final item = selectedItems[index];
                      print('📋 Отображаем задачу: ${item['name']}');
                      return ListTile(
                        title: Text(item['name']),
                        subtitle: Text('Тип: ${item['type']}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.check),
                          onPressed: () => _showCompletionDialog(context, item),
                        ),
                        onTap: () => _showCompletionDialog(context, item),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showCompletionDialog(BuildContext context, Map<String, dynamic> itemData) {
    showDialog(
      context: context,
      builder: (context) {
        return DetailedCompletionDialog(
          item: itemData['item'],
          project: itemData['project'],
          task: itemData['task'],
          stage: itemData['stage'],
        );
      },
    ).then((result) {
      if (result != null) {
        widget.onItemCompleted(result);
      }
    });
  }
}