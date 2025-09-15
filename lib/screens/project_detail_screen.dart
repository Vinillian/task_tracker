import 'package:flutter/material.dart';
import '../models/project.dart';
import '../models/task.dart';
import '../models/subtask.dart';
import '../services/firestore_service.dart';
import '../services/task_service.dart';
import '../widgets/dialogs.dart';
import '../utils/progress_utils.dart';

class ProjectDetailScreen extends StatefulWidget {
  final Project project;
  final Function(Project) onProjectUpdated;
  final Function(String, int, String) onAddProgressHistory;

  const ProjectDetailScreen({
    super.key,
    required this.project,
    required this.onProjectUpdated,
    required this.onAddProgressHistory,
  });

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  // Вспомогательный метод для кнопок действий
  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: IconButton(
        icon: Icon(icon, size: 18, color: color),
        onPressed: onPressed,
        tooltip: tooltip,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
      ),
    );
  }

  void _addTask() async {
    final name = await Dialogs.showTextInputDialog(
      context: context,
      title: 'Новая задача',
      initialValue: '',
    );
    if (name != null && name.isNotEmpty) {
      final steps = await Dialogs.showNumberInputDialog(
        context: context,
        title: 'Количество шагов для "$name"',
        message: 'Введите общее количество шагов для задачи',
      );

      if (steps != null && steps > 0) {
        setState(() {
          widget.project.tasks.add(TaskService.createTask(name, steps));
        });
        widget.onProjectUpdated(widget.project);
      }
    }
  }

  void _editTask(Task task) async {
    final name = await Dialogs.showTextInputDialog(
      context: context,
      title: 'Редактировать задачу',
      initialValue: task.name,
    );

    if (name != null && name.isNotEmpty) {
      final steps = await Dialogs.showNumberInputDialog(
        context: context,
        title: 'Количество шагов для "$name"',
        message: 'Текущее количество: ${task.totalSteps}',
        initialValue: task.totalSteps.toString(),
      );

      if (steps != null && steps > 0) {
        setState(() {
          TaskService.updateTask(task, name, steps);
        });
        widget.onProjectUpdated(widget.project);
      }
    }
  }

  void _deleteTask(Task task) async {
    final confirm = await Dialogs.showConfirmDialog(
      context: context,
      title: 'Удалить задачу',
      message: 'Вы уверены, что хотите удалить "${task.name}"?',
    );

    if (confirm) {
      setState(() {
        widget.project.tasks.remove(task);
      });
      widget.onProjectUpdated(widget.project);
    }
  }

  void _addSubtask(Task task) async {
    final name = await Dialogs.showTextInputDialog(
      context: context,
      title: 'Новая подзадача',
      initialValue: '',
    );

    if (name != null && name.isNotEmpty) {
      final steps = await Dialogs.showNumberInputDialog(
        context: context,
        title: 'Количество шагов для "$name"',
        message: 'Введите общее количество шагов для подзадачи',
      );

      if (steps != null && steps > 0) {
        setState(() {
          task.subtasks.add(TaskService.createSubtask(name, steps));
        });
        widget.onProjectUpdated(widget.project);
      }
    }
  }

  void _addTaskProgress(Task task) async {
    final steps = await Dialogs.showNumberInputDialog(
      context: context,
      title: 'Добавить прогресс: ${task.name}',
      message: 'Текущий прогресс: ${task.completedSteps}/${task.totalSteps}',
    );

    if (steps != null && steps > 0) {
      setState(() {
        task.completedSteps = (task.completedSteps + steps).clamp(0, task.totalSteps);
      });
      widget.onProjectUpdated(widget.project);

      widget.onAddProgressHistory(task.name, steps, 'task');
    }
  }

  void _addSubtaskProgress(Subtask subtask, Task task) async {
    final steps = await Dialogs.showNumberInputDialog(
      context: context,
      title: 'Добавить прогресс: ${subtask.name}',
      message: 'Текущий прогресс: ${subtask.completedSteps}/${subtask.totalSteps}',
    );

    if (steps != null && steps > 0) {
      setState(() {
        subtask.completedSteps = (subtask.completedSteps + steps).clamp(0, subtask.totalSteps);
      });
      widget.onProjectUpdated(widget.project);

      widget.onAddProgressHistory(subtask.name, steps, 'subtask');
    }
  }

  void _editSubtask(Subtask subtask, Task task) async {
    final name = await Dialogs.showTextInputDialog(
      context: context,
      title: 'Редактировать подзадачу',
      initialValue: subtask.name,
    );

    if (name != null && name.isNotEmpty) {
      final steps = await Dialogs.showNumberInputDialog(
        context: context,
        title: 'Количество шагов для "$name"',
        message: 'Текущее количество: ${subtask.totalSteps}',
        initialValue: subtask.totalSteps.toString(),
      );

      if (steps != null && steps > 0) {
        setState(() {
          TaskService.updateSubtask(subtask, name, steps);
        });
        widget.onProjectUpdated(widget.project);
      }
    }
  }

  void _deleteSubtask(Subtask subtask, Task task) async {
    final confirm = await Dialogs.showConfirmDialog(
      context: context,
      title: 'Удалить подзадачу',
      message: 'Вы уверены, что хотите удалить "${subtask.name}"?',
    );

    if (confirm) {
      setState(() {
        task.subtasks.remove(subtask);
      });
      widget.onProjectUpdated(widget.project);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.project.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final newName = await Dialogs.showTextInputDialog(
                context: context,
                title: 'Редактировать проект',
                initialValue: widget.project.name,
              );

              if (newName != null && newName.isNotEmpty) {
                setState(() {
                  widget.project.name = newName;
                });
                widget.onProjectUpdated(widget.project);
              }
            },
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: widget.project.tasks.length,
        itemBuilder: (context, index) {
          final task = widget.project.tasks[index];
          final taskProgress = ProgressUtils.calculateProgress(task.completedSteps, task.totalSteps);

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(color: Colors.grey.shade200, width: 1),
            ),
            child: ExpansionTile(
              leading: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: ProgressUtils.getTaskColor(taskProgress).withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: ProgressUtils.getTaskColor(taskProgress)),
                ),
                child: Center(
                  child: Text(
                    '${(taskProgress * 100).toInt()}%',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: ProgressUtils.getTaskColor(taskProgress),
                    ),
                  ),
                ),
              ),
              title: Text(
                task.name,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 15,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(
                    '${task.completedSteps}/${task.totalSteps} шагов',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 6),
                  ProgressUtils.buildAnimatedProgressBar(taskProgress),
                ],
              ),
              children: [
                // Кнопки управления задачей
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Wrap(
                    spacing: 8,
                    children: [
                      _buildActionButton(
                        icon: Icons.add,
                        color: Colors.green,
                        tooltip: 'Добавить прогресс',
                        onPressed: () => _addTaskProgress(task),
                      ),
                      _buildActionButton(
                        icon: Icons.edit,
                        color: Colors.blue,
                        tooltip: 'Редактировать',
                        onPressed: () => _editTask(task),
                      ),
                      _buildActionButton(
                        icon: Icons.delete,
                        color: Colors.red,
                        tooltip: 'Удалить',
                        onPressed: () => _deleteTask(task),
                      ),
                    ],
                  ),
                ),

                // Заголовок подзадач
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Text(
                    'Подзадачи:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ),

                // Подзадачи
                ...task.subtasks.map((subtask) {
                  final subtaskProgress = ProgressUtils.calculateProgress(
                      subtask.completedSteps, subtask.totalSteps);

                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: ListTile(
                      dense: true,
                      visualDensity: VisualDensity.compact,
                      leading: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.arrow_right, size: 16, color: Colors.blue.shade700),
                      ),
                      title: Text(
                        subtask.name,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 2),
                          Text(
                            '${subtask.completedSteps}/${subtask.totalSteps} шагов',
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                          ),
                          const SizedBox(height: 4),
                          ProgressUtils.buildAnimatedProgressBar(subtaskProgress, height: 6),
                        ],
                      ),
                      trailing: Wrap(
                        spacing: 4,
                        children: [
                          IconButton(
                            icon: Icon(Icons.add, size: 18, color: Colors.green.shade600),
                            onPressed: () => _addSubtaskProgress(subtask, task),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          IconButton(
                            icon: Icon(Icons.edit, size: 18, color: Colors.blue.shade600),
                            onPressed: () => _editSubtask(subtask, task),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete, size: 18, color: Colors.red.shade600),
                            onPressed: () => _deleteSubtask(subtask, task),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  );
                }).toList(),

                // Разделитель перед кнопкой добавления подзадачи
                const Divider(height: 1, color: Colors.grey, indent: 16, endIndent: 16),

                // Кнопка добавления подзадачи
                ListTile(
                  leading: const Icon(Icons.add, size: 20),
                  title: const Text('Добавить подзадачу', style: TextStyle(fontSize: 14)),
                  onTap: () => _addSubtask(task),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addTask,
        child: const Icon(Icons.add),
      ),
    );
  }
}