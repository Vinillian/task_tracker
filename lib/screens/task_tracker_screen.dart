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
import 'planning_calendar_screen.dart'; // ← Должен быть этот импорт
import '../repositories/local_repository.dart';
import '../models/task.dart';
import '../models/stage.dart';
import '../models/step.dart' as custom_step;
import '../services/completion_service.dart';
import 'calendar_screen.dart';

class TaskTrackerScreen extends StatefulWidget {
  const TaskTrackerScreen({super.key});

  @override
  State<TaskTrackerScreen> createState() => _TaskTrackerScreenState();
}

class _TaskTrackerScreenState extends State<TaskTrackerScreen>
    with SingleTickerProviderStateMixin {
  AppUser? currentUser;
  final FirestoreService _firestoreService = FirestoreService();

  // TabController делаем доступным для Drawer
  TabController get tabController => _tabControllerInternal;
  late TabController _tabControllerInternal;

  String? _saveMessage;
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    super.initState();
    _tabControllerInternal = TabController(length: 3, vsync: this);
    _loadUserData();
  }

  // Метод обновления данных
  Future<void> _refreshData() async {
    print('🔄 Принудительное обновление данных...');
    setState(() {
      currentUser = null;
    });
    await _loadUserData();
  }

  // Изменяем метод чтобы возвращал Future<void>
  // Изменяем метод чтобы возвращал Future<void>
  Future<void> _loadUserData() async {
    print('📥 Загрузка данных пользователя...');
    final localRepo = Provider.of<LocalRepository>(context, listen: false);

    try {
      final localUser = localRepo.loadUser();
      if (localUser != null && localUser.username.isNotEmpty) {
        print('✅ Используем локальные данные из Hive');
        if (mounted) {
          setState(() => currentUser = localUser);
        }
        return;
      }

      final authService = Provider.of<AuthService>(context, listen: false);
      final currentAuthUser = authService.currentUser;

      if (currentAuthUser != null) {
        try {
          print('🔍 Загрузка данных пользователя из Firestore...');
          final userDoc = await _firestoreService.getUserDocument(currentAuthUser.uid);

          if (userDoc.exists) {
            final userData = userDoc.data() as Map<String, dynamic>;
            final firestoreUser = AppUser.fromFirestore(userData);

            if (mounted) {
              setState(() {
                currentUser = firestoreUser;
              });
            }

            await localRepo.saveUser(firestoreUser);
            print('✅ Данные сохранены в Hive');

            if (firestoreUser.projects.isEmpty) {
              print('ℹ️ Пользователь существует, но проекты отсутствуют');
            }
          } else {
            print('ℹ️ Документ пользователя не существует в Firestore');
          }
        } catch (e) {
          print('❌ Ошибка загрузки пользователя: $e');
          if (mounted) {
            setState(() {
              currentUser = AppUser.empty();
            });
          }
        }
      }
    } catch (e) {
      print('❌ Неожиданная ошибка в _loadUserData: $e');
    }
  }

  // Метод для обработки завершения задач из экрана планирования
  void _handleItemCompletionFromPlanning(Map<String, dynamic> completionResult) {
    _handleItemCompletion(completionResult);

    // Показываем уведомление
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ Задача выполнена!'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // Метод для сохранения текущего пользователя в Firestore
  void _saveCurrentUser() {
    if (currentUser == null) return;

    final authService = Provider.of<AuthService>(context, listen: false);
    final currentAuthUser = authService.currentUser;

    if (currentAuthUser == null) return;

    // Если данные пустые, заполняем их из аутентификации
    if (currentUser!.username.isEmpty || currentUser!.email.isEmpty) {
      print('⚠️ Заполняем пустые данные пользователя из аутентификации');
      setState(() {
        currentUser = AppUser(
          username: currentAuthUser.email?.split('@').first ?? 'User',
          email: currentAuthUser.email ?? '',
          projects: currentUser?.projects ?? [],
          progressHistory: currentUser?.progressHistory ?? [],
        );
      });
    }

    final localRepo = Provider.of<LocalRepository>(context, listen: false);

    try {
      localRepo.saveUser(currentUser!);
      print('✅ Данные сохранены в Hive: ${currentUser!.username}');
    } catch (e) {
      print('❌ Ошибка сохранения в Hive: $e');
      return;
    }

    setState(() {
      _saveMessage = 'Сохранение...';
    });

    print('💾 Сохранение пользователя в Firestore: ${currentUser!.username}');

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
      print('❌ Ошибка сохранения в Firestore: $error');
    });
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
          controller: _tabControllerInternal, // ← ИСПРАВИТЬ НА _tabControllerInternal
          tabs: const [
            Tab(icon: Icon(Icons.list), text: 'Проекты'),
            Tab(icon: Icon(Icons.bar_chart), text: 'Статистика'),
            Tab(icon: Icon(Icons.calendar_month), text: 'Календарь'),
          ],
        ),
      ),
      drawer: DrawerScreen(
        userEmail: authService.currentUser?.email,
        currentUser: currentUser,
        tabController: tabController, // ← ПЕРЕДАЕМ КОНТРОЛЛЕР
        onItemCompletedFromPlanning: _handleItemCompletionFromPlanning, // ← ДОБАВИТЬ ЭТУ СТРОКУ
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
            child: RefreshIndicator(
              key: _refreshIndicatorKey,
              onRefresh: _refreshData,
              child: TabBarView(
                controller: _tabControllerInternal, // ← ИСПРАВИТЬ НА _tabControllerInternal
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
                  currentUser != null
                      ? CalendarScreen(
                    currentUser: currentUser,
                    onItemCompleted: _handleItemCompletion,
                  )
                      : const Center(child: CircularProgressIndicator()),
                ],
              ),
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
    _tabControllerInternal.dispose(); // ← ИСПРАВИТЬ НА _tabControllerInternal
    super.dispose();
  }

  void _handleItemCompletion(Map<String, dynamic> completionResult) {
    if (completionResult['item'] == null || currentUser == null) return;

    final completedItem = completionResult['item'];
    final project = completionResult['project'];
    final task = completionResult['task'];
    final stage = completionResult['stage'];

    // Используем CompletionService для обработки
    final result = CompletionService.completeItemWithHistory(
      item: completedItem,
      stepsAdded: 1, // По умолчанию +1 шаг
      itemName: CompletionService.getItemName(completedItem),
      itemType: CompletionService.getItemType(completedItem),
      currentHistory: currentUser!.progressHistory,
    );

    // Обновляем проекты
    final updatedProjects = currentUser!.projects.map((p) => p.name == project?.name
        ? _updateProjectWithCompletion(p, result['updatedItem'], task, stage)
        : p
    ).toList();

    setState(() {
      currentUser = AppUser(
        username: currentUser!.username,
        email: currentUser!.email,
        projects: updatedProjects,
        progressHistory: result['updatedHistory'],
      );
    });

    _saveCurrentUser();

    // Показываем уведомление
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ ${CompletionService.getItemName(completedItem)} выполнено!'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Project _updateProjectWithCompletion(Project project, dynamic completedItem, Task? parentTask, Stage? parentStage) {
    final updatedTasks = project.tasks.map((t) {
      // Если это задача верхнего уровня
      if (completedItem is Task && t.name == completedItem.name) {
        return completedItem;
      }

      // Если это этап или шаг внутри задачи
      if (parentTask != null && t.name == parentTask.name) {
        final updatedStages = t.stages.map((s) {
          // Если это этап
          if (completedItem is Stage && s.name == completedItem.name) {
            return completedItem;
          }

          // Если это шаг внутри этапа
          if (parentStage != null && s.name == parentStage.name && completedItem is custom_step.Step) {
            final updatedSteps = s.steps.map((step) =>
            step.name == completedItem.name ? completedItem : step
            ).toList();
            return Stage(
              name: s.name,
              completedSteps: s.completedSteps,
              totalSteps: s.totalSteps,
              stageType: s.stageType,
              isCompleted: s.isCompleted,
              steps: updatedSteps,
              plannedDate: s.plannedDate,
              recurrence: s.recurrence,
            );
          }

          return s;
        }).toList();

        return Task(
          name: t.name,
          completedSteps: t.completedSteps,
          totalSteps: t.totalSteps,
          stages: updatedStages,
          taskType: t.taskType,
          recurrence: t.recurrence,
          dueDate: t.dueDate,
          isCompleted: t.isCompleted,
          description: t.description,
          plannedDate: t.plannedDate,
        );
      }

      return t;
    }).toList();

    return Project(
      name: project.name,
      tasks: updatedTasks,
    );
  }
  }