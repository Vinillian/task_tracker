import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/user.dart';

class GitHubCalendar extends StatelessWidget {
  final User? currentUser;

  // Константы ширины/шага колонки
  static const double _cellSize = 12;
  static const double _cellMargin = 1;
  static const double _columnWidth = _cellSize + _cellMargin * 2;

  const GitHubCalendar({super.key, required this.currentUser});

  Map<DateTime, int> _getDailyContributions() {
    final contributions = <DateTime, int>{};
    final now = DateTime.now();
    final startDate = DateTime(now.year - 1, now.month, now.day);

    // Заполняем все даты нулями
    var currentDate = startDate;
    while (currentDate.isBefore(now) || currentDate.isAtSameMomentAs(now)) {
      final date = DateTime(currentDate.year, currentDate.month, currentDate.day);
      contributions[date] = 0;
      currentDate = currentDate.add(const Duration(days: 1));
    }

    if (currentUser != null) {
      print('=== CALENDAR DEBUG ===');
      print('User: ${currentUser!.name}');
      print('Progress history items: ${currentUser!.progressHistory.length}');

      for (final history in currentUser!.progressHistory) {
        // Нормализуем дату истории (убираем время)
        final historyDate = DateTime(history.date.year, history.date.month, history.date.day);
        print('History item: $historyDate - ${history.stepsAdded} steps - ${history.itemName}');

        if (contributions.containsKey(historyDate)) {
          contributions[historyDate] = contributions[historyDate]! + history.stepsAdded;
          print('✓ ADDED to calendar: $historyDate - ${history.stepsAdded} steps');
        } else {
          print('✗ SKIPPED (out of range): $historyDate');
        }
      }

      print('Calendar date range: ${contributions.keys.first} to ${contributions.keys.last}');
      print('=====================');
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

  List<List<DateTime>> _groupWeeksByColumns(Map<DateTime, int> contributions) {
    final allDates = contributions.keys.toList()..sort();
    if (allDates.isEmpty) return [];

    final weeks = <List<DateTime>>[];
    DateTime currentDate = allDates.first;
    while (currentDate.weekday != DateTime.monday) {
      currentDate = currentDate.subtract(const Duration(days: 1));
    }

    final lastDate = allDates.last;
    while (currentDate.isBefore(lastDate) || currentDate.isAtSameMomentAs(lastDate)) {
      final week = <DateTime>[];
      for (int i = 0; i < 7; i++) {
        if (currentDate.isAfter(lastDate)) {
          week.add(DateTime(0));
        } else {
          week.add(currentDate);
          currentDate = currentDate.add(const Duration(days: 1));
        }
      }
      weeks.add(week);
      if (currentDate.isAfter(lastDate)) break;
    }

    return weeks;
  }

  String _getShortMonthName(int month) {
    switch (month) {
      case 1:
        return 'Янв';
      case 2:
        return 'Фев';
      case 3:
        return 'Мар';
      case 4:
        return 'Апр';
      case 5:
        return 'Май';
      case 6:
        return 'Июн';
      case 7:
        return 'Июл';
      case 8:
        return 'Авг';
      case 9:
        return 'Сен';
      case 10:
        return 'Окт';
      case 11:
        return 'Ноя';
      case 12:
        return 'Дек';
      default:
        return '';
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

  Widget _buildMonthHeaders(List<List<DateTime>> weeks) {
    if (weeks.isEmpty) return const SizedBox();

    final monthHeaders = <Widget>[];
    String? currentMonth;
    int currentMonthWeeks = 0;

    String? monthOfWeekStart(DateTime d) {
      if (d.year <= 1) return null;
      return _getShortMonthName(d.month);
    }

    for (int i = 0; i < weeks.length; i++) {
      final firstValid = weeks[i].firstWhere((d) => d.year > 1, orElse: () => DateTime(0));
      final weekMonth = firstValid.year > 1 ? monthOfWeekStart(firstValid)! : null;

      if (weekMonth == null) {
        if (currentMonth != null) currentMonthWeeks++;
        continue;
      }

      if (weekMonth != currentMonth) {
        if (currentMonth != null && currentMonthWeeks > 0) {
          monthHeaders.add(
            Container(
              width: _columnWidth * currentMonthWeeks,
              alignment: Alignment.center,
              child: Text(currentMonth, style: const TextStyle(fontSize: 10, color: Colors.black54)),
            ),
          );
        }
        currentMonth = weekMonth;
        currentMonthWeeks = 1;
      } else {
        currentMonthWeeks++;
      }
    }

    if (currentMonth != null && currentMonthWeeks > 0) {
      monthHeaders.add(
        Container(
          width: _columnWidth * currentMonthWeeks,
          alignment: Alignment.center,
          child: Text(currentMonth, style: const TextStyle(fontSize: 10, color: Colors.black54)),
        ),
      );
    }

    return Row(children: monthHeaders);
  }

  Widget _buildCalendarGridWithRows(Map<DateTime, int> contributions) {
    final weeks = _groupWeeksByColumns(contributions);
    if (weeks.isEmpty) {
      return const Center(
        child: Text('Нет данных для отображения', style: TextStyle(color: Colors.grey)),
      );
    }

    final scrollController = ScrollController(initialScrollOffset: 1000);

    return Scrollbar(
      controller: scrollController,
      thumbVisibility: true,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        controller: scrollController,
        reverse: true,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Метки дней недели СЛЕВА от календаря
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Пустое место для заголовка месяцев
                const SizedBox(height: 28, width: 30),
                // Понедельник (1 строка)
                SizedBox(
                  height: _cellSize + _cellMargin * 2,
                  child: const Text('Пн',
                      style: TextStyle(fontSize: 9, color: Colors.black54)),
                ),
                // Вторник (2 строка) - ДОБАВИЛИ
                SizedBox(
                  height: _cellSize + _cellMargin * 2,
                  child: const Text('Вт',
                      style: TextStyle(fontSize: 9, color: Colors.black54)),
                ),
                // Среда (3 строка)
                SizedBox(
                  height: _cellSize + _cellMargin * 2,
                  child: const Text('Ср',
                      style: TextStyle(fontSize: 9, color: Colors.black54)),
                ),
                // Четверг (4 строка) - ДОБАВИЛИ
                SizedBox(
                  height: _cellSize + _cellMargin * 2,
                  child: const Text('Чт',
                      style: TextStyle(fontSize: 9, color: Colors.black54)),
                ),
                // Пятница (5 строка)
                SizedBox(
                  height: _cellSize + _cellMargin * 2,
                  child: const Text('Пт',
                      style: TextStyle(fontSize: 9, color: Colors.black54)),
                ),
                // Суббота (6 строка) - ДОБАВИЛИ
                SizedBox(
                  height: _cellSize + _cellMargin * 2,
                  child: const Text('Сб',
                      style: TextStyle(fontSize: 9, color: Colors.black54)),
                ),
                // Воскресенье (7 строка) - ДОБАВИЛИ
                SizedBox(
                  height: _cellSize + _cellMargin * 2,
                  child: const Text('Вс',
                      style: TextStyle(fontSize: 9, color: Colors.black54)),
                ),
              ],
            ),
            const SizedBox(width: 8),
            // Основная часть (месяцы + сетка)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMonthHeaders(weeks),
                const SizedBox(height: 4),
                // Сетка календаря
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: weeks.map((week) {
                    return SizedBox(
                      width: _columnWidth,
                      child: Column(
                        children: List.generate(7, (day) {
                          if (day < week.length && week[day].year > 1) {
                            final date = week[day];
                            final dayContributions = contributions[date] ?? 0;
                            final color = _getContributionColor(dayContributions);

                            return Container(
                              width: _cellSize,
                              height: _cellSize,
                              margin: const EdgeInsets.all(_cellMargin),
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(2),
                                border: Border.all(color: const Color(0xFF1B1F230F), width: 0.5),
                              ),
                              child: Tooltip(
                                message: '${DateFormat('dd MMMM yyyy').format(date)}\n$dayContributions шагов',
                                child: const SizedBox.expand(),
                              ),
                            );
                          } else {
                            return Container(
                              width: _cellSize,
                              height: _cellSize,
                              margin: const EdgeInsets.all(_cellMargin),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEBEDF0),
                                borderRadius: BorderRadius.circular(2),
                                border: Border.all(color: const Color(0xFF1B1F230F), width: 0.5),
                              ),
                            );
                          }
                        }),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('Меньше', style: TextStyle(fontSize: 10, color: Colors.black54)),
        const SizedBox(width: 4),
        _buildLegendItem(const Color(0xFF9BE9A8)),
        const SizedBox(width: 2),
        _buildLegendItem(const Color(0xFF40C463)),
        const SizedBox(width: 2),
        _buildLegendItem(const Color(0xFF30A14E)),
        const SizedBox(width: 2),
        _buildLegendItem(const Color(0xFF216E39)),
        const SizedBox(width: 4),
        const Text('Больше', style: TextStyle(fontSize: 10, color: Colors.black54)),
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

    // DEBUG: посмотрим что собирается
    print('=== CALENDAR DEBUG ===');
    print('User: ${currentUser?.name}');
    print('Progress history: ${currentUser?.progressHistory.length} items');
    contributions.forEach((date, steps) {
      if (steps > 0) print('$date: $steps steps');
    });
    print('=====================');

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
            _buildCalendarGridWithRows(contributions),
            const SizedBox(height: 16),
            _buildLegend(),
          ],
        ),
      ),
    );
  }
}
