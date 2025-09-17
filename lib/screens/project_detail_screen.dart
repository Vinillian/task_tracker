import 'package:flutter/material.dart';
import '../models/project.dart';
import '../models/task.dart';
import '../models/subtask.dart';
import '../models/task_type.dart';
import '../services/firestore_service.dart';
import '../services/task_service.dart';
import '../widgets/dialogs.dart';
import '../utils/progress_utils.dart';
import '../widgets/task_edit_dialog.dart';
import '../widgets/subtask_edit_dialog.dart';
import 'package:intl/intl.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.project.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _editProjectName,
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
              leading: _buildTaskLeading(task, taskProgress),
              title: Text(
                task.name,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 15,
                ),
              ),
              subtitle: _buildTaskSubtitle(task, taskProgress),
              children: _buildTaskChildren(task),
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

  Widget _buildTaskLeading(Task task, double progress) {
    if (task.taskType == "singleStep") {
      return Checkbox(
        value: task.isCompleted,
        onChanged: (value) {
          _toggleTaskCompletion(task);
        },
        shape: const CircleBorder(),
      );
    } else {
      return Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: ProgressUtils.getTaskColor(progress).withOpacity(0.2),
          shape: BoxShape.circle,
          border: Border.all(color: ProgressUtils.getTaskColor(progress)),
        ),
        child: Center(
          child: Text(
            '${(progress * 100).toInt()}%',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: ProgressUtils.getTaskColor(progress),
            ),
          ),
        ),
      );
    }
  }

  Widget _buildTaskSubtitle(Task task, double progress) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (task.description != null)
          Text(
            task.description!,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        const SizedBox(height: 4),
        if (task.taskType == "stepByStep")
          Text(
            '${task.completedSteps}/${task.totalSteps} шагов',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        if (task.taskType == "singleStep")
          Text(
            task.isCompleted ? 'Выполнено' : 'Не выполнено',
            style: TextStyle(
              fontSize: 12,
              color: task.isCompleted ? Colors.green : Colors.grey.shade600,
              fontWeight: FontWeight.bold,
            ),
          ),
        if (task.dueDate != null)
          Text(
            'Срок: ${DateFormat('dd.MM.yyyy').format(task.dueDate!)}',
            style: TextStyle(fontSize: 11, color: Colors.orange),
          ),
        if (task.recurrence != null)
          Text(
            task.recurrence!.displayText,
            style: TextStyle(fontSize: 11, color: Colors.blue),
          ),
        const SizedBox(height: 6),
        if (task.taskType == "stepByStep")
          ProgressUtils.buildAnimatedProgressBar(progress),
      ],
    );
  }

  List<Widget> _buildTaskChildren(Task task) {
    final children = <Widget>[];

    children.add(
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Wrap(
          spacing: 8,
          children: [
            if (task.taskType == "stepByStep")
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
    );

    if (task.subtasks.isNotEmpty) {
      children.addAll([
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
        ...task.subtasks.map((subtask) => _buildSubtaskWidget(subtask, task)),
      ]);
    }

    children.addAll([
      const Divider(height: 1, color: Colors.grey, indent: 16, endIndent: 16),
      ListTile(
        leading: const Icon(Icons.add, size: 20),
        title: const Text('Добавить подзадачу', style: TextStyle(fontSize: 14)),
        onTap: () => _addSubtask(task),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      ),
    ]);

    return children;
  }

  Widget _buildSubtaskWidget(Subtask subtask, Task task) {
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
        leading: subtask.subtaskType == 'singleStep'
            ? Checkbox(
          value: subtask.isCompleted,
          onChanged: (value) => _toggleSubtaskCompletion(subtask, task),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        )
            : Container(
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
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            decoration: subtask.subtaskType == 'singleStep' && subtask.isCompleted
                ? TextDecoration.lineThrough
                : null,
          ),
        ),
        subtitle: subtask.subtaskType == 'stepByStep'
            ? Column(
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
        )
            : Text(
          subtask.isCompleted ? 'Выполнено' : 'Не выполнено',
          style: TextStyle(
            fontSize: 11,
            color: subtask.isCompleted ? Colors.green : Colors.grey.shade600,
          ),
        ),
        trailing: Wrap(
          spacing: 4,
          children: [
            if (subtask.subtaskType == 'stepByStep')
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
  }

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

  void _toggleTaskCompletion(Task task) {
    setState(() {
      final taskIndex = widget.project.tasks.indexOf(task);
      widget.project.tasks[taskIndex] = TaskService.toggleTaskCompletion(task);
    });

    if (task.isCompleted) {
      widget.onAddProgressHistory(task.name, 1, 'task');
    }

    widget.onProjectUpdated(widget.project);
  }

  void _toggleSubtaskCompletion(Subtask subtask, Task task) {
    setState(() {
      final subtaskIndex = task.subtasks.indexOf(subtask);
      task.subtasks[subtaskIndex] = TaskService.toggleSubtaskCompletion(subtask);
    });

    if (subtask.isCompleted) {
      widget.onAddProgressHistory(subtask.name, 1, 'subtask');
    }

    widget.onProjectUpdated(widget.project);
  }

  void _editProjectName() async {
    final newName = await Dialogs.showTextInputDialog(
      context: context,
      title: 'Редактировать проект',
      initialValue: widget.project.name,
    );

    if (newName != null && newName.isNotEmpty) {
      final updatedProject = Project(
        name: newName,
        tasks: widget.project.tasks,
      );
      widget.onProjectUpdated(updatedProject);
    }
  }

  void _addTask() async {
    final task = await showDialog<Task>(
      context: context,
      builder: (context) => TaskEditDialog(
        onSave: (newTask) {
          setState(() {
            widget.project.tasks.add(newTask);
          });
          widget.onProjectUpdated(widget.project);
        },
      ),
    );
  }

  void _editTask(Task task) async {
    final updatedTask = await showDialog<Task>(
      context: context,
      builder: (context) => TaskEditDialog(
        initialTask: task,
        onSave: (newTask) {
          setState(() {
            final taskIndex = widget.project.tasks.indexOf(task);
            widget.project.tasks[taskIndex] = newTask;
          });
          widget.onProjectUpdated(widget.project);
        },
      ),
    );
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
    final subtask = await showDialog<Subtask>(
      context: context,
      builder: (context) => SubtaskEditDialog(
        onSave: (newSubtask) {
          setState(() {
            task.subtasks.add(newSubtask);
          });
          widget.onProjectUpdated(widget.project);
        },
      ),
    );
  }

  void _editSubtask(Subtask subtask, Task task) async {
    final updatedSubtask = await showDialog<Subtask>(
      context: context,
      builder: (context) => SubtaskEditDialog(
        initialSubtask: subtask,
        onSave: (newSubtask) {
          setState(() {
            final subtaskIndex = task.subtasks.indexOf(subtask);
            task.subtasks[subtaskIndex] = newSubtask;
          });
          widget.onProjectUpdated(widget.project);
        },
      ),
    );
  }

  void _addTaskProgress(Task task) async {
    final steps = await Dialogs.showNumberInputDialog(
      context: context,
      title: 'Добавить прогресс: ${task.name}',
      message: 'Текущий прогресс: ${task.completedSteps}/${task.totalSteps}',
    );

    if (steps != null && steps > 0) {
      setState(() {
        final taskIndex = widget.project.tasks.indexOf(task);
        widget.project.tasks[taskIndex] = TaskService.addProgressToTask(task, steps);
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
        final subtaskIndex = task.subtasks.indexOf(subtask);
        task.subtasks[subtaskIndex] = TaskService.addProgressToSubtask(subtask, steps);
      });
      widget.onProjectUpdated(widget.project);
      widget.onAddProgressHistory(subtask.name, steps, 'subtask');
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
}