import 'package:flutter/material.dart';
import '../models/user.dart';
import '../models/project.dart';
import '../models/task.dart';
import '../models/subtask.dart';
import '../models/progress_history.dart';
import '../widgets/statistics_widgets.dart';
import 'project_list_screen.dart';
import '../services/firestore_service.dart';
import 'drawer_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TaskTrackerScreen extends StatefulWidget {
  const TaskTrackerScreen({super.key});

  @override
  State<TaskTrackerScreen> createState() => _TaskTrackerScreenState();
}

class _TaskTrackerScreenState extends State<TaskTrackerScreen>
    with SingleTickerProviderStateMixin {
  List<User> users = [];
  User? currentUser;
  final FirestoreService _firestoreService = FirestoreService();

  late TabController _tabController;


  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _setupRealTimeListener();
  }

  void _setupRealTimeListener() {
    _firestoreService.usersStream().listen((usersList) {
      if (mounted) {
        setState(() {
          users = usersList;
          if (users.isNotEmpty && currentUser == null) {
            currentUser = users.first;
            // Автоматически мигрируем при первом запуске
            _saveData();
          }
        });
      }
    });
  }

  Future<void> _saveData() async {
    for (final user in users) {
      await _firestoreService.saveUser(user);
    }
  }

  void _addProgressHistory(String itemName, int stepsAdded, String itemType) {
    if (currentUser == null) return;

    final now = DateTime.now();

    // Сохраняем как Map для совместимости с Firestore
    final history = {
      'date': now.toIso8601String(), // Сохраняем как строку
      'itemName': itemName,
      'stepsAdded': stepsAdded,
      'itemType': itemType,
    };

    setState(() {
      currentUser!.progressHistory.add(history);
      _saveData();
    });

    print('Progress history added: $history');
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


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(currentUser?.name ?? '📊 Трекер задач'),
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
        currentUser: currentUser,
        onUserSelected: (user) {
          setState(() => currentUser = user);
        },
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          ProjectListScreen(
            currentUser: currentUser,
            onUserChanged: (user) {
              setState(() => currentUser = user);
            },
            onAddProject: _addProject,
            onDeleteProject: _deleteProject,
            onAddProgressHistory: _addProgressHistory,
          ),
          StatisticsWidgets.buildStatisticsTab(context, currentUser),
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