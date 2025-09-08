import 'package:flutter/material.dart';

class ProgressUtils {
  /// Получение процента выполнения задачи
  static double calculateProgress(int completed, int total) {
    if (total <= 0) return 0.0;
    return (completed / total).clamp(0.0, 1.0);
  }

  /// Выбор цвета задачи по прогрессу
  static Color getTaskColor(double progress) {
    if (progress <= 0.3) {
      return Colors.red.shade100;
    } else if (progress <= 0.7) {
      return Colors.yellow.shade100;
    } else {
      return Colors.green.shade100;
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
                    ? Colors.yellow
                    : Colors.green,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        );
      },
    );
  }
}
