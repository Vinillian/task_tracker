import 'package:flutter/material.dart';
import '../models/project.dart';
import '../models/task.dart';
import '../services/task_service.dart';
import '../services/completion_service.dart';
import '../widgets/task_list_item.dart';
import '../widgets/task_edit_dialog.dart';

class ProjectDetailScreen extends StatefulWidget {
  final Project project;

  const ProjectDetailScreen({Key? key, required this.project}) : super(key: key);

  @override
  _ProjectDetailScreenState createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  late Project _project;
  late TaskService _taskService;
  late CompletionService _completionService;

  final List<Task> _selectedTasks = [];
  bool _selectionMode = false;

  @override
  void initState() {
    super.initState();
    _project = widget.project;
    _completionService = CompletionService();
    _taskService = TaskService(_completionService);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildBody(),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: Text(_project.name),
      actions: [
        if (_project.tasks.isNotEmpty) ...[
          IconButton(
            icon: Icon(_selectionMode ? Icons.cancel : Icons.select_all),
            onPressed: _toggleSelectionMode,
            tooltip: _selectionMode ? 'Отменить выбор' : 'Выбрать задачи',
          ),
          if (_selectionMode && _selectedTasks.isNotEmpty)
            IconButton(
              icon: Icon(Icons.delete),
              onPressed: _deleteSelectedTasks,
              tooltip: 'Удалить выбранные',
            ),
        ],
        PopupMenuButton<String>(
          onSelected: (value) {
            _handleMenuAction(value);
          },
          itemBuilder: (BuildContext context) => [
            PopupMenuItem(
              value: 'add_task',
              child: Row(
                children: [
                  Icon(Icons.add, color: Colors.green),
                  SizedBox(width: 8),
                  Text('Добавить задачу'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'project_stats',
              child: Row(
                children: [
                  Icon(Icons.analytics, color: Colors.blue),
                  SizedBox(width: 8),
                  Text('Статистика проекта'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBody() {
    if (_project.tasks.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        // Прогресс проекта
        _buildProjectProgress(),
        // Список задач
        Expanded(
          child: _buildTaskList(),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.task, size: 64, color: Colors.grey.shade300),
          SizedBox(height: 16),
          Text(
            'Пока нет задач',
            style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
          ),
          SizedBox(height: 8),
          Text(
            'Добавьте первую задачу в проект',
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectProgress() {
    final progress = _project.progress;
    return Card(
      margin: EdgeInsets.all(16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Прогресс проекта',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey.shade200,
              color: _getProgressColor(progress),
            ),
            SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${(progress * 100).toStringAsFixed(1)}%',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
                Text(
                  '${_project.allTasks.where((t) => t.isCompleted).length}/${_project.allTasks.length} задач',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskList() {
    return ListView.builder(
      padding: EdgeInsets.all(8),
      itemCount: _project.tasks.length,
      itemBuilder: (context, index) {
        final task = _project.tasks[index];
        return _buildTaskWithSubtasks(task);
      },
    );
  }

  Widget _buildTaskWithSubtasks(Task task) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Основная задача
        TaskListItem(
          task: task,
          nestingLevel: task.nestingLevel,
          onTap: () => _selectionMode
              ? _toggleTaskSelection(task)
              : _showTaskDetails(task),
          onComplete: () => _toggleTaskCompletion(task),
          onAddSubtask: task.canAddSubtask()
              ? () => _showAddSubtaskDialog(task)
              : null,
          onEdit: () => _showEditTaskDialog(task),
          onDelete: () => _deleteTask(task),
          isSelected: _selectedTasks.contains(task),
        ),
        // Рекурсивно отображаем подзадачи
        ...task.subtasks.map((subtask) => _buildTaskWithSubtasks(subtask)),
      ],
    );
  }

  Widget _buildFloatingActionButton() {
    if (_selectionMode) return SizedBox.shrink();

    return FloatingActionButton(
      onPressed: _showAddTaskDialog,
      child: Icon(Icons.add),
      tooltip: 'Добавить задачу',
    );
  }

  // === ОБРАБОТЧИКИ СОБЫТИЙ ===

  void _toggleSelectionMode() {
    setState(() {
      _selectionMode = !_selectionMode;
      if (!_selectionMode) {
        _selectedTasks.clear();
      }
    });
  }

  void _toggleTaskSelection(Task task) {
    setState(() {
      if (_selectedTasks.contains(task)) {
        _selectedTasks.remove(task);
      } else {
        _selectedTasks.add(task);
      }
    });
  }

  void _deleteSelectedTasks() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Удалить выбранные задачи?'),
        content: Text('Будет удалено ${_selectedTasks.length} задач${_selectedTasks.any((t) => t.hasSubtasks) ? ' вместе с подзадачами' : ''}.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _performDeleteSelectedTasks();
            },
            child: Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _performDeleteSelectedTasks() {
    setState(() {
      for (final task in _selectedTasks) {
        _project = _project.removeTask(task.id);
      }
      _selectedTasks.clear();
      _selectionMode = false;
    });
    // TODO: Сохранить изменения в репозитории
  }

  void _showAddTaskDialog() async {
    final result = await showDialog<Task>(
      context: context,
      builder: (context) => TaskEditDialog(
        projectId: _project.id,
        nestingLevel: 0,
      ),
    );

    if (result != null) {
      setState(() {
        _project = _project.addTask(result);
      });
      // TODO: Сохранить изменения в репозитории
    }
  }

  void _showAddSubtaskDialog(Task parentTask) async {
    final result = await showDialog<Task>(
      context: context,
      builder: (context) => TaskEditDialog(
        projectId: _project.id,
        parentTask: parentTask,
        nestingLevel: parentTask.nestingLevel + 1,
      ),
    );

    if (result != null) {
      setState(() {
        final updatedParentTask = parentTask.addSubtask(result);
        _project = _project.updateTask(parentTask.id, updatedParentTask);
      });
      // TODO: Сохранить изменения в репозитории
    }
  }

  void _showEditTaskDialog(Task task) async {
    final result = await showDialog<Task>(
      context: context,
      builder: (context) => TaskEditDialog(
        projectId: _project.id,
        task: task,
        nestingLevel: task.nestingLevel,
      ),
    );

    if (result != null) {
      setState(() {
        _project = _project.updateTask(task.id, result);
      });
      // TODO: Сохранить изменения в репозитории
    }
  }

  void _toggleTaskCompletion(Task task) {
    setState(() {
      final updatedTask = task.isCompleted
          ? _taskService.uncompleteTask(task)
          : _taskService.completeTask(task);

      _project = _project.updateTask(task.id, updatedTask);
    });
    // TODO: Сохранить изменения в репозитории
  }

  void _showTaskDetails(Task task) {
    // TODO: Реализовать экран деталей задачи
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Детали задачи: ${task.title}')),
    );
  }

  void _deleteTask(Task task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Удалить задачу?'),
        content: Text('Задача "${task.title}" будет удалена${task.hasSubtasks ? ' вместе со всеми подзадачами' : ''}.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _project = _project.removeTask(task.id);
              });
              // TODO: Сохранить изменения в репозитории
            },
            child: Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _handleMenuAction(String value) {
    switch (value) {
      case 'add_task':
        _showAddTaskDialog();
        break;
      case 'project_stats':
        _showProjectStats();
        break;
    }
  }

  void _showProjectStats() {
    final allTasks = _project.allTasks;
    final completedTasks = allTasks.where((t) => t.isCompleted).length;
    final tasksWithSubtasks = allTasks.where((t) => t.hasSubtasks).length;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Статистика проекта'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Всего задач: ${allTasks.length}'),
            Text('Выполнено: $completedTasks'),
            Text('С подзадачами: $tasksWithSubtasks'),
            Text('Прогресс: ${(_project.progress * 100).toStringAsFixed(1)}%'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  Color _getProgressColor(double progress) {
    if (progress < 0.3) return Colors.red;
    if (progress < 0.7) return Colors.orange;
    return Colors.green;
  }
}