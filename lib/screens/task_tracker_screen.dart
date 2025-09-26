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
import 'planning_calendar_screen.dart';
import '../repositories/local_repository.dart';
import '../models/task.dart';
import '../models/stage.dart';
import '../models/step.dart' as custom_step;
import '../services/completion_service.dart';
import 'calendar_screen.dart';
import '../widgets/task_heatmap_widget.dart';
import '../services/recurrence_service.dart'; // ← ДОБАВИТЬ
import '../models/recurrence.dart'; // ← ДОБАВИТЬ


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
    _tabControllerInternal = TabController(length: 4, vsync: this);
    _initializeData().then((_) {
      _fixMissingPlannedDates(); // ← ДОБАВЬТЕ ЭТУ СТРОЧКУ
    });
  }

  Future<void> _initializeData() async {
    // Даем время на инициализацию Hive
    await Future.delayed(const Duration(milliseconds: 500));

    // Сначала пробуем загрузить данные
    await _loadUserData();

    // Затем проверяем и восстанавливаем данные если нужно
    final localRepo = Provider.of<LocalRepository>(context, listen: false);
    final recovered = await localRepo.checkAndRecoverData();
    if (recovered) {
      print('✅ Данные восстановлены');
      await _loadUserData(); // Перезагружаем данные
    }
  }



  // Метод обновления данных
  Future<void> _refreshData() async {
    print('🔄 Принудительное обновление данных...');
    setState(() {
      currentUser = null;
    });
    await _loadUserData();
  }


  Future<void> _loadUserData() async {
    print('📥 Загрузка данных пользователя...');
    final localRepo = Provider.of<LocalRepository>(context, listen: false);

    try {
      // ПЕРВОЕ: Пробуем загрузить из Hive
      final localUser = localRepo.loadUser();
      if (localUser != null && localUser.username.isNotEmpty) {
        print('✅ Используем локальные данные из Hive');
        print('📊 Проектов: ${localUser.projects.length}, История: ${localUser.progressHistory.length}');

        if (mounted) {
          setState(() => currentUser = localUser);
        }
        return;
      }

      // ВТОРОЕ: Если в Hive пусто, пробуем Firestore
      final authService = Provider.of<AuthService>(context, listen: false);
      final currentAuthUser = authService.currentUser;

      if (currentAuthUser != null) {
        try {
          print('🔍 Загрузка данных пользователя из Firestore...');
          final userDoc = await _firestoreService.getUserDocument(currentAuthUser.uid);

          if (userDoc.exists) {
            final userData = userDoc.data() as Map<String, dynamic>;
            final firestoreUser = AppUser.fromFirestore(userData);

            print('✅ Данные из Firestore: ${firestoreUser.projects.length} проектов');

            if (mounted) {
              setState(() {
                currentUser = firestoreUser;
              });
            }

            // Сохраняем в Hive для будущих загрузок
            await localRepo.saveUser(firestoreUser);
            print('✅ Данные сохранены в Hive');
          } else {
            print('ℹ️ Документ пользователя не существует в Firestore');
            // Создаем пустого пользователя
            if (mounted) {
              setState(() {
                currentUser = AppUser.empty();
              });
            }
          }
        } catch (e) {
          print('❌ Ошибка загрузки пользователя: $e');
          // Создаем пустого пользователя как запасной вариант
          if (mounted) {
            setState(() {
              currentUser = AppUser.empty();
            });
          }
        }
      } else {
        print('⚠️ Нет аутентифицированного пользователя');
      }
    } catch (e) {
      print('❌ Неожиданная ошибка в _loadUserData: $e');
      // Создаем пустого пользователя как запасной вариант
      if (mounted) {
        setState(() {
          currentUser = AppUser.empty();
        });
      }
    }
  }

  AppUser _autoMoveDailyTasks(AppUser user) {
    final updatedProjects = user.projects.map((project) {
      final updatedTasks = project.tasks.map((task) {
        // Автоматический перенос daily задач, которые ПРОСРОЧЕНЫ и не выполнены
        if (task.recurrence?.type == RecurrenceType.daily &&
            task.plannedDate != null &&
            RecurrenceService.shouldMoveToNextDay(task.plannedDate!, task.recurrence!) &&
            !task.isCompleted) {

          // Для recurring задач не меняем plannedDate, только если они просрочены
          final nextDate = RecurrenceService.getNextOccurrenceForDailyTask(task.plannedDate!, task.recurrence!);
          return Task(
            name: task.name,
            completedSteps: 0,
            totalSteps: task.totalSteps,
            stages: task.stages,
            taskType: task.taskType,
            recurrence: task.recurrence,
            dueDate: task.dueDate,
            isCompleted: false,
            description: task.description,
            plannedDate: nextDate, // ⚠️ Меняем дату только для просроченных
            colorValue: task.colorValue,
            isTracked: task.isTracked,
          );
        }
        return task;
      }).toList();

      return Project(name: project.name, tasks: updatedTasks);
    }).toList();

    return AppUser(
      username: user.username,
      email: user.email,
      projects: updatedProjects,
      progressHistory: user.progressHistory,
    );
  }

  // Метод для обработки завершения задач из экрана планирования
  // В lib/screens/task_tracker_screen.dart в методе _handleItemCompletion
  void _handleItemCompletion(Map<String, dynamic> completionResult) {
    if (completionResult['item'] == null || currentUser == null) return;

    final completedItem = completionResult['item'];
    final project = completionResult['project'];
    final task = completionResult['task'];
    final stage = completionResult['stage'];

    print('🎯 Обработка выполнения элемента:');
    print('   📝 Элемент: ${completedItem.name}');
    print('   🏗️ Тип: ${completedItem.runtimeType}');
    print('   📂 Проект: ${project?.name}');
    print('   ✅ Задача: ${task?.name}');
    print('   📋 Этап: ${stage?.name}');

    if (completedItem is Task) {
      print('   🔄 Тип задачи: ${completedItem.taskType}');
      print('   📊 Прогресс до: ${completedItem.completedSteps}/${completedItem.totalSteps}');
      print('   ✅ Выполнена до: ${completedItem.isCompleted}');
    }

    // Для recurring задач - не сбрасываем прогресс, просто отмечаем выполнение
    final result = CompletionService.completeItemWithHistory(
      item: completedItem,
      stepsAdded: 1,
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

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(currentUser?.username ?? authService.currentUser?.email ?? '📊 Трекер задач'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabControllerInternal,
          tabs: const [
            Tab(icon: Icon(Icons.list), text: 'Проекты'),
            Tab(icon: Icon(Icons.bar_chart), text: 'Статистика'),
            Tab(icon: Icon(Icons.analytics), text: 'Аналитика'),
            Tab(icon: Icon(Icons.calendar_month), text: 'Календарь'),
          ],
        ),
      ),
      drawer: DrawerScreen(
        userEmail: authService.currentUser?.email,
        currentUser: currentUser,
        tabController: tabController,
        onItemCompletedFromPlanning: _handleItemCompletionFromPlanning,
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
                controller: _tabControllerInternal,
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
                      ? TaskHeatmapWidget(currentUser: currentUser)
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
    _tabControllerInternal.dispose();
    super.dispose();
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

  // В _TaskTrackerScreenState
  void _resetDailyRecurringTasks() {
    if (currentUser == null) return;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastReset = _getLastResetDate();

    // Сбрасываем статус только если сегодня новый день
    if (lastReset == null || lastReset.isBefore(today)) {
      print('🔄 Сброс статуса daily recurring задач на новый день');

      final updatedProjects = currentUser!.projects.map((project) {
        final updatedTasks = project.tasks.map((task) {
          // Сбрасываем только daily recurring задачи
          if (task.recurrence?.type == RecurrenceType.daily && task.isCompleted) {
            return Task(
              name: task.name,
              completedSteps: 0,
              totalSteps: task.totalSteps,
              stages: task.stages,
              taskType: task.taskType,
              recurrence: task.recurrence,
              dueDate: task.dueDate,
              isCompleted: false, // СБРАСЫВАЕМ статус выполнения
              description: task.description,
              plannedDate: task.plannedDate,
              colorValue: task.colorValue,
              isTracked: task.isTracked,
            );
          }
          return task;
        }).toList();

        return Project(name: project.name, tasks: updatedTasks);
      }).toList();

      setState(() {
        currentUser = AppUser(
          username: currentUser!.username,
          email: currentUser!.email,
          projects: updatedProjects,
          progressHistory: currentUser!.progressHistory,
        );
      });

      _saveLastResetDate(today);
      _saveCurrentUser();
    }
  }

  DateTime? _getLastResetDate() {
    // Реализуйте хранение даты последнего сброса (например, в SharedPreferences)
    return null;
  }

  void _saveLastResetDate(DateTime date) {
    // Реализуйте сохранение даты последнего сброса
  }

  // В _TaskTrackerScreenState добавьте метод:
  void _fixMissingPlannedDates() {
    if (currentUser == null) return;

    bool needsFix = false;
    final updatedProjects = currentUser!.projects.map((project) {
      final updatedTasks = project.tasks.map((task) {
        // Если задача recurring но plannedDate = null - восстанавливаем
        if (task.recurrence != null && task.plannedDate == null) {
          needsFix = true;
          return Task(
            name: task.name,
            completedSteps: task.completedSteps,
            totalSteps: task.totalSteps,
            stages: task.stages,
            taskType: task.taskType,
            recurrence: task.recurrence,
            dueDate: task.dueDate,
            isCompleted: task.isCompleted,
            description: task.description,
            plannedDate: DateTime.now(), // Устанавливаем сегодняшнюю дату
            colorValue: task.colorValue,
            isTracked: task.isTracked,
          );
        }
        return task;
      }).toList();

      return Project(name: project.name, tasks: updatedTasks);
    }).toList();

    if (needsFix) {
      setState(() {
        currentUser = AppUser(
          username: currentUser!.username,
          email: currentUser!.email,
          projects: updatedProjects,
          progressHistory: currentUser!.progressHistory,
        );
      });
      _saveCurrentUser();
      print('✅ Восстановлены отсутствующие plannedDate');
    }
  }
}