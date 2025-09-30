import 'package:flutter/material.dart';
import '../models/app_user.dart';
import '../models/task_type.dart';
import '../utils/progress_utils.dart';
import 'github_calendar.dart';

class StatisticsWidgets {
  static Widget buildStatisticsTab(BuildContext context, AppUser? user) {
    if (user == null) {
      return const Center(child: Text('Нет выбранного пользователя'));
    }

    return RefreshIndicator(
      onRefresh: () async {
        // Здесь можно добавить принудительное обновление данных
        await Future.delayed(const Duration(seconds: 1));
        // TODO: Добавить реальное обновление данных
      },
      child: SingleChildScrollView(
        child: _buildStatisticsContent(context, user),
      ),
    );
  }

  static Widget _buildStatisticsContent(BuildContext context, AppUser user) {
    int totalTasks = 0;
    int completedTasks = 0;
    int totalSteps = 0;
    int completedSteps = 0;

    for (var project in user.projects) {
      for (var task in project.tasks) {
        totalTasks += 1;

        if (task.taskType == "stepByStep") {
          totalSteps += task.totalSteps;
          completedSteps += task.completedSteps;

          if (task.completedSteps >= task.totalSteps) {
            completedTasks += 1;
          }
        } else if (task.taskType == "singleStep") {
          totalSteps += 1;
          if (task.isCompleted) {
            completedSteps += 1;
            completedTasks += 1;
          }
        }

        // Обработка этапов и шагов
        for (var stage in task.stages) {
          if (stage.stageType == "stepByStep") {
            totalSteps += stage.totalSteps;
            completedSteps += stage.completedSteps;
          } else if (stage.stageType == "singleStep") {
            totalSteps += 1;
            if (stage.isCompleted) {
              completedSteps += 1;
            }
          }

          // Обработка шагов в этапах
          for (var step in stage.steps) {
            totalSteps += step.totalSteps;
            completedSteps += step.completedSteps;
          }
        }
      }
    }

    double taskProgress = totalTasks > 0 ? completedTasks / totalTasks : 0.0;
    double stepsProgress = totalSteps > 0 ? completedSteps / totalSteps : 0.0;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          GitHubCalendar(),
          const SizedBox(height: 24),
          Text('Общая статистика',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text('Задачи завершены', style: TextStyle(fontSize: 16)),
                  const SizedBox(height: 8),
                  ProgressUtils.buildAnimatedProgressBar(taskProgress, height: 16),
                  const SizedBox(height: 8),
                  Text('$completedTasks/$totalTasks задач (${(taskProgress * 100).toStringAsFixed(1)}%)'),
                  const SizedBox(height: 4),
                  Text('Включая одношаговые задачи',
                      style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text('Шаги выполнены', style: TextStyle(fontSize: 16)),
                  const SizedBox(height: 8),
                  ProgressUtils.buildAnimatedProgressBar(stepsProgress, height: 16),
                  const SizedBox(height: 8),
                  Text('$completedSteps/$totalSteps шагов (${(stepsProgress * 100).toStringAsFixed(1)}%)'),
                  const SizedBox(height: 4),
                  Text('Включая этапы и шаги',
                      style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text('Статистика по проектам',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          ...user.projects.map((project) {
            double projectProgress = 0.0;
            int projectTasks = project.tasks.length;
            int completedProjectTasks = 0;

            for (var task in project.tasks) {
              if (task.taskType == "stepByStep") {
                if (task.completedSteps >= task.totalSteps) completedProjectTasks++;
              } else if (task.taskType == "singleStep") {
                if (task.isCompleted) completedProjectTasks++;
              }
            }

            if (projectTasks > 0) {
              projectProgress = completedProjectTasks / projectTasks;
            }

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                title: Text(project.name),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    ProgressUtils.buildAnimatedProgressBar(projectProgress),
                    const SizedBox(height: 8),
                    Text('$completedProjectTasks/$projectTasks задач завершено'),
                    if (project.tasks.any((t) => t.taskType == "singleStep"))
                      Text('Включая одношаговые задачи',
                          style: TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}