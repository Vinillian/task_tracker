import 'package:flutter/material.dart';
import '../models/app_user.dart';
import '../models/progress_history.dart';
import '../models/task.dart';

class AnalyticsService {
  // Получить все отслеживаемые задачи из всех проектов
  static List<Task> getTrackedTasks(AppUser user) {
    final allTasks = <Task>[];
    for (final project in user.projects) {
      allTasks.addAll(project.tasks.where((task) => task.isTracked));
    }
    return allTasks;
  }

  // Агрегировать прогресс по задачам за 14-дневный период
  // ЗАМЕНИТЬ метод aggregateTaskProgress на эту улучшенную версию:
static Map<String, Map<DateTime, int>> aggregateTaskProgress(
    AppUser user, DateTime startDate) {
  final endDate = startDate.add(const Duration(days: 13));
  final result = <String, Map<DateTime, int>>{};

  // 1. Инициализация карты для отслеживаемых задач
  final trackedTasks = getTrackedTasks(user);
  for (final task in trackedTasks) {
    result[task.name] = {};
    for (var i = 0; i < 14; i++) {
      final date = startDate.add(Duration(days: i));
      result[task.name]![DateTime(date.year, date.month, date.day)] = 0;
    }
  }

  // 2. Обход истории прогресса и агрегация данных с учетом иерархии
  for (final historyItem in user.progressHistory) {
    if (historyItem is! ProgressHistory) continue;

    final itemDate = DateTime(
      historyItem.date.year,
      historyItem.date.month,
      historyItem.date.day,
    );

    if (itemDate.isBefore(startDate) || itemDate.isAfter(endDate)) continue;

    // 3. Поиск родительской задачи для любой записи истории
    Task? parentTask = _findParentTaskForHistoryItem(user, historyItem);
    
    // 4. Если родительская задача найдена и она отслеживается, добавляем прогресс
    //if (parentTask != null && trackedTasks.any((t) => t.name == parentTask!.name)) {
    if (parentTask != null && trackedTasks.any((t) => t.name == parentTask.name)) {
      final currentValue = result[parentTask.name]?[itemDate] ?? 0;
      
      // Учитываем прогресс: для чекбоксов = 1 шаг, для пошаговых = реальные шаги
      int progressValue = historyItem.stepsAdded;
      if (historyItem.itemType == 'stage' || historyItem.itemType == 'step') {
        // Для этапов и шагов считаем каждый чекбокс как 1 шаг
        progressValue = historyItem.stepsAdded > 0 ? 1 : historyItem.stepsAdded;
      }
      
      if (progressValue > 0) {
        result[parentTask.name]![itemDate] = currentValue + progressValue;
      }
    }
  }
  
  return result;
}

// Вспомогательный метод для поиска родительской задачи
static Task? _findParentTaskForHistoryItem(AppUser user, ProgressHistory historyItem) {
  for (final project in user.projects) {
    for (final task in project.tasks) {
      // Если запись относится непосредственно к задаче
      if (historyItem.itemName == task.name && historyItem.itemType == 'task') {
        return task;
      }
      
      // Если запись относится к этапу - ищем в этапах задачи
      for (final stage in task.stages) {
        if (historyItem.itemName == stage.name && historyItem.itemType == 'stage') {
          return task;
        }
        
        // Если запись относится к шагу - ищем в шагах этапа
        for (final step in stage.steps) {
          if (historyItem.itemName == step.name && historyItem.itemType == 'step') {
            return task;
          }
        }
      }
    }
  }
  return null;
}
  // Получить цвет для интенсивности
  static Color getColorForIntensity(int intensity) {
    if (intensity == 0) return const Color(0xFFEBEDF0);
    if (intensity < 3) return const Color(0xFF9BE9A8);
    if (intensity < 6) return const Color(0xFF40C463);
    if (intensity < 10) return const Color(0xFF30A14E);
    return const Color(0xFF216E39);
  }

  // Рассчитать начальную дату для текущего 14-дневного периода
  static DateTime getCurrentPeriodStart() {
    final now = DateTime.now();
    // Начало периода - понедельник текущей недели
    final start = now.subtract(Duration(days: now.weekday - 1));
    return DateTime(start.year, start.month, start.day);
  }

    // Детальная статистика прогресса по задаче за период
  static Map<String, int> getTaskDetailedProgress(
      AppUser user, String taskName, DateTime startDate, DateTime endDate) {
    
    int taskProgress = 0;
    int stagesProgress = 0;
    int stepsProgress = 0;
    int totalProgress = 0;

    // Находим задачу
    final task = _findTaskByName(user, taskName);
    if (task == null) return {'task': 0, 'stages': 0, 'steps': 0, 'total': 0};

    // Анализируем историю прогресса за период
    for (final historyItem in user.progressHistory) {
      if (historyItem is! ProgressHistory) continue;

      final itemDate = DateTime(
        historyItem.date.year,
        historyItem.date.month,
        historyItem.date.day,
      );

      if (itemDate.isBefore(startDate) || itemDate.isAfter(endDate)) continue;

      final parentTask = _findParentTaskForHistoryItem(user, historyItem);
      if (parentTask?.name != taskName) continue;

      final progressValue = historyItem.stepsAdded > 0 ? 1 : historyItem.stepsAdded;
      
      if (historyItem.itemType == 'task') {
        taskProgress += progressValue;
      } else if (historyItem.itemType == 'stage') {
        stagesProgress += progressValue;
      } else if (historyItem.itemType == 'step') {
        stepsProgress += progressValue;
      }
      
      totalProgress += progressValue;
    }

    return {
      'task': taskProgress,
      'stages': stagesProgress,
      'steps': stepsProgress,
      'total': totalProgress,
    };
  }

  // Вспомогательный метод для поиска задачи по имени
  static Task? _findTaskByName(AppUser user, String taskName) {
    for (final project in user.projects) {
      for (final task in project.tasks) {
        if (task.name == taskName) return task;
      }
    }
    return null;
  }
}