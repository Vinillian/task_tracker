import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/project_provider.dart';
import '../providers/task_provider.dart';
import '../utils/logger.dart';
import '../widgets/add_project_dialog.dart';
import 'project_detail_screen.dart';
import '../models/project.dart';

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
      Logger.success('Проекты загружены через провайдер');
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

    // Добавляем демо-проекты через провайдер
    for (final project in demoProjects) {
      ref.read(projectsProvider.notifier).addProject(project);
      // УБРАЛИ автоматическое создание демо-задач
      // ref.read(tasksProvider.notifier).loadDemoTasks(project.id);
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

    // УБРАЛИ автоматическое создание демо-задач
    // ref.read(tasksProvider.notifier).loadDemoTasks(newProject.id);

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

    // Добавляем демо-задачи в первый проект
    ref.read(tasksProvider.notifier).loadDemoTasks(projects.first.id);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Демо-задачи добавлены в проект "${projects.first.name}"!'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _clearAllData() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Очистить все данные?'),
        content: const Text('Это действие удалит все проекты и задачи. Вы уверены?'),
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
            ref.read(projectsProvider.notifier).updateProject(index, updatedProject);
          },
          taskService: taskService,
        ),
      ),
    );
  }

  Widget _buildProjectCard(int index) {
    final projects = ref.watch(projectsProvider);
    final taskService = ref.read(taskServiceProvider);

    final project = projects[index];
    final progress = taskService.getProjectProgress(project.id);
    final totalTasks = taskService.getProjectTotalTasks(project.id);
    final completedTasks = taskService.getProjectCompletedTasks(project.id);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: () => _navigateToProjectDetail(index),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          height: 80,
          child: Row(
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      project.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (project.description.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        project.description,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${(progress * 100).toInt()}%',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$completedTasks/$totalTasks',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 60,
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey.shade200,
                  color: progress == 1.0 ? Colors.green : Colors.blue,
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
          // ДОБАВЬ эту кнопку
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
        padding: const EdgeInsets.symmetric(vertical: 8),
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