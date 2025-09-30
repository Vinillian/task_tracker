// widgets/task_card.dart
import 'package:flutter/material.dart';
import '../models/task.dart';
import '../models/task_type.dart';
import '../screens/task_management_screen.dart';
import 'task_progress_widget.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final int taskIndex;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final Function(int) onUpdateSteps;
  final Function(Task)? onTaskUpdated;

  const TaskCard({
    super.key,
    required this.task,
    required this.taskIndex,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
    required this.onUpdateSteps,
    this.onTaskUpdated,
  });

  void _manageTaskSteps(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text('Управление: ${task.title}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Прогресс: ${task.completedSteps}/${task.totalSteps}'),
                const SizedBox(height: 16),
                LinearProgressIndicator(value: task.progress),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: task.completedSteps > 0
                          ? () {
                        onUpdateSteps(task.completedSteps - 1);
                        Navigator.pop(context);
                      }
                          : null,
                      child: const Text('-1'),
                    ),
                    ElevatedButton(
                      onPressed: task.completedSteps < task.totalSteps
                          ? () {
                        onUpdateSteps(task.completedSteps + 1);
                        Navigator.pop(context);
                      }
                          : null,
                      child: const Text('+1'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (task.totalSteps > 1) ...[
                  const Text('Или установите точное значение:'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Slider(
                          value: task.completedSteps.toDouble(),
                          min: 0,
                          max: task.totalSteps.toDouble(),
                          divisions: task.totalSteps,
                          onChanged: (value) {
                            setState(() {
                              onUpdateSteps(value.toInt());
                            });
                          },
                          onChangeEnd: (value) {
                            Navigator.pop(context);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Закрыть'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _navigateToTaskManagement(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TaskManagementScreen(
          task: task,
          onTaskUpdated: onTaskUpdated ?? (updatedTask) {
            // Если не передан колбэк, просто обновляем текущее состояние
            onUpdateSteps(updatedTask.completedSteps);
          },
          onTaskDeleted: onDelete,
        ),
      ),
    );
  }

  Widget _buildSubTasksIndicator() {
    if (task.subTasks.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.subdirectory_arrow_right, size: 12, color: Colors.blue),
          const SizedBox(width: 4),
          Text(
            '${task.subTasks.length}',
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskTypeIndicator() {
    if (task.type == TaskType.stepByStep) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.purple.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.purple.shade100),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.linear_scale, size: 10, color: Colors.purple),
            SizedBox(width: 2),
            Text(
              'шаги',
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.bold,
                color: Colors.purple,
              ),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Прогресс/чекбокс
                TaskProgressWidget(
                  task: task,
                  onToggle: onToggle,
                ),
                const SizedBox(width: 12),

                // Основное содержимое задачи
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Заголовок и индикаторы
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              task.title,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                decoration: task.isCompleted && task.type == TaskType.single
                                    ? TextDecoration.lineThrough
                                    : TextDecoration.none,
                                color: task.isCompleted && task.type == TaskType.single
                                    ? Colors.grey
                                    : Colors.black87,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildSubTasksIndicator(),
                          if (task.type == TaskType.stepByStep) ...[
                            const SizedBox(width: 4),
                            _buildTaskTypeIndicator(),
                          ],
                        ],
                      ),

                      // Описание
                      if (task.description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          task.description,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],

                      // Дополнительная информация
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          // Прогресс текстом
                          if (task.type == TaskType.stepByStep) ...[
                            Text(
                              '${task.completedSteps}/${task.totalSteps} шагов',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(width: 12),
                          ],

                          // Уровень вложенности
                          if (task.calculateDepth() > 0) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.orange.shade100),
                              ),
                              child: Text(
                                'уровень ${task.calculateDepth() + 1}',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.orange.shade700,
                                ),
                              ),
                            ),
                          ],

                          const Spacer(),

                          // Дата создания (если нужно)
                          Text(
                            _formatDate(task.id),
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Кнопки действий
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Кнопка управления подзадачами
                if (task.canAddSubTask) ...[
                  OutlinedButton.icon(
                    icon: const Icon(Icons.subdirectory_arrow_right, size: 16),
                    label: const Text('Подзадачи'),
                    onPressed: () => _navigateToTaskManagement(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],

                // Кнопка управления шагами (для пошаговых задач)
                if (task.type == TaskType.stepByStep) ...[
                  OutlinedButton.icon(
                    icon: const Icon(Icons.play_arrow, size: 16),
                    label: const Text('Шаги'),
                    onPressed: () => _manageTaskSteps(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],

                // Кнопка редактирования
                IconButton(
                  icon: const Icon(Icons.edit, size: 18, color: Colors.blue),
                  onPressed: onEdit,
                  tooltip: 'Редактировать задачу',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                ),

                // Кнопка удаления
                IconButton(
                  icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                  onPressed: onDelete,
                  tooltip: 'Удалить задачу',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String id) {
    try {
      final timestamp = int.tryParse(id);
      if (timestamp != null) {
        final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
        return '${date.day}.${date.month}.${date.year}';
      }
    } catch (e) {
      // ignore: empty_catches
    }
    return 'недавно';
  }
}