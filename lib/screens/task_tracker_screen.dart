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
  String? _saveMessage;

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
        print('🔍 Загрузка данных пользователя UID: ${currentAuthUser.uid}');
        final userDoc = await _firestoreService.getUserDocument(currentAuthUser.uid);

        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;
          setState(() {
            currentUser = AppUser.fromFirestore(userData);
          });

          if (currentUser?.projects.isEmpty == true) {
            print('ℹ️ Пользователь существует, но проекты отсутствуют');
          } else {
            print('✅ Загружено ${currentUser?.projects.length} проектов');
          }
        } else {
          // Создаем нового пользователя
          setState(() {
            currentUser = AppUser(
              username: currentAuthUser.email?.split('@').first ?? 'User',
              email: currentAuthUser.email ?? '',
              projects: [],
              progressHistory: [],
            );
          });
          await _firestoreService.saveUser(currentUser!, currentAuthUser.uid);
          print('✅ Создан новый пользователь: ${currentUser!.username}');
        }
      } catch (e) {
        print('❌ Ошибка загрузки пользователя: $e');
      }
    }
  }

  // Метод для сохранения текущего пользователя в Firestore
  void _saveCurrentUser() {
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentAuthUser = authService.currentUser;
    if (currentAuthUser != null && currentUser != null) {
      setState(() {
        _saveMessage = 'Сохранение...';
      });

      print('💾 Сохранение пользователя: ${currentUser!.username}');
      print('📊 Проектов: ${currentUser!.projects.length}');
      print('📈 Записей истории: ${currentUser!.progressHistory.length}');

      // Выводим детальную информацию о проектах
      for (var i = 0; i < currentUser!.projects.length; i++) {
        print('   Проект $i: ${currentUser!.projects[i].name}');
        print('   Задач: ${currentUser!.projects[i].tasks.length}');
      }

      _firestoreService.saveUser(currentUser!, currentAuthUser.uid).then((_) {
        setState(() {
          _saveMessage = 'Данные сохранены ✅';
        });
        Future.delayed(const Duration(seconds: 2), () {
          setState(() {
            _saveMessage = null;
          });
        });
        print('✅ Данные успешно сохранены в Firestore');
      }).catchError((error) {
        setState(() {
          _saveMessage = 'Ошибка сохранения: $error';
        });
        print('❌ Ошибка сохранения: $error');
      });
    }
  }

  void _addProgressHistory(String itemName, int stepsAdded, String itemType) {
    if (currentUser == null) return;

    final history = ProgressHistory(
      date: DateTime.now(),
      itemName: itemName,
      stepsAdded: stepsAdded,
      itemType: itemType,
    );

    setState(() {
      currentUser!.progressHistory.add(history);
    });

    _saveCurrentUser();
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
            decoration: const InputDecoration(
              hintText: 'Название проекта',
              border: OutlineInputBorder(),
            ),
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
                  _saveCurrentUser();
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
    _saveCurrentUser();
  }

  void _onProjectUpdated(Project updatedProject) {
    if (currentUser == null) return;

    final index = currentUser!.projects.indexWhere((p) => p.name == updatedProject.name);
    if (index != -1) {
      setState(() {
        currentUser!.projects[index] = updatedProject;
      });
      _saveCurrentUser();
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
        currentUser: currentUser,
      ),
      body: Column(
        children: [
          if (_saveMessage != null)
            Container(
              padding: const EdgeInsets.all(8),
              color: _saveMessage!.contains('Ошибка') ? Colors.red[100] : Colors.green[100],
              child: Row(
                children: [
                  Icon(
                    _saveMessage!.contains('Ошибка') ? Icons.error : Icons.check_circle,
                    color: _saveMessage!.contains('Ошибка') ? Colors.red : Colors.green,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _saveMessage!,
                      style: TextStyle(
                        color: _saveMessage!.contains('Ошибка') ? Colors.red : Colors.green,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                currentUser != null
                    ? ProjectListScreen(
                  currentUser: currentUser,
                  onUserChanged: (user) {
                    setState(() => currentUser = user);
                    _saveCurrentUser();
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
          ),
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

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}