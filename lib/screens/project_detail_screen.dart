import 'package:flutter/material.dart';
import '../models/project.dart';
import '../models/task.dart';
import '../models/stage.dart';
import '../models/task_type.dart';
import '../services/firestore_service.dart';
import '../services/task_service.dart';
import '../widgets/dialogs.dart';
import '../utils/progress_utils.dart';
import '../widgets/task_edit_dialog.dart';
import 'package:intl/intl.dart';
import '../models/step.dart' as custom_step;
import '../widgets/stage_edit_dialog.dart';
import '../widgets/step_edit_dialog.dart';

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

    if (task.stages.isNotEmpty) {
      children.addAll([
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Text(
            'Этапы:',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ),
        ...task.stages.map((stage) => _buildStageWidget(stage, task)),
      ]);
    }

    children.addAll([
      const Divider(height: 1, color: Colors.grey, indent: 16, endIndent: 16),
      ListTile(
        leading: const Icon(Icons.add, size: 20),
        title: const Text('Добавить этап', style: TextStyle(fontSize: 14)),
        onTap: () => _addStage(task),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      ),
    ]);

    return children;
  }

  Widget _buildStageWidget(Stage stage, Task task) {
    final stageProgress = ProgressUtils.calculateProgress(
        stage.completedSteps, stage.totalSteps);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ExpansionTile(
        leading: stage.stageType == 'singleStep'
            ? Checkbox(
          value: stage.isCompleted,
          onChanged: (value) => _toggleStageCompletion(stage, task),
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
          stage.name,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            decoration: stage.stageType == 'singleStep' && stage.isCompleted
                ? TextDecoration.lineThrough
                : null,
          ),
        ),
        subtitle: stage.stageType == 'stepByStep'
            ? Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(
              '${stage.completedSteps}/${stage.totalSteps} шагов',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 4),
            ProgressUtils.buildAnimatedProgressBar(stageProgress, height: 6),
          ],
        )
            : Text(
          stage.isCompleted ? 'Выполнено' : 'Не выполнено',
          style: TextStyle(
            fontSize: 11,
            color: stage.isCompleted ? Colors.green : Colors.grey.shade600,
          ),
        ),
        children: _buildStageChildren(stage, task),
      ),
    );
  }

  List<Widget> _buildStageChildren(Stage stage, Task task) {
    final children = <Widget>[];

    children.add(
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Wrap(
          spacing: 8,
          children: [
            if (stage.stageType == "stepByStep")
              _buildActionButton(
                icon: Icons.add,
                color: Colors.green,
                tooltip: 'Добавить прогресс этапа',
                onPressed: () => _addStageProgress(stage, task),
              ),
            _buildActionButton(
              icon: Icons.edit,
              color: Colors.blue,
              tooltip: 'Редактировать этап',
              onPressed: () => _editStage(stage, task),
            ),
            _buildActionButton(
              icon: Icons.delete,
              color: Colors.red,
              tooltip: 'Удалить этап',
              onPressed: () => _deleteStage(stage, task),
            ),
          ],
        ),
      ),
    );

    if (stage.steps.isNotEmpty) {
      children.addAll([
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Text(
            'Шаги:',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ),
        ...stage.steps.map((step) => _buildStepWidget(step, stage, task)),
      ]);
    }

    children.addAll([
      const Divider(height: 1, color: Colors.grey, indent: 16, endIndent: 16),
      ListTile(
        leading: const Icon(Icons.add, size: 20),
        title: const Text('Добавить шаг', style: TextStyle(fontSize: 14)),
        onTap: () => _addStep(stage, task),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      ),
    ]);

    return children;
  }

  Widget _buildStepWidget(custom_step.Step step, Stage stage, Task task) {
    final stepProgress = ProgressUtils.calculateProgress(
        step.completedSteps, step.totalSteps);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: ListTile(
        dense: true,
        visualDensity: VisualDensity.compact,
        leading: step.stepType == 'singleStep'
            ? Checkbox(
          value: step.isCompleted,
          onChanged: (value) => _toggleStepCompletion(step, stage, task),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        )
            : Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.circle, size: 12, color: Colors.green.shade700),
        ),
        title: Text(
          step.name,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            decoration: step.stepType == 'singleStep' && step.isCompleted
                ? TextDecoration.lineThrough
                : null,
          ),
        ),
        subtitle: step.stepType == 'stepByStep'
            ? Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(
              '${step.completedSteps}/${step.totalSteps} шагов',
              style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 4),
            ProgressUtils.buildAnimatedProgressBar(stepProgress, height: 4),
          ],
        )
            : Text(
          step.isCompleted ? 'Выполнено' : 'Не выполнено',
          style: TextStyle(
            fontSize: 10,
            color: step.isCompleted ? Colors.green : Colors.grey.shade600,
          ),
        ),
        trailing: Wrap(
          spacing: 4,
          children: [
            if (step.stepType == 'stepByStep')
              IconButton(
                icon: Icon(Icons.add, size: 16, color: Colors.green.shade600),
                onPressed: () => _addStepProgress(step, stage, task),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            IconButton(
              icon: Icon(Icons.edit, size: 16, color: Colors.blue.shade600),
              onPressed: () => _editStep(step, stage, task),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            IconButton(
              icon: Icon(Icons.delete, size: 16, color: Colors.red.shade600),
              onPressed: () => _deleteStep(step, stage, task),
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
    final wasCompleted = task.isCompleted;

    setState(() {
      final taskIndex = widget.project.tasks.indexOf(task);
      widget.project.tasks[taskIndex] = TaskService.toggleTaskCompletion(task);
    });

    if (!wasCompleted) {
      widget.onAddProgressHistory(task.name, 1, 'task');
    } else {
      widget.onAddProgressHistory("Отмена: ${task.name}", -1, 'task');
    }

    widget.onProjectUpdated(widget.project);
  }

  void _toggleStageCompletion(Stage stage, Task task) {
    final wasCompleted = stage.isCompleted;

    setState(() {
      final stageIndex = task.stages.indexOf(stage);
      task.stages[stageIndex] = TaskService.toggleStageCompletion(stage);
    });

    if (!wasCompleted) {
      widget.onAddProgressHistory(stage.name, 1, 'stage');
    } else {
      widget.onAddProgressHistory("Отмена: ${stage.name}", -1, 'stage');
    }

    widget.onProjectUpdated(widget.project);
  }

  void _toggleStepCompletion(custom_step.Step step, Stage stage, Task task) {
    final wasCompleted = step.isCompleted;

    setState(() {
      final stepIndex = stage.steps.indexOf(step);
      stage.steps[stepIndex] = TaskService.toggleStepCompletion(step);
    });

    if (!wasCompleted) {
      widget.onAddProgressHistory(step.name, 1, 'step');
    } else {
      widget.onAddProgressHistory("Отмена: ${step.name}", -1, 'step');
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

  void _addStage(Task task) async {
    final stage = await showDialog<Stage>(
      context: context,
      builder: (context) => StageEditDialog(
        onSave: (newStage) {
          setState(() {
            task.stages.add(newStage);
          });
          widget.onProjectUpdated(widget.project);
        },
      ),
    );
  }

  void _editStage(Stage stage, Task task) async {
    final updatedStage = await showDialog<Stage>(
      context: context,
      builder: (context) => StageEditDialog(
        initialStage: stage,
        onSave: (newStage) {
          setState(() {
            final stageIndex = task.stages.indexOf(stage);
            task.stages[stageIndex] = newStage;
          });
          widget.onProjectUpdated(widget.project);
        },
      ),
    );
  }

  void _deleteStage(Stage stage, Task task) async {
    final confirm = await Dialogs.showConfirmDialog(
      context: context,
      title: 'Удалить этап',
      message: 'Вы уверены, что хотите удалить "${stage.name}"?',
    );

    if (confirm) {
      setState(() {
        task.stages.remove(stage);
      });
      widget.onProjectUpdated(widget.project);
    }
  }

  void _addStep(Stage stage, Task task) async {
    final step = await showDialog<custom_step.Step>(
      context: context,
      builder: (context) => StepEditDialog(
        onSave: (newStep) {
          setState(() {
            stage.steps.add(newStep);
          });
          widget.onProjectUpdated(widget.project);
        },
      ),
    );
  }

  void _editStep(custom_step.Step step, Stage stage, Task task) async {
    final updatedStep = await showDialog<custom_step.Step>(
      context: context,
      builder: (context) => StepEditDialog(
        initialStep: step,
        onSave: (newStep) {
          setState(() {
            final stepIndex = stage.steps.indexOf(step);
            stage.steps[stepIndex] = newStep;
            widget.onProjectUpdated(widget.project);
          });
        },
      ),
    );
  }

  void _deleteStep(custom_step.Step step, Stage stage, Task task) async {
    final confirm = await Dialogs.showConfirmDialog(
      context: context,
      title: 'Удалить шаг',
      message: 'Вы уверены, что хотите удалить "${step.name}"?',
    );

    if (confirm) {
      setState(() {
        stage.steps.remove(step);
        widget.onProjectUpdated(widget.project);
      });
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
        final taskIndex = widget.project.tasks.indexOf(task);
        widget.project.tasks[taskIndex] = TaskService.addProgressToTask(task, steps);
      });
      widget.onProjectUpdated(widget.project);
      widget.onAddProgressHistory(task.name, steps, 'task');
    }
  }

  void _addStageProgress(Stage stage, Task task) async {
    final steps = await Dialogs.showNumberInputDialog(
      context: context,
      title: 'Добавить прогресс: ${stage.name}',
      message: 'Текущий прогресс: ${stage.completedSteps}/${stage.totalSteps}',
    );

    if (steps != null && steps > 0) {
      setState(() {
        final stageIndex = task.stages.indexOf(stage);
        task.stages[stageIndex] = TaskService.addProgressToStage(stage, steps);
      });
      widget.onProjectUpdated(widget.project);
      widget.onAddProgressHistory(stage.name, steps, 'stage');
    }
  }

  void _addStepProgress(custom_step.Step step, Stage stage, Task task) async {
    final steps = await Dialogs.showNumberInputDialog(
      context: context,
      title: 'Добавить прогресс: ${step.name}',
      message: 'Текущий прогресс: ${step.completedSteps}/${step.totalSteps}',
    );

    if (steps != null && steps > 0) {
      setState(() {
        final stepIndex = stage.steps.indexOf(step);
        stage.steps[stepIndex] = TaskService.addProgressToStep(step, steps);
      });
      widget.onProjectUpdated(widget.project);
      widget.onAddProgressHistory(step.name, steps, 'step');
    }
  }
}