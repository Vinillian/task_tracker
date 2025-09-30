import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/app_user.dart';
import '../models/task.dart';
import '../services/analytics_service.dart';

class TaskHeatmapWidget extends StatefulWidget {
  final AppUser? currentUser;

  const TaskHeatmapWidget({super.key, required this.currentUser});

  @override
  State<TaskHeatmapWidget> createState() => _TaskHeatmapWidgetState();
}

class _TaskHeatmapWidgetState extends State<TaskHeatmapWidget> {
  DateTime _currentPeriodStart = _getInitialPeriodStart();
  final int _periodLength = 14; // 2 недели

  static DateTime _getInitialPeriodStart() {
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final weekNumber = ((now.day - 1) / 7).floor();

    // Начинаем с нечетной недели месяца (0-based: 0, 2, 4...)
    final startWeek = weekNumber.isEven ? weekNumber : weekNumber - 1;
    return firstDayOfMonth.add(Duration(days: startWeek * 7));
  }

  void _previousPeriod() {
    setState(() {
      _currentPeriodStart = _currentPeriodStart.subtract(Duration(days: _periodLength));
    });
  }

  void _nextPeriod() {
    setState(() {
      _currentPeriodStart = _currentPeriodStart.add(Duration(days: _periodLength));
    });
  }

  String _getPeriodDisplayText() {
    final periodEnd = _currentPeriodStart.add(Duration(days: _periodLength - 1));
    final monthStart = DateFormat('MMM').format(_currentPeriodStart);
    final monthEnd = DateFormat('MMM').format(periodEnd);

    final weekOfMonthStart = ((_currentPeriodStart.day - 1) / 7).floor() + 1;
    final weekOfMonthEnd = ((periodEnd.day - 1) / 7).floor() + 1;

    if (_currentPeriodStart.month == periodEnd.month) {
      return '${_currentPeriodStart.day}-${periodEnd.day} $monthStart (Недели $weekOfMonthStart-$weekOfMonthEnd)';
    } else {
      return '${_currentPeriodStart.day} $monthStart - ${periodEnd.day} $monthEnd';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.currentUser == null) {
      return const Center(child: Text('Нет данных для отображения'));
    }

    final taskProgress = AnalyticsService.aggregateTaskProgress(widget.currentUser!, _currentPeriodStart);
    final trackedTasks = AnalyticsService.getTrackedTasks(widget.currentUser!);

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
            _buildHeader(),
            const SizedBox(height: 16),
            Expanded(
              child: _buildHeatmapTable(context, taskProgress, trackedTasks),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: _previousPeriod,
          tooltip: 'Предыдущий период',
        ),
        Expanded(
          child: Column(
            children: [
              const Icon(Icons.analytics, color: Colors.blue),
              const SizedBox(height: 4),
              Text(
                _getPeriodDisplayText(),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              Text(
                'Аналитика задач',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: _nextPeriod,
          tooltip: 'Следующий период',
        ),
      ],
    );
  }

  Widget _buildHeatmapTable(BuildContext context, Map<String, Map<DateTime, int>> taskProgress,
      List<Task> trackedTasks) {

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(4),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Table(
            border: TableBorder.all(color: Colors.grey.shade300, width: 0.5),
            columnWidths: _buildColumnWidths(),
            children: [
              // Заголовок с датами и днями недели
              TableRow(
                decoration: BoxDecoration(color: Colors.grey.shade50),
                children: [
                  // Пустая ячейка для левого верхнего угла
                  const TableCell(
                    verticalAlignment: TableCellVerticalAlignment.middle,
                    child: SizedBox(
                      height: 60,
                      child: Center(child: Text('Задача', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                    ),
                  ),
                  // Даты и дни недели
                  for (var i = 0; i < _periodLength; i++)
                    TableCell(
                      verticalAlignment: TableCellVerticalAlignment.middle,
                      child: Container(
                        height: 60,
                        padding: const EdgeInsets.all(4),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              DateFormat('dd').format(_currentPeriodStart.add(Duration(days: i))),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _getDayOfWeekAbbreviation(_currentPeriodStart.add(Duration(days: i))),
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              // Строки с задачами и квадратиками
              for (final task in trackedTasks)
                TableRow(
                  children: [
                    // Название задачи
                    TableCell(
                      verticalAlignment: TableCellVerticalAlignment.middle,
                      child: Container(
                        height: 40,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        child: Text(
                          task.name,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                          softWrap: true,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.left,
                        ),
                      ),
                    ),
                    // Квадратики прогресса
                    for (var i = 0; i < _periodLength; i++)
                      _buildSquareHeatmapCell(taskProgress[task.name] ?? {}, _currentPeriodStart.add(Duration(days: i))),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Map<int, TableColumnWidth> _buildColumnWidths() {
    final widths = <int, TableColumnWidth>{
      0: const FixedColumnWidth(165), // Ширина колонки с названиями задач
    };

    // Ширина колонок с квадратиками
    for (int i = 1; i <= _periodLength; i++) {
      widths[i] = const FixedColumnWidth(40);
    }

    return widths;
  }

  TableCell _buildSquareHeatmapCell(Map<DateTime, int> taskData, DateTime date) {
    final intensity = taskData[DateTime(date.year, date.month, date.day)] ?? 0;
    final color = _getGitHubStyleColor(intensity);
    final borderColor = intensity > 0 ? _darkenColor(color, 0.1) : Colors.grey.shade300;

    return TableCell(
      verticalAlignment: TableCellVerticalAlignment.middle,
      child: Container(
        height: 40,
        padding: const EdgeInsets.all(4),
        child: Center(
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: borderColor,
                width: intensity > 0 ? 1.5 : 1.0,
              ),
            ),
            child: Tooltip(
              message: '${DateFormat('EEEE, dd.MM.yyyy').format(date)}\n'
                  'Активность: $intensity ${_getActivityWord(intensity)}',
              child: const SizedBox.expand(),
            ),
          ),
        ),
      ),
    );
  }

  // Сокращения дней недели
  String _getDayOfWeekAbbreviation(DateTime date) {
    switch (date.weekday) {
      case 1: return 'Пн';
      case 2: return 'Вт';
      case 3: return 'Ср';
      case 4: return 'Чт';
      case 5: return 'Пт';
      case 6: return 'Сб';
      case 7: return 'Вс';
      default: return '';
    }
  }

  // Метод для затемнения цвета
  Color _darkenColor(Color color, double factor) {
    final hsl = HSLColor.fromColor(color);
    final darkenedHsl = hsl.withLightness((hsl.lightness - factor).clamp(0.0, 1.0));
    return darkenedHsl.toColor();
  }

  // Цветовая палитра как в GitHub Calendar
  Color _getGitHubStyleColor(int intensity) {
    switch (intensity) {
      case 0:
        return const Color(0xFFEBEDF0);
      case 1:
        return const Color(0xFF9BE9A8);
      case 2:
        return const Color(0xFF40C463);
      case 3:
        return const Color(0xFF30A14E);
      default:
        return const Color(0xFF216E39);
    }
  }

  // Правильное склонение слова "шаг"
  String _getActivityWord(int intensity) {
    if (intensity == 0) return 'шагов';
    if (intensity == 1) return 'шаг';
    if (intensity < 5) return 'шага';
    return 'шагов';
  }
}