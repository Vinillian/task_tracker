import 'package:flutter/material.dart';
import '../models/user.dart';
import '../models/project.dart';
import '../models/task.dart';
import '../models/subtask.dart';
import '../models/progress_history.dart';
import '../services/storage_service.dart';
import '../widgets/statistics_widgets.dart';
import '../widgets/task_widgets.dart';
import 'project_list_screen.dart';

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
    _loadData().then((_) {
      if (currentUser == null) {
        setState(() {
          users.add(User(name: 'Новый пользователь', projects: [], progressHistory: []));
          currentUser = users[0];
          _saveData();
        });
      }
    });
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
    print('Loading data...');
    final loadedUsers = await _storageService.loadData();
    print('Loaded ${loadedUsers.length} users');

    setState(() {
      users = loadedUsers;
      if (users.isNotEmpty) {
        currentUser = users[0];
        print('Current user set to: ${currentUser?.name}');
      } else {
        print('No users found, creating default user');
        users.add(User(name: 'Default User', projects: [], progressHistory: []));
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
    final date = DateTime(now.year, now.month, now.day);

    print('Adding progress: $itemName, $stepsAdded steps, $date');

    final history = ProgressHistory(
      date: date,
      itemName: itemName,
      stepsAdded: stepsAdded,
      itemType: itemType,
    );

    setState(() {
      currentUser!.progressHistory.add(history);
      _saveData();
    });
  }

  void _handleAddProject() {
    print('Add project button pressed');
    _addProject();
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

  void _handleDataImported(List<User> importedUsers) {
    setState(() {
      users = importedUsers;
      currentUser = users.isNotEmpty ? users[0] : null;
    });
    _saveData();
  }

  @override
  Widget build(BuildContext context) {
    print('Building TaskTrackerScreen, currentUser: ${currentUser?.name}');

    return Scaffold(
      appBar: AppBar(
        title: const Text('📊 Трекер задач'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.list), text: 'Проекты'),
            Tab(icon: Icon(Icons.bar_chart), text: 'Статистика'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          ProjectListScreen(
            currentUser: currentUser,
            onUserChanged: (user) {
              print('User changed to: ${user?.name}');
              setState(() => currentUser = user);
            },
            onAddProject: _addProject,
            onDeleteProject: _deleteProject,
            onAddProgressHistory: _addProgressHistory,
            storageService: _storageService,
            users: users,
            onDataImported: _handleDataImported,
          ),
          StatisticsWidgets.buildStatisticsTab(currentUser),
        ],
      ),
    );
  }

  void _addUser() {
    if (_userController.text.isNotEmpty) {
      setState(() {
        final newUser = User(name: _userController.text, projects: [], progressHistory: []);
        users.add(newUser);
        currentUser = newUser;
        _userController.clear();
        _showUserInput = false;
        _saveData();
        print('User created and set as current: ${newUser.name}');
      });
    }
  }

  void _addProject() {
    print('_addProject called');
    if (currentUser == null) {
      print("Ошибка: currentUser is null!");
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Новый проект'),
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
                    currentUser!.projects.add(Project(
                      name: controller.text,
                      tasks: [],
                    ));
                    _saveData();
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('Создать'),
            ),
          ],
        );
      },
    );
  }

  void _deleteProject(Project project) {
    setState(() {
      currentUser?.projects.remove(project);
      _saveData();
    });
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