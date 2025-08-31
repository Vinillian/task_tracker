import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/user.dart';
import 'github_calendar.dart';

class StatisticsWidgets {
  static Map<String, int> getDailyProgress(User? currentUser) {
    final dailyProgress = <String, int>{};
    if (currentUser == null) return dailyProgress;

    for (final history in currentUser.progressHistory) {
      final dateKey = DateFormat('yyyy-MM-dd').format(history.date);
      dailyProgress[dateKey] = (dailyProgress[dateKey] ?? 0) + history.stepsAdded;
    }
    return dailyProgress;
  }

  static Color getDateColor(int steps) {
    if (steps >= 20) return Colors.green;
    if (steps >= 10) return Colors.orange;
    return Colors.red;
  }

  static IconData getDateIcon(int steps) {
    if (steps >= 20) return Icons.emoji_events;
    if (steps >= 10) return Icons.thumb_up;
    return Icons.thumb_down;
  }

  static Widget buildOverallStatistics(Map<String, int> dailyProgress) {
    final totalSteps = dailyProgress.values.fold(0, (sum, steps) => sum + steps);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'Общая статистика',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text(
                      '$totalSteps',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const Text('Всего шагов', style: TextStyle(fontSize: 12)),
                  ],
                ),
                Column(
                  children: [
                    Text(
                      '${dailyProgress.length}',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const Text('Дней активности', style: TextStyle(fontSize: 12)),
                  ],
                ),
                Column(
                  children: [
                    Text(
                      '${dailyProgress.isEmpty ? 0 : (totalSteps / dailyProgress.length).round()}',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const Text('Среднее в день', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static Widget buildDailyProgressList(Map<String, int> dailyProgress) {
    final sortedDates = dailyProgress.keys.toList()..sort((a, b) => b.compareTo(a));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Прогресс по дням',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        dailyProgress.isEmpty
            ? const Center(child: Text('Нет данных о прогрессе'))
            : ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: sortedDates.length,
          itemBuilder: (context, index) {
            final date = sortedDates[index];
            final steps = dailyProgress[date]!;
            final parsedDate = DateTime.parse(date);

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: getDateColor(steps),
                  child: Text(
                    steps.toString(),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                title: Text(DateFormat('dd MMMM yyyy').format(parsedDate)),
                subtitle: Text('$steps шагов выполнено'),
                trailing: Icon(getDateIcon(steps), color: getDateColor(steps)),
              ),
            );
          },
        ),
      ],
    );
  }

  static Widget buildStatisticsTab(User? currentUser) {
    if (currentUser == null) {
      return const Center(child: Text('Выберите пользователя'));
    }

    final dailyProgress = getDailyProgress(currentUser);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView(
        children: [
          GitHubCalendar(currentUser: currentUser),
          const SizedBox(height: 20),
          buildOverallStatistics(dailyProgress),
          const SizedBox(height: 20),
          buildDailyProgressList(dailyProgress),
        ],
      ),
    );
  }
}