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
import '../repositories/local_repository.dart';
import '../models/task.dart';
import '../services/completion_service.dart';
import 'calendar_screen.dart';
import '../widgets/task_heatmap_widget.dart';
import '../services/recurrence_completion_service.dart';



class TaskTrackerScreen extends StatefulWidget {
  const TaskTrackerScreen({super.key});

  @override
  State<TaskTrackerScreen> createState() => _TaskTrackerScreenState();
}

class _TaskTrackerScreenState extends State<TaskTrackerScreen>
    with SingleTickerProviderStateMixin {
  AppUser? currentUser;
  final FirestoreService _firestoreService = FirestoreService();

  TabController get tabController => _tabControllerInternal;
  late TabController _tabControllerInternal;

  String? _saveMessage;
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
  GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    super.initState();
    _tabControllerInternal = TabController(length: 4, vsync: this);
    _initializeData().then((_) {
      _fixMissingPlannedDates();
    });
  }

  Future<void> _initializeData() async {
    await Future.delayed(const Duration(milliseconds: 500));
    await _loadUserData();

    final localRepo = Provider.of<LocalRepository>(context, listen: false);
    final recovered = await localRepo.checkAndRecoverData();
    if (recovered) {
      print('✅ Данные восстановлены');
      await _loadUserData();
    }
  }

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
          final userDoc =
          await _firestoreService.getUserDocument(currentAuthUser.uid);

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
          } else {
            if (mounted) {
              setState(() {
                currentUser = AppUser.empty();
              });
            }
          }
        } catch (e) {
          print('❌ Ошибка загрузки пользователя: $e');
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
      if (mounted) {
        setState(() {
          currentUser = AppUser.empty();
        });
      }
    }
  }

  /// Подсчёт завершённых задач в проекте
  Future<int> _calculateRealCompletedTasks(
      Project project, BuildContext context) async {
    int completed = 0;
    final today = DateTime.now();

    for (var task in project.tasks) {
      if (task.recurrence != null) {
        final done = await RecurrenceCompletionService.isOccurrenceCompleted(
          task,
          today,
          context,
        );
        if (done) completed++;
      } else if (task.taskType == "singleStep" && task.isCompleted) {
        completed++;
      } else if (task.taskType == "stepByStep" &&
          task.completedSteps >= task.totalSteps) {
        completed++;
      }
    }

    return completed;
  }

  void _handleItemCompletion(Map<String, dynamic> completionResult) {
    if (completionResult['item'] == null || currentUser == null) return;

    final completedItem = completionResult['item'];
    final project = completionResult['project'];
    final task = completionResult['task'];
    final stage = completionResult['stage'];
    final isRecurring = completionResult['isRecurring'] == true;
    final occurrenceDate = completionResult['occurrenceDate'];

    print('🎯 Обработка выполнения: ${completedItem.name}, recurring: $isRecurring');

    if (isRecurring && occurrenceDate != null) {
      _handleRecurringItemCompletion(completedItem, project, task, stage);
      return;
    }

    _handleRegularItemCompletion(completedItem, project, task, stage);
  }

  void _handleRecurringItemCompletion(
      dynamic completedItem, Project? project, Task? task, Stage? stage) {
    final progressHistory = ProgressHistory(
      date: DateTime.now(),
      itemName: completedItem.name,
      stepsAdded: 1,
      itemType: _getItemType(completedItem),
    );

    final updatedHistory = List<dynamic>.from(currentUser!.progressHistory)
      ..add(progressHistory);

    setState(() {
      currentUser = AppUser(
        username: currentUser!.username,
        email: currentUser!.email,
        projects: currentUser!.projects,
        progressHistory: updatedHistory,
      );
    });

    _saveCurrentUser();
  }

  void _handleRegularItemCompletion(
      dynamic completedItem, Project? project, Task? task, Stage? stage) {
    final result = CompletionService.completeItemWithHistory(
      item: completedItem,
      stepsAdded: 1,
      itemName: CompletionService.getItemName(completedItem),
      itemType: CompletionService.getItemType(completedItem),
      currentHistory: currentUser!.progressHistory,
    );

    final updatedProjects = _updateProjectsWithCompletion(
      currentUser!.projects,
      completedItem,
      project,
      task,
      stage,
      result['updatedItem'],
    );

    setState(() {
      currentUser = AppUser(
        username: currentUser!.username,
        email: currentUser!.email,
        projects: updatedProjects,
        progressHistory: result['updatedHistory'],
      );
    });

    _saveCurrentUser();
  }

  String _getItemType(dynamic item) {
    if (item is Task) return 'task';
    if (item is Stage) return 'stage';
    if (item is custom_step.Step) return 'step';
    return 'unknown';
  }

  void _saveCurrentUser() {
    if (currentUser == null) return;

    final authService = Provider.of<AuthService>(context, listen: false);
    final currentAuthUser = authService.currentUser;

    if (currentAuthUser == null) return;

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

    _firestoreService.saveUser(currentUser!, currentAuthUser.uid).then((_) {
      setState(() {
        _saveMessage = 'Данные сохранены ✅';
      });
      Future.delayed(const Duration(seconds: 2), () {
        setState(() {
          _saveMessage = null;
        });
      });
    }).catchError((error) {
      setState(() {
        _saveMessage = 'Ошибка сохранения: $error';
      });
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

  void _handleItemCompletionFromPlanning(
      Map<String, dynamic> completionResult) {
    _handleItemCompletion(completionResult);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Задача выполнена!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(currentUser?.username ??
            authService.currentUser?.email ??
            '📊 Трекер задач'),
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
              color: _saveMessage!.contains('Ошибка')
                  ? Colors.red[100]
                  : Colors.green[100],
              child: Row(
                children: [
                  Icon(
                    _saveMessage!.contains('Ошибка')
                        ? Icons.error
                        : Icons.check_circle,
                    color: _saveMessage!.contains('Ошибка')
                        ? Colors.red
                        : Colors.green,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _saveMessage!,
                      style: TextStyle(
                        color: _saveMessage!.contains('Ошибка')
                            ? Colors.red
                            : Colors.green,
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
                      ? StatisticsWidgets.buildStatisticsTab(
                      context, currentUser)
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

  List<Project> _updateProjectsWithCompletion(
      List<Project> projects,
      dynamic completedItem,
      Project? targetProject,
      Task? targetTask,
      Stage? targetStage,
      dynamic updatedItem,
      ) {
    return projects.map((project) {
      if (targetProject != null && project.name != targetProject.name) {
        return project;
      }

      final updatedTasks = project.tasks.map((task) {
        if (targetTask != null && task.name == targetTask.name) {
          return _updateTaskWithCompletion(
              task, completedItem, targetStage, updatedItem);
        }

        if (completedItem is Task && task.name == completedItem.name) {
          return updatedItem;
        }

        return task;
      }).toList();

      return Project(name: project.name, tasks: updatedTasks.cast<Task>());
    }).toList();
  }


// исправленный фрагмент без copyWith

  Task _updateTaskWithCompletion(
      Task task,
      dynamic completedItem,
      Stage? targetStage,
      dynamic updatedItem,
      ) {
    if (completedItem is Stage && targetStage != null) {
      final updatedStages = task.stages.map((stage) {
        if (stage.name == targetStage.name) {
          return _updateStageWithCompletion(stage, completedItem, updatedItem);
        }
        return stage;
      }).toList();

      return Task(
        name: task.name,
        completedSteps: task.completedSteps,
        totalSteps: task.totalSteps,
        stages: updatedStages,
        taskType: task.taskType,
        recurrence: task.recurrence,
        dueDate: task.dueDate,
        isCompleted: task.isCompleted,
        description: task.description,
        plannedDate: task.plannedDate,
        colorValue: task.colorValue,
        isTracked: task.isTracked,
      );
    }

    if (completedItem is custom_step.Step && targetStage != null) {
      final updatedStages = task.stages.map((stage) {
        if (stage.name == targetStage.name) {
          final updatedSteps = stage.steps.map((step) {
            if (step.name == completedItem.name) {
              return updatedItem;
            }
            return step;
          }).toList();

          return Stage(
            name: stage.name,
            completedSteps: stage.completedSteps,
            totalSteps: stage.totalSteps,
            stageType: stage.stageType,
            isCompleted: stage.isCompleted,
            steps: updatedSteps.cast<custom_step.Step>(),
            plannedDate: stage.plannedDate,
            recurrence: stage.recurrence,
          );
        }
        return stage;
      }).toList();

      return Task(
        name: task.name,
        completedSteps: task.completedSteps,
        totalSteps: task.totalSteps,
        stages: updatedStages,
        taskType: task.taskType,
        recurrence: task.recurrence,
        dueDate: task.dueDate,
        isCompleted: task.isCompleted,
        description: task.description,
        plannedDate: task.plannedDate,
        colorValue: task.colorValue,
        isTracked: task.isTracked,
      );
    }

    return task;
  }

  Stage _updateStageWithCompletion(
      Stage stage,
      dynamic completedItem,
      dynamic updatedItem,
      ) {
    if (completedItem is custom_step.Step) {
      final updatedSteps = stage.steps.map((step) {
        if (step.name == completedItem.name) {
          return updatedItem;
        }
        return step;
      }).toList();

      return Stage(
        name: stage.name,
        completedSteps: stage.completedSteps,
        totalSteps: stage.totalSteps,
        stageType: stage.stageType,
        isCompleted: stage.isCompleted,
        steps: updatedSteps.cast<custom_step.Step>(),
        plannedDate: stage.plannedDate,
        recurrence: stage.recurrence,
      );
    }

    return updatedItem;
  }

  void _fixMissingPlannedDates() {
    if (currentUser == null) return;

    bool needsFix = false;
    final updatedProjects = currentUser!.projects.map((project) {
      final updatedTasks = project.tasks.map((task) {
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
            plannedDate: DateTime.now(),
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

