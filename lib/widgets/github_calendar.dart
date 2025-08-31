import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/user.dart';

class GitHubCalendar extends StatelessWidget {
  final User? currentUser;

  const GitHubCalendar({super.key, required this.currentUser});

  Map<DateTime, int> _getDailyContributions() {
    final contributions = <DateTime, int>{};

    if (currentUser == null) return contributions;

    for (final history in currentUser!.progressHistory) {
      final date = DateTime(history.date.year, history.date.month, history.date.day);
      contributions[date] = (contributions[date] ?? 0) + history.stepsAdded;
    }

    return contributions;
  }

  Color _getContributionColor(int steps) {
    if (steps == 0) return Colors.grey[100]!;
    if (steps < 5) return Colors.green[100]!;
    if (steps < 10) return Colors.green[300]!;
    if (steps < 20) return Colors.green[500]!;
    return Colors.green[700]!;
  }

  Widget _buildCalendarGrid(DateTime startDate, DateTime endDate, Map<DateTime, int> contributions) {
    final weeks = <List<Widget>>[];
    var currentDate = startDate;

    // Создаем список всех дат в периоде
    final allDates = <DateTime>[];
    while (currentDate.isBefore(endDate) || currentDate.isAtSameMomentAs(endDate)) {
      allDates.add(currentDate);
      currentDate = currentDate.add(const Duration(days: 1));
    }

    // Разбиваем на недели (по 7 дней)
    for (int i = 0; i < allDates.length; i += 7) {
      final week = <Widget>[];
      final weekDates = allDates.sublist(i, i + 7 > allDates.length ? allDates.length : i + 7);

      for (final date in weekDates) {
        final dayContributions = contributions[date] ?? 0;
        final color = _getContributionColor(dayContributions);

        week.add(
          Container(
            width: 12,
            height: 12,
            margin: const EdgeInsets.all(1),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
              border: Border.all(
                color: Colors.grey[300]!,
                width: 0.5,
              ),
            ),
            child: Tooltip(
              message: '${DateFormat('dd MMMM yyyy').format(date)}\n$dayContributions шагов',
              child: const SizedBox.expand(),
            ),
          ),
        );
      }

      // Добавляем пустые ячейки, если неделя неполная
      while (week.length < 7) {
        week.add(
          Container(
            width: 12,
            height: 12,
            margin: const EdgeInsets.all(1),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(2),
              border: Border.all(
                color: Colors.grey[300]!,
                width: 0.5,
              ),
            ),
          ),
        );
      }

      weeks.add(week);
    }

    return Column(
      children: [
        // Месяцы - точно над соответствующими столбцами
        _buildMonthLabels(weeks, startDate),
        const SizedBox(height: 4),
        // Основная сетка с днями недели
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Дни недели - точно на уровне строк
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(height: 6),
                _buildWeekDayLabel('Пн'),
                const SizedBox(height: 24),
                _buildWeekDayLabel('Ср'),
                const SizedBox(height: 24),
                _buildWeekDayLabel('Пт'),
                const SizedBox(height: 6),
              ],
            ),
            const SizedBox(width: 8),
            // Календарь
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: weeks.asMap().entries.map((entry) {
                    final weekIndex = entry.key;
                    final week = entry.value;

                    return Column(
                      children: week,
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMonthLabels(List<List<Widget>> weeks, DateTime startDate) {
    final monthLabels = <Widget>[];
    var currentMonth = startDate.month;
    var weekOffset = 0;

    // Первый месяц
    monthLabels.add(
      SizedBox(
        width: 30,
        child: Text(
          _getShortMonthName(startDate.month),
          style: const TextStyle(fontSize: 10, color: Colors.black54),
        ),
      ),
    );

    // Проходим по всем неделям и определяем смену месяцев
    for (int weekIndex = 0; weekIndex < weeks.length; weekIndex++) {
      final weekStartDate = startDate.add(Duration(days: weekIndex * 7));
      final weekMonth = weekStartDate.month;

      if (weekMonth != currentMonth) {
        currentMonth = weekMonth;
        monthLabels.add(
          SizedBox(
            width: 12 * 7, // Ширина одной недели
            child: Text(
              _getShortMonthName(currentMonth),
              style: const TextStyle(fontSize: 10, color: Colors.black54),
            ),
          ),
        );
      } else {
        monthLabels.add(SizedBox(width: 12 * 7)); // Пустое место для продолжения месяца
      }
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          const SizedBox(width: 30), // Отступ для дней недели
          ...monthLabels,
        ],
      ),
    );
  }

  String _getShortMonthName(int month) {
    switch (month) {
      case 1: return 'Янв';
      case 2: return 'Фев';
      case 3: return 'Мар';
      case 4: return 'Апр';
      case 5: return 'Май';
      case 6: return 'Июн';
      case 7: return 'Июл';
      case 8: return 'Авг';
      case 9: return 'Сен';
      case 10: return 'Окт';
      case 11: return 'Ноя';
      case 12: return 'Дек';
      default: return '';
    }
  }

  Widget _buildWeekDayLabel(String day) {
    return SizedBox(
      width: 20,
      child: Text(
        day,
        style: const TextStyle(fontSize: 9, color: Colors.black54),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Меньше',
          style: TextStyle(fontSize: 10, color: Colors.black54),
        ),
        const SizedBox(width: 4),
        _buildLegendItem(Colors.green[100]!),
        const SizedBox(width: 4),
        _buildLegendItem(Colors.green[300]!),
        const SizedBox(width: 4),
        _buildLegendItem(Colors.green[500]!),
        const SizedBox(width: 4),
        _buildLegendItem(Colors.green[700]!),
        const SizedBox(width: 4),
        const Text(
          'Больше',
          style: TextStyle(fontSize: 10, color: Colors.black54),
        ),
      ],
    );
  }

  Widget _buildLegendItem(Color color) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: Colors.grey[300]!, width: 0.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final contributions = _getDailyContributions();
    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month - 3, now.day);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Календарь активности',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildCalendarGrid(startDate, now, contributions),
            const SizedBox(height: 16),
            _buildLegend(),
          ],
        ),
      ),
    );
  }
}