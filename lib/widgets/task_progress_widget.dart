// widgets/task_progress_widget.dart
import 'package:flutter/material.dart';
import '../models/task.dart';
import '../models/task_type.dart';

class TaskProgressWidget extends StatelessWidget {
  final Task task;
  final VoidCallback onToggle;

  const TaskProgressWidget({
    super.key,
    required this.task,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    if (task.type == TaskType.stepByStep) {
      // ✅ ПОШАГОВАЯ ЗАДАЧА - прогресс бар
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              value: task.progress,
              strokeWidth: 3,
            ),
          ),
          Text(
            '${task.completedSteps}/${task.totalSteps}',
            style: const TextStyle(fontSize: 10),
          ),
        ],
      );
    } else {
      // ✅ ОДИНОЧНАЯ ЗАДАЧА - чекбокс
      return Checkbox(
        value: task.isCompleted,
        onChanged: (value) => onToggle(),
      );
    }
  }
}