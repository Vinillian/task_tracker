// screens/project_detail_screen.dart
import 'package:flutter/material.dart';
import '../models/project.dart';
import '../models/task.dart';
import '../models/task_type.dart';
import '../widgets/expandable_task_card.dart';
import '../widgets/add_task_dialog.dart';
import '../widgets/edit_dialogs.dart';

class ProjectDetailScreen extends StatefulWidget {
  final Project project;
  final int projectIndex;
  final Function(Project) onProjectUpdated;

  const ProjectDetailScreen({
    super.key,
    required this.project,
    required this.projectIndex,
    required this.onProjectUpdated,
  });

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  late Project _project;

  @override
  void initState() {
    super.initState();
    _project = widget.project;
  }

  void _addTask() {
    showDialog(
      context: context,
      builder: (context) => AddTaskDialog(
        onTaskCreated: (String title, String description, TaskType type, int steps) {
          _createTask(title, description, type, steps);
        },
      ),
    );
  }

  void _createTask(String title, String description, TaskType type, int totalSteps) {
    setState(() {
      final newTask = Task(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        description: description,
        isCompleted: false,
        type: type,
        totalSteps: totalSteps,
        completedSteps: 0,
      );

      _project = _project.copyWith(
        tasks: [..._project.tasks, newTask],
      );
    });

    widget.onProjectUpdated(_project);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Задача "$title" добавлена!'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _updateTaskWithSubTasks(int taskIndex, Task updatedTask) {
    setState(() {
      final updatedTasks = List<Task>.from(_project.tasks);
      updatedTasks[taskIndex] = updatedTask;
      _project = _project.copyWith(tasks: updatedTasks);
    });

    widget.onProjectUpdated(_project);
  }

  void _deleteTask(int taskIndex) {
    setState(() {
      final updatedTasks = List<Task>.from(_project.tasks)..removeAt(taskIndex);
      _project = _project.copyWith(tasks: updatedTasks);
    });

    widget.onProjectUpdated(_project);
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
    return Card(
      margin: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        // ❌ УБИРАЕМ фиксированную высоту 120 - она слишком маленькая
        // height: 120,
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
                  child: Icon(Icons.folder, color: Colors.blue.shade600, size: 24),
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
                // ✅ УБИРАЕМ maxLines: 1 - пусть описание занимает столько строк, сколько нужно
                // maxLines: 1,
                // overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
            ],
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: _project.progress,
                    backgroundColor: Colors.grey.shade200,
                    color: _project.progress == 1.0 ? Colors.green : Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${(_project.progress * 100).toInt()}%',
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
                  '${_project.completedTasks}/${_project.totalTasks} задач выполнено',
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
    if (_project.tasks.isEmpty) {
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
        itemCount: _project.tasks.length,
        itemBuilder: (context, index) {
          return ExpandableTaskCard(
            task: _project.tasks[index],
            taskIndex: index,
            onTaskUpdated: (updatedTask) => _updateTaskWithSubTasks(index, updatedTask),
            onTaskDeleted: () => _deleteTask(index),
            level: 0,
          );
        },
      ),
    );
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