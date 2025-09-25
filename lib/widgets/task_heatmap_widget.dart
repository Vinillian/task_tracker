import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/app_user.dart';
import '../models/task.dart';
import '../services/analytics_service.dart';

class TaskHeatmapWidget extends StatelessWidget {
  final AppUser? currentUser;

  const TaskHeatmapWidget({super.key, required this.currentUser});

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return const Center(child: Text('Нет данных для отображения'));
    }

    final periodStart = AnalyticsService.getCurrentPeriodStart();
    final taskProgress = AnalyticsService.aggregateTaskProgress(currentUser!, periodStart);
    final trackedTasks = AnalyticsService.getTrackedTasks(currentUser!);

    if (trackedTasks.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.analytics, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text('Нет отслеживаемых задач'),
            SizedBox(height: 8),
            Text('Добавьте задачи в список отслеживания',
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(periodStart),
            const SizedBox(height: 16),
            Expanded(
              child: _buildHeatmapTable(context, taskProgress, trackedTasks, periodStart),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(DateTime periodStart) {
    final periodEnd = periodStart.add(const Duration(days: 13));
    return Row(
      children: [
        const Icon(Icons.analytics, color: Colors.blue),
        const SizedBox(width: 8),
        Text(
          'Аналитика задач: ${DateFormat('dd.MM').format(periodStart)} - ${DateFormat('dd.MM.yyyy').format(periodEnd)}',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildHeatmapTable(BuildContext context, Map<String, Map<DateTime, int>> taskProgress,
      List<Task> trackedTasks, DateTime periodStart) {
    
    return Container(
      // Ограничиваем максимальную высоту таблицы
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
      child: SingleChildScrollView(
        // Вертикальная прокрутка для всего списка задач
        scrollDirection: Axis.vertical,
        child: SingleChildScrollView(
          // Горизонтальная прокрутка для тепловой карты
          scrollDirection: Axis.horizontal,
          child: Table(
            border: TableBorder.all(color: Colors.grey.shade300, width: 0.5),
            // Устанавливаем фиксированную ширину для столбцов
            columnWidths: const <int, TableColumnWidth>{
              0: FixedColumnWidth(200), // Широкий столбец для названий задач
            },
            defaultColumnWidth: const FixedColumnWidth(40), // Фиксированная ширина для ячеек с датами
            children: [
              // Заголовок с датами
              TableRow(
                decoration: BoxDecoration(color: Colors.grey.shade100),
                children: [
                  const TableCell(
                    child: Padding(
                      padding: EdgeInsets.all(8),
                      child: Text('Задача',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  for (var i = 0; i < 14; i++)
                    TableCell(
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        child: Text(
                          DateFormat('dd').format(periodStart.add(Duration(days: i))),
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              ),
              // Данные по задачам
              for (final task in trackedTasks)
                TableRow(
                  children: [
                    TableCell(
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        child: Text(
                          task.name,
                          style: const TextStyle(fontSize: 12),
                          softWrap: true,
                          maxLines: 2,
                        ),
                      ),
                    ),
                    for (var i = 0; i < 14; i++)
                      _buildHeatmapCell(taskProgress[task.name] ?? {}, periodStart.add(Duration(days: i))),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  TableCell _buildHeatmapCell(Map<DateTime, int> taskData, DateTime date) {
    final intensity = taskData[DateTime(date.year, date.month, date.day)] ?? 0;
    final color = AnalyticsService.getColorForIntensity(intensity);

    return TableCell(
      child: Container(
        width: 30,
        height: 30,
        color: color,
        child: Tooltip(
          message: '${DateFormat('dd.MM.yyyy').format(date)}\nШагов: $intensity',
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}