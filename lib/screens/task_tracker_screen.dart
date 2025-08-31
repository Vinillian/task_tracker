import 'package:flutter/material.dart';
import '../models/user.dart';
import '../models/project.dart';
import '../models/task.dart';
import '../models/subtask.dart';
import '../models/progress_history.dart';
import '../services/storage_service.dart';
import '../widgets/statistics_widgets.dart';
import '../widgets/task_widgets.dart';
import '../widgets/project_widgets.dart';

class TaskTrackerScreen extends StatefulWidget {
  const TaskTrackerScreen({super.key});

  @override
  State<TaskTrackerScreen> createState() => _TaskTrackerScreenState();
}

class _TaskTrackerScreenState extends State<TaskTrackerScreen>
    with SingleTickerProviderStateMixin {
  List<User> users = [];
  User? currentUser;
  final StorageService _storageService = StorageService();

  late TabController _tabController;

  final TextEditingController _userController = TextEditingController();
  final TextEditingController _projectController = TextEditingController();

  final Map<String, TextEditingController> _taskNameControllers = {};
  final Map<String, TextEditingController> _taskStepsControllers = {};
  final Map<String, TextEditingController> _subtaskNameControllers = {};
  final Map<String, TextEditingController> _subtaskStepsControllers = {};

  bool _showUserInput = false;
  bool _showProjectInput = false;
  final Map<int, bool> _showTaskInput = {};
  final Map<String, bool> _showSubtaskInput = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _userController.dispose();
    _projectController.dispose();

    for (final controller in _taskNameControllers.values) {
      controller.dispose();
    }
    for (final controller in _taskStepsControllers.values) {
      controller.dispose();
    }
    for (final controller in _subtaskNameControllers.values) {
      controller.dispose();
    }
    for (final controller in _subtaskStepsControllers.values) {
      controller.dispose();
    }

    super.dispose();
  }

  Future<void> _loadData() async {
    final loadedUsers = await _storageService.loadData();
    setState(() {
      users = loadedUsers;
      if (users.isNotEmpty) {
        currentUser = users[0];
      }
    });
  }

  Future<void> _saveData() async {
    await _storageService.saveData(users);
  }

  void _addProgressHistory(String itemName, int stepsAdded, String itemType) {
    if (currentUser == null) return;

    final now = DateTime.now();
    final history = ProgressHistory(
      date: now,
      itemName: itemName,
      stepsAdded: stepsAdded,
      itemType: itemType,
    );

    setState(() {
      currentUser!.progressHistory.add(history);
      _saveData();
    });
  }

  TextEditingController _getTaskNameController(int projectIndex) {
    final key = 'p$projectIndex';
    if (!_taskNameControllers.containsKey(key)) {
      _taskNameControllers[key] = TextEditingController();
      _taskStepsControllers[key] = TextEditingController();
    }
    return _taskNameControllers[key]!;
  }

  TextEditingController _getTaskStepsController(int projectIndex) {
    final key = 'p$projectIndex';
    if (!_taskStepsControllers.containsKey(key)) {
      _taskNameControllers[key] = TextEditingController();
      _taskStepsControllers[key] = TextEditingController();
    }
    return _taskStepsControllers[key]!;
  }

  TextEditingController _getSubtaskNameController(int projectIndex, int taskIndex) {
    final key = 'p${projectIndex}t$taskIndex';
    if (!_subtaskNameControllers.containsKey(key)) {
      _subtaskNameControllers[key] = TextEditingController();
      _subtaskStepsControllers[key] = TextEditingController();
    }
    return _subtaskNameControllers[key]!;
  }

  TextEditingController _getSubtaskStepsController(int projectIndex, int taskIndex) {
    final key = 'p${projectIndex}t$taskIndex';
    if (!_subtaskStepsControllers.containsKey(key)) {
      _subtaskNameControllers[key] = TextEditingController();
      _subtaskStepsControllers[key] = TextEditingController();
    }
    return _subtaskStepsControllers[key]!;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📊 Трекер задач с подзадачами'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.list), text: 'Задачи'),
            Tab(icon: Icon(Icons.bar_chart), text: 'Статистика'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTasksTab(),
          StatisticsWidgets.buildStatisticsTab(currentUser),
        ],
      ),
    );
  }

  Widget _buildTasksTab() {
    return TaskWidgets.buildTasksTab(
      users: users,
      currentUser: currentUser,
      showUserInput: _showUserInput,
      userController: _userController,
      projectController: _projectController,
      showProjectInput: _showProjectInput,
      showTaskInput: _showTaskInput,
      showSubtaskInput: _showSubtaskInput,
      onUserChanged: (user) => setState(() => currentUser = user),
      onShowUserInputChanged: (value) => setState(() => _showUserInput = value),
      onShowProjectInputChanged: (value) => setState(() => _showProjectInput = value),
      onShowTaskInputChanged: (index, value) => setState(() => _showTaskInput[index] = value),
      onShowSubtaskInputChanged: (key, value) => setState(() => _showSubtaskInput[key] = value),
      onAddUser: _addUser,
      onAddProject: _addProject,
      getTaskNameController: _getTaskNameController,
      getTaskStepsController: _getTaskStepsController,
      getSubtaskNameController: _getSubtaskNameController,
      getSubtaskStepsController: _getSubtaskStepsController,
      onAddTask: _addTask,
      onAddSubtask: _addSubtask,
      onAddIncrementalProgress: _addIncrementalProgress,
    );
  }

  void _addUser() {
    if (_userController.text.isNotEmpty) {
      setState(() {
        users.add(User(name: _userController.text, projects: [], progressHistory: []));
        currentUser = users.last;
        _userController.clear();
        _showUserInput = false;
        _saveData();
      });
    }
  }

  void _addProject() {
    if (currentUser == null) return;

    if (_projectController.text.isNotEmpty) {
      setState(() {
        currentUser!.projects.add(Project(name: _projectController.text, tasks: []));
        _projectController.clear();
        _showProjectInput = false;
        _saveData();
      });
    }
  }

  void _addTask(int projectIndex) {
    if (currentUser == null) return;

    final taskKey = 'p$projectIndex';
    final nameController = _taskNameControllers[taskKey];
    final stepsController = _taskStepsControllers[taskKey];

    if (nameController != null && nameController.text.isNotEmpty) {
      final steps = int.tryParse(stepsController?.text ?? '1') ?? 1;
      setState(() {
        currentUser!.projects[projectIndex].tasks.add(
          Task(name: nameController.text, totalSteps: steps, completedSteps: 0, subtasks: []),
        );
        nameController.clear();
        stepsController?.clear();
        _showTaskInput[projectIndex] = false;
        _saveData();
      });
    }
  }

  void _addSubtask(int projectIndex, int taskIndex) {
    if (currentUser == null) return;

    final subtaskKey = 'p${projectIndex}t$taskIndex';
    final nameController = _subtaskNameControllers[subtaskKey];
    final stepsController = _subtaskStepsControllers[subtaskKey];

    if (nameController != null && nameController.text.isNotEmpty) {
      final steps = int.tryParse(stepsController?.text ?? '1') ?? 1;
      setState(() {
        currentUser!.projects[projectIndex].tasks[taskIndex].subtasks.add(
          Subtask(name: nameController.text, totalSteps: steps, completedSteps: 0),
        );
        nameController.clear();
        stepsController?.clear();
        _showSubtaskInput[subtaskKey] = false;
        _saveData();
      });
    }
  }

  void _updateProgress(int projectIndex, int taskIndex, int subtaskIndex, int completedSteps) {
    setState(() {
      if (subtaskIndex >= 0) {
        final subtask = currentUser!.projects[projectIndex].tasks[taskIndex].subtasks[subtaskIndex];
        subtask.completedSteps = completedSteps.clamp(0, subtask.totalSteps);
      } else {
        final task = currentUser!.projects[projectIndex].tasks[taskIndex];
        task.completedSteps = completedSteps.clamp(0, task.totalSteps);
      }
      _saveData();
    });
  }

  Future<void> _addIncrementalProgress(int projectIndex, int taskIndex, int subtaskIndex) async {
    if (currentUser == null) return;

    final isSubtask = subtaskIndex >= 0;
    final task = currentUser!.projects[projectIndex].tasks[taskIndex];
    final subtask = isSubtask ? task.subtasks[subtaskIndex] : null;

    final currentSteps = isSubtask ? subtask!.completedSteps : task.completedSteps;
    final maxSteps = isSubtask ? subtask!.totalSteps : task.totalSteps;
    final remainingSteps = maxSteps - currentSteps;

    final controller = TextEditingController();

    final result = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isSubtask ? 'Добавить прогресс подзадачи' : 'Добавить прогресс задачи'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isSubtask ? subtask!.name : task.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Текущий прогресс: $currentSteps/$maxSteps'),
            Text(
              'Осталось: $remainingSteps шагов',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Сколько шагов выполнили?',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 0),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              final newSteps = int.tryParse(controller.text) ?? 0;
              Navigator.pop(context, newSteps);
            },
            child: const Text('Добавить'),
          ),
        ],
      ),
    );

    if (result != null && result > 0) {
      final newCompletedSteps = currentSteps + result;
      _updateProgress(projectIndex, taskIndex, subtaskIndex, newCompletedSteps);

      final itemName = isSubtask ? subtask!.name : task.name;
      final itemType = isSubtask ? 'subtask' : 'task';
      _addProgressHistory(itemName, result, itemType);
    }
  }
}