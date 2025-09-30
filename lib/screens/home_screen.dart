// screens/home_screen.dart
import 'package:flutter/material.dart';
import '../models/project.dart';
import '../models/task.dart';
import '../models/task_type.dart';
import '../utils/storage_helper.dart';
import '../widgets/project_card.dart';
import '../widgets/add_project_dialog.dart';
import 'project_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Project> projects = [];
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

  void _createDemoProjects() {
    setState(() {
      projects = [
        Project(
          id: '1',
          name: 'Рабочие задачи',
          description: 'Задачи по работе',
          createdAt: DateTime.now(),
          tasks: [
            Task(
              id: '1',
              title: 'Создать отчет',
              description: 'Подготовить еженедельный отчет',
              isCompleted: false,
              type: TaskType.single,
            ),
          ],
        ),
        Project(
          id: '2',
          name: 'Личные дела',
          description: 'Персональные задачи',
          createdAt: DateTime.now(),
          tasks: [
            Task(
              id: '2',
              title: 'Купить продукты',
              description: 'Молоко, хлеб, фрукты',
              isCompleted: false,
              type: TaskType.single,
            ),
          ],
        ),
      ];
    });
    _saveProjects();
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
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        description: description,
        tasks: [],
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

  void _deleteProject(int index) {
    setState(() {
      projects.removeAt(index);
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
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Tracker 💾'),
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
        itemCount: projects.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () => _navigateToProjectDetail(index),
            child: ProjectCard(
              project: projects[index],
              projectIndex: index,
              onUpdate: (updatedProject) => _updateProject(index, updatedProject),
              onDelete: () => _deleteProject(index),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewProject,
        child: const Icon(Icons.add),
      ),
    );
  }
}