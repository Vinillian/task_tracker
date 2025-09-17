// utils/progress_utils.dart
import 'package:flutter/material.dart';
import '../models/subtask.dart'; // ← ДОБАВИТЬ импорт

class ProgressUtils {
  /// Получение процента выполнения задачи
  static double calculateProgress(int completed, int total) {
    if (total <= 0) return 0.0;
    return (completed / total).clamp(0.0, 1.0);
  }

  /// Выбор цвета задачи по прогрессу
  static Color getTaskColor(double progress) {
    if (progress <= 0.3) {
      return Colors.red;
    } else if (progress <= 0.7) {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }

  /// Анимация прогресса
  static Widget buildAnimatedProgressBar(double progress, {double height = 8}) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: progress),
      duration: const Duration(milliseconds: 500),
      builder: (context, value, child) {
        return Container(
          height: height,
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(4),
          ),
          child: FractionallySizedBox(
            widthFactor: value,
            child: Container(
              decoration: BoxDecoration(
                color: value <= 0.3
                    ? Colors.red
                    : value <= 0.7
                    ? Colors.orange
                    : Colors.green,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        );
      },
    );
  }

  // Метод для получения иконки подзадачи
  static Widget getSubtaskIcon(Subtask subtask, VoidCallback onTap) {
    if (subtask.subtaskType == 'singleStep') {
      return Checkbox(
        value: subtask.isCompleted,
        onChanged: (_) => onTap(),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      );
    } else {
      final progress = calculateProgress(subtask.completedSteps, subtask.totalSteps);
      return Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: getTaskColor(progress).withOpacity(0.2),
          shape: BoxShape.circle,
          border: Border.all(color: getTaskColor(progress)),
        ),
        child: Center(
          child: Text(
            '${(progress * 100).toInt()}%',
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.bold,
              color: getTaskColor(progress),
            ),
          ),
        ),
      );
    }
  }
}