// screens/project_detail_screen.dart
import 'package:flutter/material.dart';

import '../models/project.dart';
import '../models/task.dart';
import '../models/task_type.dart';
import '../widgets/add_task_dialog.dart';
import '../widgets/edit_dialogs.dart';
import '../widgets/expandable_task_card.dart';
import '../services/task_service.dart';

class ProjectDetailScreen extends StatefulWidget {
  final Project project;
  final int projectIndex;
  final Function(Project) onProjectUpdated;
  final TaskService taskService; // ✅ ДОБАВЛЯЕМ

  const ProjectDetailScreen({
    super.key,
    required this.project,
    required this.projectIndex,
    required this.onProjectUpdated,
    required this.taskService, // ✅ ДОБАВЛЯЕМ
  });

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  late Project _project;
  bool _allExpanded = false;
  late TaskService _taskService; // ✅ ДОБАВЛЯЕМ

  @override
  void initState() {
    super.initState();
    _project = widget.project;
    _taskService = widget.taskService; // ✅ ИНИЦИАЛИЗИРУЕМ
  }

  void _toggleAllExpanded() {
    setState(() {
      _allExpanded = !_allExpanded;
    });
  }

  void _addTask() {
    showDialog(
      context: context,
      builder: (context) => AddTaskDialog(
        onTaskCreated: (String title, String description, TaskType type,
            int steps, String? parentId) {
          _createTask(title, description, type, steps, _project.id, parentId);
        },
        projectId: _project.id,
        parentId: null,
      ),
    );
  }

  void _createTask(String title, String description, TaskType type,
      int totalSteps, String projectId, String? parentId) {
    final newTask = Task(
      id: 'task_${DateTime.now().millisecondsSinceEpoch}',
      parentId: parentId, // ✅ Используем parentId
      projectId: projectId,
      title: title,
      description: description,
      isCompleted: false,
      type: type,
      totalSteps: totalSteps,
      completedSteps: 0,
    );

    _taskService.addTask(newTask);
    setState(() {});

    widget.onProjectUpdated(_project);

    // ✅ АВТОПРОКРУТКА К НОВОЙ ЗАДАЧЕ
    if (mounted) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          final scrollController = PrimaryScrollController.of(context);
          if (scrollController.hasClients) {
            scrollController.animateTo(
              scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        }
      });
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Задача "$title" добавлена!'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _editProject() {
    showDialog(
      context: context,
      builder: (context) => EditProjectDialog(
        project: _project,
        onProjectUpdated: (String name, String description) {
          setState(() {
            _project = _project.copyWith(
              name: name,
              description: description,
            );
          });
          widget.onProjectUpdated(_project);
        },
      ),
    );
  }

  Widget _buildHeader() {
    final progress = _taskService.getProjectProgress(_project.id);
    final totalTasks = _taskService.getProjectTotalTasks(_project.id);
    final completedTasks = _taskService.getProjectCompletedTasks(_project.id);

    return Card(
      margin: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child:
                      Icon(Icons.folder, color: Colors.blue.shade600, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _project.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    _allExpanded ? Icons.unfold_less : Icons.unfold_more,
                    color: Colors.blue,
                  ),
                  onPressed: _toggleAllExpanded,
                  tooltip: _allExpanded ? 'Свернуть все' : 'Развернуть все',
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.orange),
                  onPressed: _editProject,
                  tooltip: 'Редактировать проект',
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_project.description.isNotEmpty) ...[
              Text(
                _project.description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 8),
            ],
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.grey.shade200,
                    color: progress == 1.0 ? Colors.green : Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${(progress * 100).toInt()}%',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$completedTasks/$totalTasks задач выполнено',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  'Создан: ${_project.createdAt.day}.${_project.createdAt.month}.${_project.createdAt.year}',
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
    );
  }

  Widget _buildTasksList() {
    final rootTasks = _taskService
        .getProjectTasks(_project.id)
        .where((task) => task.parentId == null)
        .toList();

    if (rootTasks.isEmpty) {
      return const Expanded(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.task, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Нет задач',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
              SizedBox(height: 8),
              Text(
                'Добавьте первую задачу',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Expanded(
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: rootTasks.length,
        itemBuilder: (context, index) {
          return ExpandableTaskCard(
            task: rootTasks[index],
            taskIndex: index,
            onTaskUpdated: (updatedTask) => _updateTask(updatedTask),
            onTaskDeleted: () => _deleteTask(rootTasks[index].id),
            taskService: _taskService,
            level: 0,
            forceExpanded: _allExpanded,
          );
        },
      ),
    );
  }

  void _updateTask(Task updatedTask) {
    _taskService.updateTask(updatedTask);
    setState(() {});
    widget.onProjectUpdated(_project);
  }

  void _deleteTask(String taskId) {
    _taskService.removeTask(taskId);
    setState(() {});
    widget.onProjectUpdated(_project);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_project.name),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_task),
            onPressed: _addTask,
            tooltip: 'Добавить задачу',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildHeader(),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  'Задачи проекта',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _buildTasksList(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addTask,
        child: const Icon(Icons.add),
      ),
    );
  }
}
