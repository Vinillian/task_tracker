import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  final Function(String, int, String) onAddProgressHistory; // ДОБАВИТЬ

  const ProjectDetailScreen({
    super.key,
    required this.project,
    required this.onProjectUpdated,
    required this.onAddProgressHistory, // ДОБАВИТЬ
  });

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  final FirestoreService _firestoreService = FirestoreService();

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

      // Передаем данные через callback
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

      // Передаем данные через callback
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
            color: ProgressUtils.getTaskColor(taskProgress),
            child: ExpansionTile(
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${task.name} (${task.completedSteps}/${task.totalSteps})'),
                  const SizedBox(height: 4),
                  ProgressUtils.buildAnimatedProgressBar(taskProgress),
                ],
              ),
              children: [
                // Кнопки управления задачей
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () => _addTaskProgress(task),
                        tooltip: 'Добавить прогресс',
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _editTask(task),
                        tooltip: 'Редактировать',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteTask(task),
                        tooltip: 'Удалить',
                      ),
                    ],
                  ),
                ),

                // Подзадачи
                ...task.subtasks.map((subtask) {
                  final subtaskProgress = ProgressUtils.calculateProgress(
                      subtask.completedSteps, subtask.totalSteps);

                  return ListTile(
                    title: Text(subtask.name),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${subtask.completedSteps}/${subtask.totalSteps}'),
                        ProgressUtils.buildAnimatedProgressBar(subtaskProgress),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.add, size: 20),
                          onPressed: () => _addSubtaskProgress(subtask, task),
                          tooltip: 'Добавить прогресс',
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit, size: 20),
                          onPressed: () => _editSubtask(subtask, task),
                          tooltip: 'Редактировать',
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                          onPressed: () => _deleteSubtask(subtask, task),
                          tooltip: 'Удалить',
                        ),
                      ],
                    ),
                  );
                }).toList(),

                // Кнопка добавления подзадачи
                ListTile(
                  leading: const Icon(Icons.add),
                  title: const Text('Добавить подзадачу'),
                  onTap: () => _addSubtask(task),
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