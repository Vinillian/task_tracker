import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../models/app_user.dart';
import '../models/task.dart';
import '../models/stage.dart';
import '../models/step.dart' as custom_step;
import '../widgets/detailed_completion_dialog.dart';
import '../services/recurrence_service.dart';

class CalendarScreen extends StatefulWidget {
  final AppUser? currentUser;
  final Function(Map<String, dynamic>) onItemCompleted;
  final isToday = _selectedDay != null &&
      isSameDay(_selectedDay!, DateTime.now()) &&
      item['occurrenceDate'] != null &&
      isSameDay(item['occurrenceDate'], DateTime.now());

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

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    for (final project in widget.currentUser!.projects) {
      for (final task in project.tasks) {
        // Для recurring задач показываем ТОЛЬКО сгенерированные occurrences
        if (task.recurrence != null && task.plannedDate != null) {
          final occurrences = RecurrenceService.generateOccurrences(
            recurrence: task.recurrence!,
            startDate: task.plannedDate!,
            untilDate: DateTime.now().add(const Duration(days: 365)),
          );

          for (final occurrence in occurrences) {
            final date = DateTime(occurrence.year, occurrence.month, occurrence.day);
            final occurrenceDay = DateTime(occurrence.year, occurrence.month, occurrence.day);

            // Для recurring задач: показываем ВСЕ будущие даты, даже если задача выполнена
            // И текущий день, если он совпадает с occurrence
            if (occurrenceDay.isAfter(today.subtract(const Duration(days: 1))) ||
                isSameDay(occurrenceDay, today)) {

              plannedItems.putIfAbsent(date, () => []).add({
                'type': 'task',
                'item': task,
                'project': project,
                'name': task.name,
                'isRecurring': true,
                'occurrenceDate': occurrence,
                'isCompleted': task.isCompleted, // Добавляем статус выполнения
                'originalPlannedDate': task.plannedDate, // Сохраняем оригинальную дату
              });
            }
          }
        }
        // Для НЕ-recurring задач показываем оригинальную задачу только если она не выполнена
        else if (task.plannedDate != null && task.recurrence == null && !task.isCompleted) {
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
            'isCompleted': task.isCompleted,
          });
        }

