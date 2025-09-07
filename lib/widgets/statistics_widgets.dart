import 'package:flutter/material.dart';
import '../models/user.dart';
import 'github_calendar.dart'; // Импортируем календарь из отдельного файла

class StatisticsWidgets {
  static Widget buildStatisticsTab(User? currentUser) {
    return SingleChildScrollView(
      child: Column(
        children: [
          GitHubCalendar(currentUser: currentUser),
          const SizedBox(height: 20),
          _buildTotalStats(currentUser),
        ],
      ),
    );
  }

  static Widget _buildTotalStats(User? currentUser) {
    int totalSteps = 0;
    int completedSteps = 0;

    if (currentUser != null) {
      for (final history in currentUser.progressHistory) {
        totalSteps += history.stepsAdded;
      }

      // Логика для completedSteps из задач и подзадач
      for (final project in currentUser.projects) {
        for (final task in project.tasks) {
          completedSteps += task.completedSteps;
          for (final subtask in task.subtasks) {
            completedSteps += subtask.completedSteps;
          }
        }
      }
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
                _buildStatItem('Всего шагов', totalSteps.toString()),
                _buildStatItem('Выполнено', completedSteps.toString()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildStatItem(String title, String value) {
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}