import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../models/app_user.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import '../models/progress_history.dart';


class GitHubCalendar extends StatelessWidget {
  const GitHubCalendar({super.key});

  static const double _cellSize = 12;
  static const double _cellMargin = 2;
  static const double _columnWidth = _cellSize + _cellMargin * 2;

  Stream<AppUser?> _userStream(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);

    final currentUid = authService.currentUser?.uid;
    if (currentUid == null) {
      return Stream.value(null);
    }

    return firestoreService.userStream(currentUid);
  }

  Map<DateTime, int> _buildContributions(List<dynamic> progressHistory) {
    final now = DateTime.now();
    final start = DateTime(now.year - 1, now.month, now.day);
    final map = <DateTime, int>{};

    // Initialize all dates with 0 contributions
    for (var d = start; !d.isAfter(now); d = d.add(const Duration(days: 1))) {
      map[DateTime(d.year, d.month, d.day)] = 0;
    }

    if (progressHistory.isEmpty) return map;

    for (final historyItem in progressHistory) {
      try {
        DateTime date;
        int steps = 0;

        if (historyItem is ProgressHistory) {
          // Handle ProgressHistory objects
          date = historyItem.date;
          steps = historyItem.stepsAdded;
        } else if (historyItem is Map<String, dynamic>) {
          // Handle Map data (from Firestore)
          final dynamic dateData = historyItem['date'];
          final dynamic stepsData = historyItem['stepsAdded'];

          if (stepsData is int) {
            steps = stepsData;
          } else if (stepsData is String) {
            steps = int.tryParse(stepsData) ?? 0;
          }

          if (dateData is Timestamp) {
            date = dateData.toDate();
          } else if (dateData is String) {
            date = DateTime.parse(dateData);
          } else {
            continue;
          }
        } else {
          continue;
        }

        // Фильтруем только положительные вклады и не отмены
        if (steps > 0) {
          final normalizedDate = DateTime(date.year, date.month, date.day);
          if (map.containsKey(normalizedDate)) {
            //map[normalizedDate] = map[normalizedDate]! + 1;
            if (map.containsKey(normalizedDate)) {
              final currentValue = map[normalizedDate] ?? 0;
              map[normalizedDate] = currentValue + 1;
            }
          }
        }
      } catch (e) {
        print('❌ Ошибка обработки записи истории: $e');
        continue;
      }
    }

    return map;
  }


  Color _colorForCount(int count) {
    if (count == 0) return const Color(0xFFEBEDF0);
    if (count < 5) return const Color(0xFF9BE9A8);
    if (count < 10) return const Color(0xFF40C463);
    if (count < 20) return const Color(0xFF30A14E);
    return const Color(0xFF216E39);
  }

  List<List<DateTime>> _weeks(Map<DateTime, int> contributions) {
    final dates = contributions.keys.toList()..sort();
    if (dates.isEmpty) return [];

    var cur = dates.first;
    while (cur.weekday != DateTime.monday) {
      cur = cur.subtract(const Duration(days: 1));
    }

    final last = dates.last;
    final weeks = <List<DateTime>>[];

    while (!cur.isAfter(last)) {
      final week = <DateTime>[];
      for (int i = 0; i < 7; i++) {
        week.add(cur);
        cur = cur.add(const Duration(days: 1));
      }
      weeks.add(week);
    }
    return weeks;
  }

  Widget _monthHeaders(List<List<DateTime>> weeks) {
    if (weeks.isEmpty) return const SizedBox.shrink();
    final headers = <Widget>[];
    String? currentMonth;
    double width = 0;

    for (final week in weeks) {
      final first = week.first;
      final label = (first.year <= 1) ? null : DateFormat.MMM().format(first);
      if (label == null) {
        width += _columnWidth;
        continue;
      }
      if (label != currentMonth) {
        if (currentMonth != null) {
          headers.add(SizedBox(
              width: width,
              child: Center(child: Text(currentMonth, style: const TextStyle(fontSize: 10, color: Colors.black54)))
          ));
        }
        currentMonth = label;
        width = _columnWidth;
      } else {
        width += _columnWidth;
      }
    }
    if (currentMonth != null) {
      headers.add(SizedBox(
          width: width,
          child: Center(child: Text(currentMonth, style: const TextStyle(fontSize: 10, color: Colors.black54)))
      ));
    }
    return Row(children: headers);
  }

  double _calculateScrollPosition(List<List<DateTime>> weeks) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    for (int i = 0; i < weeks.length; i++) {
      for (int j = 0; j < weeks[i].length; j++) {
        final date = weeks[i][j];
        if (date.year == today.year && date.month == today.month && date.day == today.day) {
          return (i * _columnWidth) - 100;
        }
      }
    }
    return weeks.length * _columnWidth - 300;
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  Widget _buildTodayStats(Map<DateTime, int> contributions) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todayContributions = contributions[today] ?? 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Сегодня: ', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey[700])),
          Text('$todayContributions ${_getContributionText(todayContributions)}',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _colorForCount(todayContributions))),
          if (todayContributions > 0) ...[
            const SizedBox(width: 8),
            Icon(Icons.check_circle, color: _colorForCount(todayContributions), size: 16),
          ],
        ],
      ),
    );
  }


  Widget _legendBox(Color color) => Container(
      width: 12, height: 12, margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2), border: Border.all(color: const Color(0x11000000)))
  );

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AppUser?>(
      stream: _userStream(context),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildEmptyState();
        }

        final user = snapshot.data;
        if (user == null || user.username.isEmpty) {
          return _buildEmptyState();
        }

        // Отладочная информация о прогрессе
        print('👤 User: ${user.username}');
        print('📋 Total history items: ${user.progressHistory.length}');

        final contributions = _buildContributions(user.progressHistory);
        final weeks = _weeks(contributions);

        if (weeks.isEmpty || user.progressHistory.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.emoji_events, size: 48, color: Colors.grey),
                SizedBox(height: 16),
                Text('Нет данных для отображения',
                    style: TextStyle(fontSize: 16)),
                SizedBox(height: 8),
                Text('Начните добавлять прогресс к задачам',
                    style: TextStyle(fontSize: 14, color: Colors.grey)),
              ],
            ),
          );
        }

        final scrollPosition = _calculateScrollPosition(weeks);
        final scrollController = ScrollController(initialScrollOffset: scrollPosition);

        return Card(
          margin: const EdgeInsets.all(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                const SizedBox(height: 4),
                const Text('Календарь активности', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Scrollbar(
                  controller: scrollController,
                  thumbVisibility: true,
                  thickness: 6,
                  radius: const Radius.circular(3),
                  child: SingleChildScrollView(
                    controller: scrollController,
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          children: [
                            const SizedBox(height: 18),
                            for (final day in ['Пн','','Ср','','Пт','','Вс'])
                              SizedBox(
                                  height: _cellSize + _cellMargin * 2,
                                  width: 24,
                                  child: Center(child: Text(day, style: const TextStyle(fontSize: 9, color: Colors.black54)))
                              ),
                          ],
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _monthHeaders(weeks),
                            const SizedBox(height: 4),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: weeks.map((week) {
                                return SizedBox(
                                  width: _columnWidth,
                                  child: Column(
                                    children: List.generate(7, (i) {
                                      if (i >= week.length) return const SizedBox();
                                      final date = week[i];
                                      final count = contributions[DateTime(date.year, date.month, date.day)] ?? 0;
                                      final color = _colorForCount(count);
                                      final isToday = _isToday(date);

                                      return Container(
                                        width: _cellSize, height: _cellSize, margin: const EdgeInsets.all(_cellMargin),
                                        decoration: BoxDecoration(
                                          color: color, borderRadius: BorderRadius.circular(2),
                                          border: Border.all(color: isToday ? Colors.blue.withOpacity(0.8) : const Color(0x11000000), width: isToday ? 1.5 : 1),
                                        ),
                                        child: Tooltip(
                                          message: '${DateFormat('dd MMM yyyy').format(date)}\n'
                                              '${count} ${_getContributionText(count)}'
                                              '${isToday ? ' (сегодня)' : ''}',
                                          child: const SizedBox.expand(),
                                        ),
                                      );
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
                ),

                const SizedBox(height: 12),
                _buildTodayStats(contributions),
                const SizedBox(height: 8),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Меньше', style: TextStyle(fontSize: 12, color: Colors.black54)),
                    const SizedBox(width: 8),
                    _legendBox(const Color(0xFF9BE9A8)),
                    const SizedBox(width: 4),
                    _legendBox(const Color(0xFF40C463)),
                    const SizedBox(width: 4),
                    _legendBox(const Color(0xFF30A14E)),
                    const SizedBox(width: 4),
                    _legendBox(const Color(0xFF216E39)),
                    const SizedBox(width: 8),
                    const Text('Больше', style: TextStyle(fontSize: 12, color: Colors.black54)),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ДОБАВЬТЕ этот метод в класс GitHubCalendar ПОСЛЕ build метода:
  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_today, size: 48, color: Colors.grey),
          SizedBox(height: 16),
          Text('Данные пользователя загружаются...',
              style: TextStyle(fontSize: 16)),
          SizedBox(height: 8),
          Text('Создайте задачи для отображения активности',
              style: TextStyle(fontSize: 14, color: Colors.grey)),
        ],
      ),
    );
  }

  String _getContributionText(int count) {
    if (count == 0) return 'вкладов';
    if (count == 1) return 'вклад';
    if (count < 5) return 'вклада';
    return 'вкладов';
  }

}