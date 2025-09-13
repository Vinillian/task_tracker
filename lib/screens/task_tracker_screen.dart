import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/app_user.dart';
import '../models/project.dart';
import '../models/progress_history.dart';
import '../widgets/statistics_widgets.dart';
import 'project_list_screen.dart';
import 'drawer_screen.dart';

class TaskTrackerScreen extends StatefulWidget {
  const TaskTrackerScreen({super.key});

  @override
  State<TaskTrackerScreen> createState() => _TaskTrackerScreenState();
}

class _TaskTrackerScreenState extends State<TaskTrackerScreen>
    with SingleTickerProviderStateMixin {
  AppUser? currentUser;
  final FirestoreService _firestoreService = FirestoreService();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUserData();
  }

  void _loadUserData() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentAuthUser = authService.currentUser;

    if (currentAuthUser != null) {
      try {
        final userDoc = await _firestoreService.getUserDocument(currentAuthUser.uid);
        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;
          setState(() {
            currentUser = AppUser.fromFirestore(userData);
          });
        } else {
          // Создаем нового пользователя с email как username
          setState(() {
            currentUser = AppUser(
              username: currentAuthUser.email?.split('@').first ?? 'User',
              email: currentAuthUser.email ?? '',
              projects: [],
              progressHistory: [],
            );
          });
          await _firestoreService.saveUser(currentUser!, currentAuthUser.uid);
        }
      } catch (e) {
        print('Ошибка загрузки пользователя: $e');
      }
    }
  }

  void _addProgressHistory(String itemName, int stepsAdded, String itemType) {
    if (currentUser == null) return;

    final now = DateTime.now();
    final history = {
      'date': now.toIso8601String(),
      'itemName': itemName,
      'stepsAdded': stepsAdded,
      'itemType': itemType,
    };

    setState(() {
      currentUser!.progressHistory.add(history);
    });

    final authService = Provider.of<AuthService>(context, listen: false);
    final currentAuthUser = authService.currentUser;
    if (currentAuthUser != null) {
      _firestoreService.saveUser(currentUser!, currentAuthUser.uid);
    }
  }

  void _addProject() {
    if (currentUser == null) return;

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
                  });

                  final authService = Provider.of<AuthService>(context, listen: false);
                  final currentAuthUser = authService.currentUser;
                  if (currentAuthUser != null) {
                    _firestoreService.saveUser(currentUser!, currentAuthUser.uid);
                  }

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
    });

    final authService = Provider.of<AuthService>(context, listen: false);
    final currentAuthUser = authService.currentUser;
    if (currentAuthUser != null) {
      _firestoreService.saveUser(currentUser!, currentAuthUser.uid);
    }
  }

  void _onProjectUpdated(Project updatedProject) {
    if (currentUser == null) return;

    final index = currentUser!.projects.indexWhere((p) => p.name == updatedProject.name);
    if (index != -1) {
      setState(() {
        currentUser!.projects[index] = updatedProject;
      });

      final authService = Provider.of<AuthService>(context, listen: false);
      final currentAuthUser = authService.currentUser;
      if (currentAuthUser != null) {
        _firestoreService.saveUser(currentUser!, currentAuthUser.uid);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(currentUser?.username ?? authService.currentUser?.email ?? '📊 Трекер задач'),
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

      drawer: DrawerScreen(
        userEmail: authService.currentUser?.email,
        currentUser: currentUser,  // ← ДОБАВИТЬ
      ),

      body: TabBarView(
        controller: _tabController,
        children: [
          currentUser != null
              ? ProjectListScreen(
            currentUser: currentUser,
            onUserChanged: (user) {
              setState(() => currentUser = user);
            },
            onAddProject: _addProject,
            onDeleteProject: _deleteProject,
            onAddProgressHistory: _addProgressHistory,
          )
              : const Center(child: CircularProgressIndicator()),

          currentUser != null
              ? StatisticsWidgets.buildStatisticsTab(context, currentUser)
              : const Center(child: CircularProgressIndicator()),
        ],
      ),

      floatingActionButton: currentUser != null
          ? FloatingActionButton(
        onPressed: _addProject,
        child: const Icon(Icons.add),
      )
          : null,
    );
  }
}