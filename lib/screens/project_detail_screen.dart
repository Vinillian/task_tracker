import 'package:flutter/material.dart';
import '../models/project.dart';
import '../models/task.dart';
import '../models/subtask.dart';

class ProjectDetailScreen extends StatefulWidget {
  final Project project;
  final Function() onDeleteProject;
  final Function(String, int, String) onAddProgressHistory;

  const ProjectDetailScreen({
    super.key,
    required this.project,
    required this.onDeleteProject,
    required this.onAddProgressHistory,
  });

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  final Map<int, bool> _showTaskInput = {};
  final Map<String, bool> _showSubtaskInput = {};
  final Map<String, TextEditingController> _taskNameControllers = {};
  final Map<String, TextEditingController> _taskStepsControllers = {};
  final Map<String, TextEditingController> _subtaskNameControllers = {};
  final Map<String, TextEditingController> _subtaskStepsControllers = {};

  TextEditingController _getTaskNameController(int taskIndex) {
    final key = 't$taskIndex';
    if (!_taskNameControllers.containsKey(key)) {
      _taskNameControllers[key] = TextEditingController();
      _taskStepsControllers[key] = TextEditingController();
    }
    return _taskNameControllers[key]!;
  }

  TextEditingController _getTaskStepsController(int taskIndex) {
    final key = 't$taskIndex';
    if (!_taskStepsControllers.containsKey(key)) {
      _taskNameControllers[key] = TextEditingController();
      _taskStepsControllers[key] = TextEditingController();
    }
    return _taskStepsControllers[key]!;
  }

  TextEditingController _getSubtaskNameController(int taskIndex, int subtaskIndex) {
    final key = 't${taskIndex}s$subtaskIndex';
    if (!_subtaskNameControllers.containsKey(key)) {
      _subtaskNameControllers[key] = TextEditingController();
      _subtaskStepsControllers[key] = TextEditingController();
    }
    return _subtaskNameControllers[key]!;
  }

  TextEditingController _getSubtaskStepsController(int taskIndex, int subtaskIndex) {
    final key = 't${taskIndex}s$subtaskIndex';
    if (!_subtaskStepsControllers.containsKey(key)) {
      _subtaskNameControllers[key] = TextEditingController();
      _subtaskStepsControllers[key] = TextEditingController();
    }
    return _subtaskStepsControllers[key]!;
  }

