import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/project_provider.dart';
import '../providers/task_provider.dart';
import '../utils/logger.dart';
import '../widgets/add_project_dialog.dart';
import 'project_detail_screen.dart';
import '../models/project.dart';
import '../models/task.dart';
import '../models/task_type.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await ref.read(projectsProvider.notifier).loadProjects();

      // ✅ ДОБАВИТЬ: Загружаем задачи из Hive
      await ref.read(tasksProvider.notifier).loadTasks();

      Logger.success('Проекты и задачи загружены через провайдер');
    } catch (e) {
      Logger.error('Ошибка загрузки проектов', e);
      _createDemoProjects();
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _createDemoProjects() {
    final demoProjects = [
      Project(
        id: 'project_1',
        name: 'Рабочие задачи',
        description: 'Задачи по работе',
        createdAt: DateTime.now(),
      ),
      Project(
        id: 'project_2',
        name: 'Личные дела',
        description: 'Персональные задачи',
        createdAt: DateTime.now(),
      ),
    ];

    for (final project in demoProjects) {
      ref.read(projectsProvider.notifier).addProject(project);
    }
  }

  void _addNewProject() {
    showDialog(
      context: context,
      builder: (context) => AddProjectDialog(
        onProjectCreated: (String name, String description) {
          _createProject(name, description);
        },
      ),
    );
  }

  void _createProject(String name, String description) {
    final newProject = Project(
      id: 'project_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      description: description,
      createdAt: DateTime.now(),
    );

    ref.read(projectsProvider.notifier).addProject(newProject);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Проект "$name" создан!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _addDemoTasks() {
    final projects = ref.read(projectsProvider);
    if (projects.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Сначала создайте проект!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    ref.read(tasksProvider.notifier).loadDemoTasks(projects.first.id);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text('Демо-задачи добавлены в проект "${projects.first.name}"!'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _createTestProjectWithTasks() {
    // Создаем тестовый проект
    final testProject = Project(
      id: 'test_project_${DateTime.now().millisecondsSinceEpoch}',
      name: '🧪 Тестовый проект',
      description: 'Проект с разнообразными демо-задачами',
      createdAt: DateTime.now(),
    );

    ref.read(projectsProvider.notifier).addProject(testProject);

    // Создаем разнообразные задачи
    _createDiverseTestTasks(testProject.id);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Тестовый проект "${testProject.name}" создан!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _createDiverseTestTasks(String projectId) {
    final taskNotifier = ref.read(tasksProvider.notifier);
    final now = DateTime.now();

    // 1. Одиночная задача с высоким приоритетом
    final singleTask = Task.create(
      title: 'Срочная задача',
      projectId: projectId,
      description: 'Задача с высоким приоритетом',
      priority: 2, // высокий
      dueDate: now.add(const Duration(days: 1)),
      color: Colors.red.value,
    );
    taskNotifier.addTask(singleTask);

    // 2. Пошаговая задача
    final stepTask = Task.create(
      title: 'Изучить Flutter',
      projectId: projectId,
      description: 'Пошаговое изучение Flutter',
      type: TaskType.stepByStep,
      totalSteps: 5,
      priority: 1, // средний
      color: Colors.blue.value,
    );
    taskNotifier.addTask(stepTask);

    // 3. Задача с подзадачами (родительская)
    final parentTask = Task.create(
      title: 'Подготовить отчет',
      projectId: projectId,
      description: 'Основная задача с подзадачами',
      priority: 1,
      color: Colors.green.value,
    );
    taskNotifier.addTask(parentTask);

    // 4. Подзадачи для родительской
    final subTask1 = Task.create(
      title: 'Собрать данные',
      projectId: projectId,
      parentId: parentTask.id,
      description: 'Первая подзадача',
    );
    taskNotifier.addTask(subTask1);

    final subTask2 = Task.create(
      title: 'Написать выводы',
      projectId: projectId,
      parentId: parentTask.id,
      description: 'Вторая подзадача',
    ).copyWith(isCompleted: true); // ✅ Исправлено
    taskNotifier.addTask(subTask2);

    // 5. Повторяющаяся задача
    final recurringTask = Task.create(
      title: 'Ежедневная встреча',
      projectId: projectId,
      description: 'Ежедневная standup встреча',
      isRecurring: true,
      dueDate:
          DateTime(now.year, now.month, now.day + 1, 10, 0), // завтра в 10:00
      color: Colors.orange.value,
    );
    taskNotifier.addTask(recurringTask);
  }

  void _clearAllData() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Очистить все данные?'),
        content:
            const Text('Это действие удалит все проекты и задачи. Вы уверены?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              ref.read(projectsProvider.notifier).clearAllProjects();
              ref.read(tasksProvider.notifier).clearAllTasks();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Все данные очищены'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            child: const Text('Очистить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _navigateToProjectDetail(int index) {
    final projects = ref.read(projectsProvider);
    final taskService = ref.read(taskServiceProvider);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProjectDetailScreen(
          project: projects[index],
          projectIndex: index,
          onProjectUpdated: (updatedProject) {
            ref
                .read(projectsProvider.notifier)
                .updateProject(index, updatedProject);
          },
          taskService: taskService,
        ),
      ),
    );
  }

  // ЗАМЕНИТЬ весь метод _buildProjectCard() на этот код:
  Widget _buildProjectCard(int index) {
    final projects = ref.watch(projectsProvider);
    final taskService = ref.read(taskServiceProvider);

    final project = projects[index];
    final progress = taskService.getProjectProgress(project.id);
    final totalTasks = taskService.getProjectTotalTasks(project.id);
    final completedTasks = taskService.getProjectCompletedTasks(project.id);

    return Card(
      margin: const EdgeInsets.all(16),
      child: InkWell(
        onTap: () => _navigateToProjectDetail(index),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Верхняя строка с иконкой и названием
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.folder,
                        color: Colors.blue.shade600, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      project.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              // Описание проекта
              if (project.description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  project.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],

              // Прогресс бар (ПОД названием и описанием)
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey.shade200,
                color: progress == 1.0 ? Colors.green : Colors.blue,
              ),
              const SizedBox(height: 8),

              // Процент выполнения и статистика
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${(progress * 100).toInt()}% выполнено',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '$completedTasks/$totalTasks задач',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),

              // Дата создания
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Создан: ${project.createdAt.day}.${project.createdAt.month}.${project.createdAt.year}',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final projects = ref.watch(projectsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Tracker 💾 (Riverpod)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addNewProject,
            tooltip: 'Создать проект',
          ),
          IconButton(
            icon: const Icon(Icons.play_arrow),
            onPressed: _addDemoTasks,
            tooltip: 'Добавить демо-задачи',
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: _clearAllData,
            tooltip: 'Очистить все данные',
          ),
          // В методе build класса _HomeScreenState, в AppBar actions ДОБАВИТЬ:
          IconButton(
            icon: const Icon(Icons.science),
            onPressed: () => Navigator.pushNamed(context, '/test-lab'),
            tooltip: 'Test Lab',
          ),
          IconButton(
            icon: const Icon(Icons.folder_special),
            onPressed: _createTestProjectWithTasks,
            tooltip: 'Создать тестовый проект с задачами',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : projects.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.folder_open, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'Нет проектов',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Нажмите + чтобы создать первый проект',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 8),
                  itemCount: projects.length,
                  itemBuilder: (context, index) {
                    return _buildProjectCard(index);
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewProject,
        child: const Icon(Icons.add),
      ),
    );
  }
}
