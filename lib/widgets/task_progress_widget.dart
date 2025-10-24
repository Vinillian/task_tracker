// lib/widgets/task_progress_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/task.dart';
import '../models/task_type.dart';
import '../providers/task_provider.dart';

class TaskProgressWidget extends ConsumerWidget {
  final String taskId;
  final VoidCallback? onTap;

  const TaskProgressWidget({
    super.key,
    required this.taskId,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final task = ref.watch(taskByIdProvider(taskId));
    if (task == null) return const SizedBox();

    return GestureDetector(
      onTap: onTap,
      child: task.type == TaskType.stepByStep
          ? _buildStepProgress(task, ref)
          : _buildCheckbox(task, ref),
    );
  }

  Widget _buildStepProgress(Task task, WidgetRef ref) {
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
  }

  Widget _buildCheckbox(Task task, WidgetRef ref) {
    return Checkbox(
      value: task.isCompleted,
      onChanged: (value) {
        ref.read(tasksProvider.notifier).toggleTaskCompletion(taskId);
      },
    );
  }
}
