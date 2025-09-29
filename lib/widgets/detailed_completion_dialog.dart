// lib/widgets/detailed_completion_dialog.dart

import 'package:flutter/material.dart';
import 'package:task_tracker/models/task.dart';

class DetailedCompletionDialog extends StatelessWidget {
  final Task task;
  final Function(bool) onComplete;

  const DetailedCompletionDialog({
    super.key,
    required this.task,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Завершить задачу'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            task.title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 16),
          _buildCompletionOptions(),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Отмена'),
        ),
        ElevatedButton(
          onPressed: () {
            onComplete(true);
            Navigator.of(context).pop();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
          ),
          child: const Text('Завершить', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  Widget _buildCompletionOptions() {
    if (task.subTasks.isEmpty) {
      return const Text('Вы уверены, что хотите завершить эту задачу?');
    }

    final completedSubtasks = task.subTasks.where((t) => t.isCompleted).length;
    final totalSubtasks = task.subTasks.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Прогресс подзадач: $completedSubtasks/$totalSubtasks'),
        const SizedBox(height: 8),
        if (completedSubtasks < totalSubtasks)
          const Text(
            'Не все подзадачи завершены. Завершить основную задачу?',
            style: TextStyle(color: Colors.orange),
          ),
      ],
    );
  }

  static void show({
    required BuildContext context,
    required Task task,
    required Function(bool) onComplete,
  }) {
    showDialog(
      context: context,
      builder: (context) => DetailedCompletionDialog(
        task: task,
        onComplete: onComplete,
      ),
    );
  }
}