import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/user.dart';

class GitHubCalendar extends StatelessWidget {
  final User? currentUser;

  const GitHubCalendar({super.key, required this.currentUser});

  Map<DateTime, int> _getDailyContributions() {
    final contributions = <DateTime, int>{};
    final now = DateTime.now();
    final startDate = DateTime(now.year - 1, now.month, now.day); // Год назад

    // Создаем все даты за последний год с нулевыми значениями
    var currentDate = startDate;
    while (currentDate.isBefore(now) || currentDate.isAtSameMomentAs(now)) {
      final date = DateTime(currentDate.year, currentDate.month, currentDate.day);
      contributions[date] = 0;
      currentDate = currentDate.add(const Duration(days: 1));
    }

    // Заполняем реальными данными
    if (currentUser != null) {
      for (final history in currentUser!.progressHistory) {
        final date = DateTime(history.date.year, history.date.month, history.date.day);
        if (contributions.containsKey(date)) {
          contributions[date] = contributions[date]! + history.stepsAdded;
        }
      }
    }

    return contributions;
  }

  Color _getContributionColor(int steps) {
    if (steps == 0) return const Color(0xFFEBEDF0);
    if (steps < 5) return const Color(0xFF9BE9A8);
    if (steps < 10) return const Color(0xFF40C463);
    if (steps < 20) return const Color(0xFF30A14E);
    return const Color(0xFF216E39);
  }

  List<List<DateTime>> _groupByWeeks(Map<DateTime, int> contributions) {
    final allDates = contributions.keys.toList()..sort();
    final weeks = <List<DateTime>>[];

    // Находим первый понедельник
    DateTime firstDate = allDates.first;
    while (firstDate.weekday != DateTime.monday) {
      firstDate = firstDate.subtract(const Duration(days: 1));
    }

    var currentDate = firstDate;
    final lastDate = allDates.last;

    while (currentDate.isBefore(lastDate) || currentDate.isAtSameMomentAs(lastDate)) {
      final week = <DateTime>[];
      for (int i = 0; i < 7; i++) {
        week.add(currentDate);
        currentDate = currentDate.add(const Duration(days: 1));
      }
      weeks.add(week);
    }

    return weeks;
  }

  Widget _buildCalendarGrid(Map<DateTime, int> contributions) {
    final weeks = _groupByWeeks(contributions);

    return Column(
      children: [
        // Заголовки месяцев
        _buildMonthHeaders(weeks),
        const SizedBox(height: 8),
        // Сетка календаря
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Дни недели
            Column(
              children: [
                const SizedBox(height: 4),
                _buildWeekDayLabel('Пн'),
                const SizedBox(height: 12),
                _buildWeekDayLabel('Ср'),
                const SizedBox(height: 12),
                _buildWeekDayLabel('Пт'),
                const SizedBox(height: 4),
              ],
            ),
            const SizedBox(width: 8),
            // Ячейки календаря
            Expanded(
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: weeks.length,
                  mainAxisSpacing: 2,
                  crossAxisSpacing: 2,
                  childAspectRatio: 1,
                ),
                itemCount: 7 * weeks.length,
                itemBuilder: (context, index) {
                  final weekIndex = index ~/ 7;
                  final dayIndex = index % 7;

                  if (weekIndex < weeks.length && dayIndex < weeks[weekIndex].length) {
                    final date = weeks[weekIndex][dayIndex];
                    final steps = contributions[date] ?? 0;
                    return _buildCalendarCell(date, steps);
                  }
                  return _buildEmptyCell();
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMonthHeaders(List<List<DateTime>> weeks) {
    final monthHeaders = <Widget>[];
    String? currentMonth;

    for (final week in weeks) {
      if (week.isNotEmpty) {
        final firstDate = week.firstWhere(
              (date) => date.day <= 7, // Берем дату в первой неделе месяца
          orElse: () => week.first,
        );

        final month = DateFormat('MMM', 'ru').format(firstDate);

        if (month != currentMonth) {
          currentMonth = month;
          monthHeaders.add(
            SizedBox(
              width: 14 * 7, // Ширина недели
              child: Text(
                month,
                style: const TextStyle(fontSize: 10, color: Colors.black54),
                textAlign: TextAlign.center,
              ),
            ),
          );
        } else {
          monthHeaders.add(const SizedBox(width: 14 * 7));
        }
      }
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          const SizedBox(width: 30), // Отступ для дней недели
          ...monthHeaders,
        ],
      ),
    );
  }

  Widget _buildCalendarCell(DateTime date, int steps) {
    return Container(
      width: 12,
      height: 12,
      margin: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        color: _getContributionColor(steps),
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: const Color(0xFF1B1F230F), width: 0.5),
      ),
      child: Tooltip(
        message: '${DateFormat('dd MMMM yyyy', 'ru').format(date)}\n$steps шагов',
        child: const SizedBox.expand(),
      ),
    );
  }

  Widget _buildEmptyCell() {
    return Container(
      width: 12,
      height: 12,
      margin: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        color: const Color(0xFFEBEDF0),
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: const Color(0xFF1B1F230F), width: 0.5),
      ),
    );
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
        _buildLegendItem(const Color(0xFF9BE9A8)),
        const SizedBox(width: 2),
        _buildLegendItem(const Color(0xFF40C463)),
        const SizedBox(width: 2),
        _buildLegendItem(const Color(0xFF30A14E)),
        const SizedBox(width: 2),
        _buildLegendItem(const Color(0xFF216E39)),
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
        border: Border.all(color: const Color(0xFF1B1F230F), width: 0.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final contributions = _getDailyContributions();

    return Card(
      margin: const EdgeInsets.all(16),
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
            _buildCalendarGrid(contributions),
            const SizedBox(height: 16),
            _buildLegend(),
          ],
        ),
      ),
    );
  }
}