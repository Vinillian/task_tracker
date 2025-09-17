import 'package:flutter/material.dart';
import '../models/app_user.dart';
import '../models/task_type.dart'; // ← ДОБАВИТЬ импорт
import '../utils/progress_utils.dart';
import 'github_calendar.dart';

class StatisticsWidgets {
  static Widget buildStatisticsTab(BuildContext context, AppUser? user) {
    if (user == null) {
      return const Center(child: Text('Нет выбранного пользователя'));
    }

    int totalTasks = 0;
    int completedTasks = 0;
    int totalSteps = 0;
    int completedSteps = 0;

    for (var project in user.projects) {
      for (var task in project.tasks) {
        totalTasks += 1;

        // Учитываем оба типа задач
        if (task.taskType == TaskType.stepByStep) {
          totalSteps += task.totalSteps;
          completedSteps += task.completedSteps;

          if (task.completedSteps >= task.totalSteps) {
            completedTasks += 1;
          }
        } else {
          // Для единовременных задач
          totalSteps += 1;
          if (task.isCompleted) {
            completedSteps += 1;
            completedTasks += 1;
          }
        }

        // Обработка подзадач
        for (var subtask in task.subtasks) {
          totalSteps += subtask.totalSteps;
          completedSteps += subtask.completedSteps;
        }
      }
    } // ← ДОБАВИТЬ закрывающую скобку

    double taskProgress = totalTasks > 0 ? completedTasks / totalTasks : 0.0;
    double stepsProgress = totalSteps > 0 ? completedSteps / totalSteps : 0.0;

    return SingleChildScrollView(
      child: Padding(
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
                    Text('${completedTasks}/$totalTasks задач (${(taskProgress * 100).toStringAsFixed(1)}%)'),
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
                if (task.taskType == TaskType.stepByStep) {
                  // Замените проверки taskType на строковые
                  if (task.taskType == 'stepByStep') {
                    // обработка пошаговых задач
                  } else if (task.taskType == 'singleStep') {
                    // обработка единовременных задач
                  }
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
                      Text(
                          '${completedProjectTasks}/${projectTasks} задач завершено'),
                    ],
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}