        // Обработка этапов задачи
        for (final stage in task.stages) {
          // Для recurring этапов показываем ТОЛЬКО сгенерированные occurrences
          if (stage.recurrence != null && stage.plannedDate != null) {
            final occurrences = RecurrenceService.generateOccurrences(
              recurrence: stage.recurrence!,
              startDate: stage.plannedDate!,
              untilDate: DateTime.now().add(const Duration(days: 365)),
            );

            for (final occurrence in occurrences) {
              final date = DateTime(occurrence.year, occurrence.month, occurrence.day);
              final occurrenceDay = DateTime(occurrence.year, occurrence.month, occurrence.day);

              if (occurrenceDay.isAfter(today.subtract(const Duration(days: 1))) ||
                  isSameDay(occurrenceDay, today)) {

                plannedItems.putIfAbsent(date, () => []).add({
                  'type': 'stage',
                  'item': stage,
                  'project': project,
                  'task': task,
                  'name': stage.name,
                  'isRecurring': true,
                  'occurrenceDate': occurrence,
                  'isCompleted': stage.isCompleted,
                  'originalPlannedDate': stage.plannedDate,
                });
              }
            }
          }
          // Для НЕ-recurring этапов показываем оригинальный этап только если не выполнен
          else if (stage.plannedDate != null && stage.recurrence == null && !stage.isCompleted) {
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
              'isCompleted': stage.isCompleted,
            });
          }

          // Обработка шагов этапа
          for (final step in stage.steps) {
            // Для recurring шагов показываем ТОЛЬКО сгенерированные occurrences
            if (step.recurrence != null && step.plannedDate != null) {
              final occurrences = RecurrenceService.generateOccurrences(
                recurrence: step.recurrence!,
                startDate: step.plannedDate!,
                untilDate: DateTime.now().add(const Duration(days: 365)),
              );

              for (final occurrence in occurrences) {
                final date = DateTime(occurrence.year, occurrence.month, occurrence.day);
                final occurrenceDay = DateTime(occurrence.year, occurrence.month, occurrence.day);

                if (occurrenceDay.isAfter(today.subtract(const Duration(days: 1))) ||
                    isSameDay(occurrenceDay, today)) {

                  plannedItems.putIfAbsent(date, () => []).add({
                    'type': 'step',
                    'item': step,
                    'project': project,
                    'task': task,
                    'stage': stage,
                    'name': step.name,
                    'isRecurring': true,
                    'occurrenceDate': occurrence,
                    'isCompleted': step.isCompleted,
                    'originalPlannedDate': step.plannedDate,
                  });
                }
              }
            }
            // Для НЕ-recurring шагов показываем оригинальный шаг только если не выполнен
            else if (step.plannedDate != null && step.recurrence == null && !step.isCompleted) {
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
                'isCompleted': step.isCompleted,
              });
            }
          }
        }
      }
    }

    print('📅 Найдено запланированных дней: ${plannedItems.length}');
    plannedItems.forEach((date, items) {
      print('   $date: ${items.length} задач');
      for (final item in items) {
        print('     - ${item['name']} (${item['type']}) - recurring: ${item['isRecurring']} - completed: ${item['isCompleted']}');
      }
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

            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              leftChevronIcon: Icon(Icons.chevron_left),
              rightChevronIcon: Icon(Icons.chevron_right),
            ),

            onDaySelected: (selectedDay, focusedDay) {
              print('📅 Выбран день: $selectedDay');
              print('🔍 Ищем задачи для: ${DateTime(selectedDay.year, selectedDay.month, selectedDay.day)}');
              print('📊 Все доступные даты: ${plannedItems.keys.toList()}');

              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },

            onDayLongPressed: (selectedDay, focusedDay) {
              final items = plannedItems[selectedDay] ?? [];
              if (items.isNotEmpty) {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Задачи на ${DateFormat('dd.MM.yyyy').format(selectedDay)}'),
                    content: SizedBox(
                      width: double.maxFinite,
                      child: ListView(
                        shrinkWrap: true,
                        children: items.map((item) => ListTile(
                          leading: Icon(
                            item['type'] == 'task' ? Icons.task :
                            item['type'] == 'stage' ? Icons.album : Icons.star,
                            size: 20,
                            color: Colors.blue,
                          ),
                          title: Text(item['name']),
                          subtitle: Text('Тип: ${item['type']}'),
                        )).toList(),
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('Закрыть'),
                      ),
                    ],
                  ),
                );
              }
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
              todayBuilder: (context, date, events) {
                return Container(
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    border: Border.all(color: Colors.blue),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '${date.day}',
                      style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                    ),
                  ),
                );
              },

              markerBuilder: (context, day, events) {
                if (events.isNotEmpty) {
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
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    'Задачи на ${DateFormat('dd.MM.yyyy').format(_selectedDay!)}: ${selectedItems.length}',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: selectedItems.length,
                    itemBuilder: (context, index) {
                      final item = selectedItems[index];
                      final isCompleted = item['isCompleted'] == true;
                      final isRecurring = item['isRecurring'] == true;
                      final isToday = _selectedDay != null && isSameDay(_selectedDay!, DateTime.now());

                      print('📋 Отображаем задачу: ${item['name']}, completed: $isCompleted, recurring: $isRecurring');

                      // Для выполненных non-recurring задач не показываем кнопку выполнения
                      final showCompletionButton = !isCompleted || (isRecurring && isToday);

                      return ListTile(
                        leading: Icon(
                          item['type'] == 'task' ? Icons.task :
                          item['type'] == 'stage' ? Icons.album : Icons.star,
                          color: isCompleted ? Colors.grey : Colors.blue,
                        ),
                        title: Text(
                          item['name'],
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            decoration: isCompleted ? TextDecoration.lineThrough : TextDecoration.none,
                            color: isCompleted ? Colors.grey : Colors.black,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Тип: ${item['type']}'),
                            if (isRecurring)
                              Text('🔄 Повторяющаяся', style: TextStyle(color: Colors.green, fontSize: 12)),
                            if (isCompleted && !isRecurring)
                              Text('✅ Выполнено', style: TextStyle(color: Colors.grey, fontSize: 12)),
                            if (isRecurring && isToday && isCompleted)
                              Text('✅ Выполнено сегодня', style: TextStyle(color: Colors.green, fontSize: 12)),
                            if (isRecurring && isToday && !isCompleted)
                              Text('⏳ Ожидает выполнения', style: TextStyle(color: Colors.orange, fontSize: 12)),
                            if (isRecurring && !isToday)
                              Text('📅 Запланировано', style: TextStyle(color: Colors.blue, fontSize: 12)),
                          ],
                        ),
                        trailing: IconButton(
                          icon: Icon(
                            Icons.check,
                            color: isRecurring
                                ? (isToday ? Colors.green : Colors.grey)
                                : (isCompleted ? Colors.grey : Colors.green),
                          ),
                          onPressed: isRecurring
                              ? (isToday ? () => _showCompletionDialog(context, item) : null)
                              : (isCompleted ? null : () => _showCompletionDialog(context, item)),
                        ),
                        onTap: isRecurring
                            ? (isToday ? () => _showCompletionDialog(context, item) : null)
                            : (isCompleted ? null : () => _showCompletionDialog(context, item)),
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
  bool _isOccurrenceToday(DateTime selectedDay, DateTime? occurrenceDate) {
    if (occurrenceDate == null) return false;

    final today = DateTime.now();
    return isSameDay(selectedDay, today) && isSameDay(occurrenceDate, today);
  }

}