  // Добавим эти методы в класс _ProjectDetailScreenState
  void _editProject() {
    final controller = TextEditingController(text: widget.project.name);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Редактировать проект'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Название проекта'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                setState(() {
                  widget.project.name = controller.text;
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }

  void _deleteProject() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить проект'),
        content: const Text('Вы уверены, что хотите удалить этот проект?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              widget.onDeleteProject(); // ← Вызов callback
              Navigator.pop(context); // Закрыть диалог
              Navigator.pop(context); // Вернуться к списку
            },
            child: const Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _handlePopupAction(String value) {
    switch (value) {
      case 'archive':
      // TODO: Реализовать архивацию
        break;
      case 'delete':
        _deleteProject();
        break;
    }
  }

  void _addTaskProgress(int taskIndex) {
    final task = widget.project.tasks[taskIndex];
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Прогресс: ${task.name}'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: 'Количество шагов'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              final steps = int.tryParse(controller.text) ?? 0;
              if (steps > 0) {
                setState(() {
                  widget.onAddProgressHistory(task.name, steps, 'task');
                  task.completedSteps += steps;
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Добавить'),
          ),
        ],
      ),
    );
  }



  // project_detail_screen.dart - обновим _addTask()
  void _addTask() {
    final nameController = TextEditingController();
    final stepsController = TextEditingController(text: '1');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Новая задача'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(hintText: 'Название задачи'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: stepsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(hintText: 'Количество шагов'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                final steps = int.tryParse(stepsController.text) ?? 1;
                setState(() {
                  widget.project.tasks.add(Task(
                    name: nameController.text,
                    totalSteps: steps,
                    completedSteps: 0,
                    subtasks: [],
                  ));
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Добавить'),
          ),
        ],
      ),
    );
  }

  void _addSubtask(int taskIndex) {
    final nameController = TextEditingController();
    final stepsController = TextEditingController(text: '1');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Новая подзадача'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(hintText: 'Название подзадачи'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: stepsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(hintText: 'Количество шагов'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                final steps = int.tryParse(stepsController.text) ?? 1;
                setState(() {
                  widget.project.tasks[taskIndex].subtasks.add(Subtask(
                    name: nameController.text,
                    totalSteps: steps,
                    completedSteps: 0,
                  ));
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Добавить'),
          ),
        ],
      ),
    );
  }

  void _editTask(int taskIndex) {
    final task = widget.project.tasks[taskIndex];
    final nameController = TextEditingController(text: task.name);
    final stepsController = TextEditingController(text: task.totalSteps.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Редактировать задачу'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(hintText: 'Название задачи'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: stepsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(hintText: 'Общее количество шагов'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                final steps = int.tryParse(stepsController.text) ?? task.totalSteps;
                setState(() {
                  task.name = nameController.text;
                  task.totalSteps = steps;
                  // Сохраняем прогресс в пределах новых шагов
                  task.completedSteps = task.completedSteps.clamp(0, steps);
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }

  void _editSubtask(int taskIndex, int subtaskIndex) {
    final subtask = widget.project.tasks[taskIndex].subtasks[subtaskIndex];
    final nameController = TextEditingController(text: subtask.name);
    final stepsController = TextEditingController(text: subtask.totalSteps.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Редактировать подзадачу'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(hintText: 'Название подзадачи'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: stepsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(hintText: 'Количество шагов'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                final steps = int.tryParse(stepsController.text) ?? subtask.totalSteps;
                setState(() {
                  subtask.name = nameController.text;
                  subtask.totalSteps = steps;
                  // Сохраняем прогресс в пределах новых шагов
                  subtask.completedSteps = subtask.completedSteps.clamp(0, steps);
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }

  void _updateProgress(int taskIndex, int subtaskIndex, int completedSteps) {
    setState(() {
      if (subtaskIndex >= 0) {
        final subtask = widget.project.tasks[taskIndex].subtasks[subtaskIndex];
        subtask.completedSteps = completedSteps.clamp(0, subtask.totalSteps);
      } else {
        final task = widget.project.tasks[taskIndex];
        task.completedSteps = completedSteps.clamp(0, task.totalSteps);
      }
    });
  }

  void _addSubtaskProgress(int taskIndex, int subtaskIndex) {
    final subtask = widget.project.tasks[taskIndex].subtasks[subtaskIndex];
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Прогресс: ${subtask.name}'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: 'Количество шагов'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              final steps = int.tryParse(controller.text) ?? 0;
              if (steps > 0) {
                setState(() {
                  widget.onAddProgressHistory(subtask.name, steps, 'subtask');
                  subtask.completedSteps += steps;

                });
                Navigator.pop(context);
              }
            },
            child: const Text('Добавить'),
          ),
        ],
      ),
    );
  }

  void _deleteTask(int taskIndex) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить задачу'),
        content: const Text('Вы уверены, что хотите удалить эту задачу?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                widget.project.tasks.removeAt(taskIndex);
              });
              Navigator.pop(context);
            },
            child: const Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _deleteSubtask(int taskIndex, int subtaskIndex) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить подзадачу'),
        content: const Text('Вы уверены, что хотите удалить эту подзадачу?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                widget.project.tasks[taskIndex].subtasks.removeAt(subtaskIndex);
              });
              Navigator.pop(context);
            },
            child: const Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // Добавьте эти методы ПЕРЕД _buildTaskList
  Color _getProgressColor(double progress) {
    if (progress >= 1.0) return Colors.green;
    if (progress >= 0.7) return Colors.orange;
    if (progress >= 0.3) return Colors.yellow;
    return Colors.red;
  }

  Color _getSubtaskProgressColor(double progress) {
    if (progress >= 1.0) return Colors.green;
    if (progress >= 0.7) return Colors.lightGreen;
    if (progress >= 0.4) return Colors.orange;
    if (progress >= 0.1) return Colors.amber;
    return Colors.red;
  }

  Widget _buildTaskList() {
    return ListView.builder(
      itemCount: widget.project.tasks.length,
      itemBuilder: (context, taskIndex) {
        final task = widget.project.tasks[taskIndex];
        // Прогресс задачи
        double taskProgress = task.totalSteps > 0
            ? task.completedSteps / task.totalSteps
            : 0;

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        task.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit, size: 20),
                      onPressed: () => _editTask(taskIndex),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () => _addSubtask(taskIndex),
                    ),
                  ],
                ),

                // Прогресс задачи
                LinearProgressIndicator(
                  value: taskProgress,
                  backgroundColor: Colors.grey[300],
                  color: _getProgressColor(taskProgress),
                ),

                const SizedBox(height: 8),

                // Кнопка прогресса и статистика
                Row(
                  children: [
                    Text('${task.completedSteps}/${task.totalSteps} шагов',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.add, size: 20),
                      onPressed: () => _addTaskProgress(taskIndex),
                    ),
                  ],
                ),

                // Подзадачи
                if (task.subtasks.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Подзадачи:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  ...task.subtasks.asMap().entries.map((entry) {
                    final subtaskIndex = entry.key;
                    final subtask = entry.value;
                    final subtaskProgress = subtask.totalSteps > 0
                        ? (subtask.completedSteps / subtask.totalSteps).toDouble()
                        : 0.0;
                    final progressColor = _getSubtaskProgressColor(subtaskProgress);

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: progressColor.withOpacity(0.2),
                        foregroundColor: progressColor,
                        child: Text(
                          '${(subtaskProgress * 100).toInt()}%',
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                      title: Text(subtask.name),
                      subtitle: Text('${subtask.completedSteps}/${subtask.totalSteps} шагов'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, size: 18),
                            onPressed: () => _editSubtask(taskIndex, subtaskIndex),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add, size: 18),
                            onPressed: () => _addSubtaskProgress(taskIndex, subtaskIndex),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    final totalSteps = widget.project.tasks.fold<int>(0, (sum, task) => sum + task.totalSteps);
    final completedSteps = widget.project.tasks.fold<int>(0, (sum, task) => sum + task.completedSteps);
    final progress = totalSteps > 0 ? completedSteps / totalSteps : 0;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.project.name),
            Text(
              '${(progress * 100).toStringAsFixed(0)}% • $completedSteps/$totalSteps шагов',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _editProject,
          ),
          PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'archive',
                child: Text('В архив'),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Text('Удалить', style: TextStyle(color: Colors.red)),
              ),
            ],
            onSelected: _handlePopupAction,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addTask,
        child: const Icon(Icons.add),
      ),
      body: widget.project.tasks.isEmpty
          ? const Center(
        child: Text(
          'Добавьте первую задачу',
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      )
          : _buildTaskList(),
    );
  }
}

