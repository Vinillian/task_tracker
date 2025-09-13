import 'package:flutter/material.dart';
import '../models/app_user.dart';
import '../models/progress_history.dart';
import '../utils/progress_utils.dart';

class TodayProgressList extends StatelessWidget {
  final AppUser? user;

  const TodayProgressList({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    // Фильтруем сегодняшние записи
    final todayProgress = user?.progressHistory.where((item) {
      if (item is ProgressHistory) {
        return item.date.isAfter(todayStart) && item.date.isBefore(todayEnd);
      }
      return false;
    }).toList() ?? [];

    if (todayProgress.isEmpty) {
      return Card(
        margin: const EdgeInsets.all(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Icon(Icons.emoji_events, size: 48, color: Colors.grey),
              const SizedBox(height: 8),
              const Text('Сегодня еще нет прогресса',
                  style: TextStyle(fontSize: 16)),
              Text('Добавьте шаги к задачам или подзадачам',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600])),
            ],
          ),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Сегодняшний прогресс',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...todayProgress.map((item) {
              if (item is ProgressHistory) {
                return _buildProgressItem(item);
              }
              return const SizedBox();
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressItem(ProgressHistory progress) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Icon(
            progress.itemType == 'task' ? Icons.task : Icons.arrow_right,
            color: Colors.blue,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  progress.itemName,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Text(
                  '+${progress.stepsAdded} шагов',
                  style: TextStyle(
                    color: Colors.green[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${progress.date.hour.toString().padLeft(2, '0')}:${progress.date.minute.toString().padLeft(2, '0')}',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}