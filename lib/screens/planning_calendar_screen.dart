import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/app_user.dart';
import '../models/task.dart';
import '../models/stage.dart';
import '../models/step.dart' as custom_step;

class PlanningCalendarScreen extends StatelessWidget {
  final AppUser? currentUser;

  const PlanningCalendarScreen({super.key, required this.currentUser});

  @override
  Widget build(BuildContext context) {
    // Собираем все запланированные элементы
    final plannedItems = <Widget>[];

    if (currentUser != null) {
      for (final project in currentUser!.projects) {
        for (final task in project.tasks) {
          if (task.plannedDate != null) {
            plannedItems.add(_buildPlannedItem(
              context,
              'Задача: ${task.name}',
              task.plannedDate!,
              'Проект: ${project.name}',
            ));
          }

          for (final stage in task.stages) {
            if (stage.plannedDate != null) {
              plannedItems.add(_buildPlannedItem(
                context,
                'Этап: ${stage.name}',
                stage.plannedDate!,
                'Задача: ${task.name}',
              ));
            }

            for (final step in stage.steps) {
              if (step.plannedDate != null) {
                plannedItems.add(_buildPlannedItem(
                  context,
                  'Шаг: ${step.name}',
                  step.plannedDate!,
                  'Этап: ${stage.name}',
                ));
              }
            }
          }
        }
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Календарь планирования'),
      ),
      body: plannedItems.isEmpty
          ? const Center(
        child: Text('Нет запланированных задач'),
      )
          : ListView(
        children: plannedItems,
      ),
    );
  }

  Widget _buildPlannedItem(BuildContext context, String title, DateTime date, String subtitle) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: const Icon(Icons.calendar_today),
        title: Text(title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(subtitle),
            Text('На: ${DateFormat('dd.MM.yyyy').format(date)}'),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.check_circle),
          onPressed: () {
            // TODO: Реализовать отметку выполнения
          },
        ),
      ),
    );
  }
}