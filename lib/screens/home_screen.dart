// screens/home_screen.dart
import 'package:flutter/material.dart';
import '../models/project.dart';
import '../services/task_service.dart';
import '../utils/storage_helper.dart';
import '../widgets/add_project_dialog.dart';
import 'project_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Project> projects = [];
  final TaskService _taskService = TaskService(); // ✅ ДОБАВЛЯЕМ TaskService
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
      final savedProjects = await StorageHelper.loadProjects();

      if (savedProjects.isNotEmpty) {
        setState(() {
          projects = savedProjects.map((projectData) {
            return Project.fromJson(projectData);
          }).toList();
        });
        print('✅ Загружено ${projects.length} проектов');

        // ✅ ЗАГРУЗКА ДЕМО-ЗАДАЧ для тестирования
        _loadDemoTasks();
      } else {
        _createDemoProjects();
      }
    } catch (e) {
      print('❌ Ошибка загрузки: $e');
      _createDemoProjects();
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _loadDemoTasks() {
    // ✅ ЗАГРУЗКА ДЕМО-ЗАДАЧ для всех проектов
    for (final project in projects) {
      _taskService.loadDemoTasks(project.id);
    }
    print('✅ Загружены демо-задачи для ${projects.length} проектов');
  }

  void _createDemoProjects() {
    setState(() {
      projects = [
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
    });
    _saveProjects();
    _loadDemoTasks(); // ✅ ДОБАВЛЯЕМ задачи после создания проектов
  }

  Future<void> _saveProjects() async {
    final projectsData = projects.map((project) => project.toJson()).toList();
    await StorageHelper.saveProjects(projectsData);
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
    setState(() {
      final newProject = Project(
        id: 'project_${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        description: description,
        createdAt: DateTime.now(),
      );

      projects.add(newProject);
    });

    _saveProjects();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Проект "$name" создан!'),
        backgroundColor: Colors.green,
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
              setState(() {
                projects.clear();
              });
              StorageHelper.clearData();
              // ✅ ОЧИСТКА всех задач
              _taskService.clearAllTasks();
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

  void _updateProject(int index, Project updatedProject) {
    setState(() {
      projects[index] = updatedProject;
    });
    _saveProjects();
  }

  void _navigateToProjectDetail(int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProjectDetailScreen(
          project: projects[index],
          projectIndex: index,
          onProjectUpdated: (updatedProject) => _updateProject(index, updatedProject),
          taskService: _taskService, // ✅ ПЕРЕДАЕМ TaskService
        ),
      ),
    );
  }

  // ✅ ОБНОВЛЯЕМ отображение прогресса проекта
  Widget _buildProjectCard(int index) {
    final project = projects[index];
    final progress = _taskService.getProjectProgress(project.id);
    final totalTasks = _taskService.getProjectTotalTasks(project.id);
    final completedTasks = _taskService.getProjectCompletedTasks(project.id);

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
              // Иконка проекта
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

              // Информация о проекте
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

              // Прогресс и счетчики
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

              // Прогресс-бар
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Tracker 💾 (Flat Structure)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addNewProject,
            tooltip: 'Создать проект',
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