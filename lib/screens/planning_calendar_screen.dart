import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import '../models/app_user.dart';
import '../models/task.dart';
import '../models/stage.dart';
import '../models/step.dart' as custom_step;
import '../models/project.dart';
import '../services/recurrence_service.dart';
import '../services/recurrence_completion_service.dart';
import '../widgets/detailed_completion_dialog.dart';

class PlanningCalendarScreen extends StatelessWidget {
  final AppUser? currentUser;
  final Function(Map<String, dynamic>) onItemCompleted;

  const PlanningCalendarScreen({
    super.key,
    required this.currentUser,
    required this.onItemCompleted,
  });

  @override
  Widget build(BuildContext context) {
    final plannedItems = <_PlannedItem>[];

    void _addTaskOccurrences(Project project, Task task, DateTime startDate) {
      final occurrences = task.recurrence != null
          ? RecurrenceService.generateOccurrences(
        recurrence: task.recurrence!,
        startDate: startDate,
        untilDate: DateTime.now().add(const Duration(days: 30)),
      )
          : [startDate];

      for (final date in occurrences) {
        plannedItems.add(_PlannedItem(
          type: 'Задача',
          name: task.name,
          date: date,
          projectName: project.name,
          isRecurring: task.recurrence != null,
          item: task,
          onTap: () => _showCompletionDialog(
            context,
            task,
            project,
            null,
            null,
            task.recurrence != null ? date : null,
          ),
        ));
      }
    }

    void _addStageOccurrences(Project project, Task task, Stage stage, DateTime startDate) {
      final occurrences = stage.recurrence != null
          ? RecurrenceService.generateOccurrences(
        recurrence: stage.recurrence!,
        startDate: startDate,
        untilDate: DateTime.now().add(const Duration(days: 30)),
      )
          : [startDate];

      for (final date in occurrences) {
        plannedItems.add(_PlannedItem(
          type: 'Этап',
          name: stage.name,
          date: date,
          projectName: project.name,
          taskName: task.name,
          isRecurring: stage.recurrence != null,
          item: stage,
          onTap: () => _showCompletionDialog(
            context,
            stage,
            project,
            task,
            null,
            stage.recurrence != null ? date : null,
          ),
        ));
      }
    }

    void _addStepOccurrences(Project project, Task task, Stage stage, custom_step.Step step, DateTime startDate) {
      final occurrences = step.recurrence != null
          ? RecurrenceService.generateOccurrences(
        recurrence: step.recurrence!,
        startDate: startDate,
        untilDate: DateTime.now().add(const Duration(days: 30)),
      )
          : [startDate];

      for (final date in occurrences) {
        plannedItems.add(_PlannedItem(
          type: 'Шаг',
          name: step.name,
          date: date,
          projectName: project.name,
          taskName: task.name,
          stageName: stage.name,
          isRecurring: step.recurrence != null,
          item: step,
          onTap: () => _showCompletionDialog(
            context,
            step,
            project,
            task,
            stage,
            step.recurrence != null ? date : null,
          ),
        ));
      }
    }

    void addTaskItems(Project project, Task task) {
      if (task.plannedDate != null) {
        _addTaskOccurrences(project, task, task.plannedDate!);
      }

      for (final stage in task.stages) {
        if (stage.plannedDate != null) {
          _addStageOccurrences(project, task, stage, stage.plannedDate!);
        }

        for (final step in stage.steps) {
          if (step.plannedDate != null) {
            _addStepOccurrences(project, task, stage, step, step.plannedDate!);
          }
        }
      }
    }

    if (currentUser != null) {
      for (final project in currentUser!.projects) {
        for (final task in project.tasks) {
          addTaskItems(project, task);
        }
      }
    }

    plannedItems.sort((a, b) => a.date.compareTo(b.date));

    final groupedItems = <DateTime, List<_PlannedItem>>{};
    for (final item in plannedItems) {
      final date = DateTime(item.date.year, item.date.month, item.date.day);
      groupedItems.putIfAbsent(date, () => []).add(item);
    }

    final sortedDates = groupedItems.keys.toList()..sort();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Календарь планирования'),
      ),
      body: groupedItems.isEmpty
          ? const Center(
        child: Text(
          'Нет запланированных задач.\nДобавьте дату выполнения в задачу, этап или шаг.',
          textAlign: TextAlign.center,
        ),
      )
          : ListView.builder(
        itemCount: sortedDates.length,
        itemBuilder: (context, index) {
          final date = sortedDates[index];
          final items = groupedItems[date]!;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  DateFormat('dd MMMM yyyy, EEEE').format(date),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ...items.map((item) => _buildPlannedItem(context, item)).toList(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPlannedItem(BuildContext context, _PlannedItem item) {
    return FutureBuilder<bool>(
      future: item.isRecurring && item.item is Task
          ? RecurrenceCompletionService.isOccurrenceCompleted(item.item as Task, item.date, context)
          : Future.value(
        item.item is Task
            ? (item.item as Task).isCompleted
            : item.item is Stage
            ? (item.item as Stage).isCompleted
            : (item.item as custom_step.Step).isCompleted,
      ),
      builder: (context, snapshot) {
        final isCompleted = snapshot.data ?? false;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            leading: _getIconForType(item.type),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    item.name,
                    style: TextStyle(
                      decoration: isCompleted ? TextDecoration.lineThrough : TextDecoration.none,
                    ),
                  ),
                ),
                if (item.isRecurring)
                  const Icon(Icons.repeat, size: 16, color: Colors.blue),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${item.type} • ${item.projectName}'),
                if (item.taskName != null) Text('Задача: ${item.taskName}'),
                if (item.stageName != null) Text('Этап: ${item.stageName}'),
                Text('На: ${DateFormat('HH:mm').format(item.date)}'),
                if (item.isRecurring)
                  Text(
                    isCompleted ? '✅ Выполнено' : '⏳ Ожидает',
                    style: TextStyle(color: isCompleted ? Colors.green : Colors.orange),
                  ),
              ],
            ),
            trailing: IconButton(
              icon: Icon(
                isCompleted ? Icons.check_circle : Icons.check_circle_outline,
                color: isCompleted ? Colors.green : Colors.grey,
              ),
              onPressed: () {
                item.onTap();
                try {
                  Provider.of<CalendarRefresh>(context, listen: false).refresh();
                } catch (_) {}
              },
              tooltip: isCompleted ? 'Снять отметку' : 'Отметить выполнение',
            ),
            onTap: () {
              item.onTap();
              try {
                Provider.of<CalendarRefresh>(context, listen: false).refresh();
              } catch (_) {}
            },
          ),
        );
      },
    );
  }

  Icon _getIconForType(String type) {
    switch (type) {
      case 'Задача':
        return const Icon(Icons.task, color: Colors.blue);
      case 'Этап':
        return const Icon(Icons.album, color: Colors.green);
      case 'Шаг':
        return const Icon(Icons.star, color: Colors.orange);
      default:
        return const Icon(Icons.calendar_today);
    }
  }

  void _showCompletionDialog(
      BuildContext context,
      dynamic item, [
        Project? project,
        Task? task,
        Stage? stage,
        DateTime? occurrenceDate,
      ]) {
    showDialog(
      context: context,
      builder: (context) => DetailedCompletionDialog(
        item: item,
        project: project,
        task: task,
        stage: stage,
        occurrenceDate: occurrenceDate,
      ),
    ).then((result) {
      if (result != null) {
        onItemCompleted(result);
      }
    });
  }
}

class _PlannedItem {
  final String type;
  final String name;
  final DateTime date;
  final String projectName;
  final String? taskName;
  final String? stageName;
  final bool isRecurring;
  final dynamic item;
  final VoidCallback onTap;

  _PlannedItem({
    required this.type,
    required this.name,
    required this.date,
    required this.projectName,
    this.taskName,
    this.stageName,
    this.isRecurring = false,
    required this.item,
    required this.onTap,
  });
}

