// project_list_screen.dart
import 'package:flutter/material.dart';
import '../models/user.dart';
import '../models/project.dart';
import '../services/storage_service.dart'; // ДОБАВЬТЕ этот импорт
import 'project_detail_screen.dart';
import 'drawer_screen.dart';

class ProjectListScreen extends StatefulWidget {
  final User? currentUser;
  final Function(User?) onUserChanged;
  final Function() onAddProject;
  final Function(Project) onDeleteProject;
  final Function(String, int, String) onAddProgressHistory;
  final StorageService storageService;
  final List<User> users;
  final Function(List<User>) onDataImported;

  const ProjectListScreen({
    super.key,
    required this.currentUser,
    required this.onUserChanged,
    required this.onAddProject,
    required this.onDeleteProject,
    required this.onAddProgressHistory,
    required this.storageService,
    required this.users,
    required this.onDataImported,
  });

  @override
  State<ProjectListScreen> createState() => _ProjectListScreenState();
}

class _ProjectListScreenState extends State<ProjectListScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void _openProject(Project project) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProjectDetailScreen(
          project: project,
          onDeleteProject: () => widget.onDeleteProject(project),
          onAddProgressHistory: widget.onAddProgressHistory,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text('Мои проекты'),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => _scaffoldKey.currentState!.openDrawer(),
        ),
      ),
      drawer: DrawerScreen(
        currentUser: widget.currentUser, // ИСПРАВЛЕНО: добавлено widget.
        onUserChanged: widget.onUserChanged, // ИСПРАВЛЕНО
        onAddProject: widget.onAddProject, // ИСПРАВЛЕНО
        storageService: widget.storageService, // ИСПРАВЛЕНО
        users: widget.users, // ИСПРАВЛЕНО
        onDataImported: widget.onDataImported, // ИСПРАВЛЕНО
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: widget.onAddProject,
        child: const Icon(Icons.add),
      ),
      body: widget.currentUser == null
          ? const Center(child: Text('Добавьте первый проект'))
          : ListView.builder(
        itemCount: widget.currentUser!.projects.length,
        itemBuilder: (context, index) {
          final project = widget.currentUser!.projects[index];
          final totalSteps = project.tasks.fold<int>(0, (sum, task) => sum + task.totalSteps);
          final completedSteps = project.tasks.fold<int>(0, (sum, task) => sum + task.completedSteps);
          final progress = totalSteps > 0 ? completedSteps / totalSteps : 0;

          return ListTile(
            leading: CircleAvatar(
              backgroundColor: _getProjectProgressColor(progress.toDouble()),
              child: Text(
                '${(progress * 100).toStringAsFixed(0)}%',
                style: const TextStyle(fontSize: 10, color: Colors.white),
              ),
            ),
            title: Text(project.name),
            subtitle: Text('$completedSteps/$totalSteps шагов • ${project.tasks.length} задач'),
            onTap: () => _openProject(project),
          );
        },
      ),
    );
  }

  Color _getProjectProgressColor(double progress) {
    if (progress >= 1.0) return Colors.green;
    if (progress >= 0.7) return Colors.orange;
    if (progress >= 0.3) return Colors.yellow;
    return Colors.red;
  }
}