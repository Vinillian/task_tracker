import 'package:flutter/material.dart';
import '../models/task.dart';
import '../models/project.dart';
import '../services/task_service.dart';
import '../services/completion_service.dart';
import '../widgets/task_list_item.dart';

class PlanningCalendarScreen extends StatefulWidget {
  final List<Project> projects;

  const PlanningCalendarScreen({Key? key, required this.projects}) : super(key: key);

  @override
  _PlanningCalendarScreenState createState() => _PlanningCalendarScreenState();
}

class _PlanningCalendarScreenState extends State<PlanningCalendarScreen> {
  late TaskService _taskService;
  late CompletionService _completionService;
  DateTime _selectedDate = DateTime.now();
  Map<DateTime, List<Task>> _tasksByDate = {};
  Map<String, bool> _expandedTasks = {}; // Для отслеживания раскрытых задач

  @override
  void initState() {
    super.initState();
    _completionService = CompletionService();
    _taskService = TaskService(_completionService);
    _groupTasksByDate();
  }

  @override
  void didUpdateWidget(PlanningCalendarScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.projects != oldWidget.projects) {
      _groupTasksByDate();
    }
  }

  // Группируем задачи по датам для планирования
  void _groupTasksByDate() {
    _tasksByDate = {};

    final allTasks = _getAllTasks();

    for (final task in allTasks) {
      // Для задач с dueDate
      if (task.dueDate != null) {
        final date = DateTime(task.dueDate!.year, task.dueDate!.month, task.dueDate!.day);
        _tasksByDate.putIfAbsent(date, () => []).add(task);
      }

      // Для незавершенных задач без даты - предлагаем запланировать
      if (!task.isCompleted && task.dueDate == null) {
        final today = DateTime.now();
        final date = DateTime(today.year, today.month, today.day);
        _tasksByDate.putIfAbsent(date, () => []).add(task);
      }
    }

    setState(() {});
  }

  // Получаем все задачи (включая подзадачи)
  List<Task> _getAllTasks() {
    final allTasks = <Task>[];

    for (final project in widget.projects) {
      allTasks.addAll(project.allTasks);
    }

    return allTasks;
  }

  // Получаем задачи для выбранной даты
  List<Task> _getTasksForSelectedDate() {
    final dateKey = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    return _tasksByDate[dateKey] ?? [];
  }

  // Перемещаем задачу на выбранную дату
  void _rescheduleTask(Task task, DateTime newDate) {
    setState(() {
      // Удаляем задачу из старой даты
      for (final date in _tasksByDate.keys) {
        _tasksByDate[date]?.removeWhere((t) => t.id == task.id);
      }

      // Добавляем на новую дату
      final newDateKey = DateTime(newDate.year, newDate.month, newDate.day);
      _tasksByDate.putIfAbsent(newDateKey, () => []).add(task);

      // TODO: Обновить задачу в репозитории с новой датой
      // final updatedTask = task.copyWith(dueDate: newDate);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Задача "${task.title}" перенесена на ${newDate.day}.${newDate.month}.${newDate.year}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tasksForSelectedDate = _getTasksForSelectedDate();
    final completedTasksCount = tasksForSelectedDate.where((task) => task.isCompleted).length;

    return Scaffold(
      appBar: AppBar(
        title: Text('Планирование'),
        actions: [
          IconButton(
            icon: Icon(Icons.today),
            onPressed: () {
              setState(() {
                _selectedDate = DateTime.now();
              });
            },
            tooltip: 'Сегодня',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              _handleMenuAction(value);
            },
            itemBuilder: (BuildContext context) => [
              PopupMenuItem(
                value: 'show_completed',
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green),
                    SizedBox(width: 8),
                    Text('Показать выполненные'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'hide_completed',
                child: Row(
                  children: [
                    Icon(Icons.hide_source, color: Colors.orange),
                    SizedBox(width: 8),
                    Text('Скрыть выполненные'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Статистика дня
          _buildDayStats(completedTasksCount, tasksForSelectedDate.length),
          // Календарь для выбора даты
          _buildDateSelector(),
          // Список задач на выбранную дату
          Expanded(
            child: _buildTaskList(tasksForSelectedDate),
          ),
        ],
      ),
    );
  }

  Widget _buildDayStats(int completedCount, int totalCount) {
    final progress = totalCount > 0 ? completedCount / totalCount : 0.0;

    return Card(
      margin: EdgeInsets.all(16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              '${_selectedDate.day}.${_selectedDate.month}.${_selectedDate.year}',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey.shade200,
              color: _getProgressColor(progress),
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Прогресс: ${(progress * 100).toStringAsFixed(1)}%',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
                Text(
                  '$completedCount/$totalCount задач',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSelector() {
    return Container(
      height: 80,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16),
        children: List.generate(30, (index) {
          final date = DateTime.now().add(Duration(days: index));
          final isSelected = _isSameDay(date, _selectedDate);
          final hasTasks = _tasksByDate.containsKey(DateTime(date.year, date.month, date.day));
          final isToday = _isSameDay(date, DateTime.now());

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedDate = date;
              });
            },
            child: Container(
              width: 60,
              margin: EdgeInsets.symmetric(horizontal: 4),
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.blue
                    : isToday
                    ? Colors.blue.shade50
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isToday && !isSelected ? Colors.blue : Colors.transparent,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _getWeekdayName(date.weekday),
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected ? Colors.white : Colors.grey.shade600,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '${date.day}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : Colors.black,
                    ),
                  ),
                  if (hasTasks)
                    Container(
                      margin: EdgeInsets.only(top: 2),
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.white : Colors.blue,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTaskList(List<Task> tasks) {
    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.schedule, size: 64, color: Colors.grey.shade300),
            SizedBox(height: 16),
            Text(
              'Нет задач на ${_selectedDate.day}.${_selectedDate.month}.${_selectedDate.year}',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
            SizedBox(height: 8),
            ElevatedButton(
              onPressed: _showUnplannedTasks,
              child: Text('Показать незапланированные задачи'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(8),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        final isExpanded = _expandedTasks[task.id] ?? false;

        return Column(
          children: [
            TaskListItem(
              task: task,
              nestingLevel: task.nestingLevel,
              onTap: () => _toggleTaskExpansion(task),
              onComplete: () => _toggleTaskCompletion(task),
              onAddSubtask: task.canAddSubtask() ? () => _showAddSubtaskDialog(task) : null,
              onEdit: () => _showRescheduleDialog(task),
              onDelete: () => _removeFromPlanning(task),
              isSelected: false,
            ),
            // Подзадачи (если раскрыто)
            if (isExpanded && task.hasSubtasks)
              ...task.subtasks.map((subtask) => Padding(
                padding: EdgeInsets.only(left: 16),
                child: TaskListItem(
                  task: subtask,
                  nestingLevel: subtask.nestingLevel,
                  onTap: () => _toggleSubtaskCompletion(subtask, task),
                  onComplete: () => _toggleSubtaskCompletion(subtask, task),
                  onAddSubtask: null, // Подзадачи не могут иметь своих подзадач на 3 уровне
                  onEdit: () => _showRescheduleDialog(subtask),
                  onDelete: () => _removeFromPlanning(subtask),
                  isSelected: false,
                ),
              )),
          ],
        );
      },
    );
  }

  // === ОБРАБОТЧИКИ СОБЫТИЙ ===

  void _toggleTaskExpansion(Task task) {
    setState(() {
      _expandedTasks[task.id] = !(_expandedTasks[task.id] ?? false);
    });
  }

  void _toggleTaskCompletion(Task task) {
    setState(() {
      final updatedTask = task.isCompleted
          ? _taskService.uncompleteTask(task)
          : _taskService.completeTask(task);

      // Обновляем задачу в группировке
      _updateTaskInGrouping(updatedTask);

      // TODO: Сохранить в репозитории
    });
  }

  void _toggleSubtaskCompletion(Task subtask, Task parentTask) {
    setState(() {
      final updatedSubtask = subtask.isCompleted
          ? _taskService.uncompleteTask(subtask)
          : _taskService.completeTask(subtask);

      final updatedParentTask = parentTask.updateSubtask(subtask.id, updatedSubtask);

      // Обновляем обе задачи в группировке
      _updateTaskInGrouping(updatedSubtask);
      _updateTaskInGrouping(updatedParentTask);

      // TODO: Сохранить в репозитории
    });
  }

  void _updateTaskInGrouping(Task updatedTask) {
    for (final date in _tasksByDate.keys) {
      final index = _tasksByDate[date]?.indexWhere((t) => t.id == updatedTask.id);
      if (index != null && index >= 0) {
        _tasksByDate[date]![index] = updatedTask;
      }
    }
  }

  void _showRescheduleDialog(Task task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Перенести задачу'),
        content: Text('Выберите новую дату для задачи "${task.title}"'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showDatePickerForReschedule(task);
            },
            child: Text('Выбрать дату'),
          ),
        ],
      ),
    );
  }

  void _showDatePickerForReschedule(Task task) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      _rescheduleTask(task, picked);
    }
  }

  void _removeFromPlanning(Task task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Убрать из планирования?'),
        content: Text('Задача "${task.title}" будет убрана из планирования на ${_selectedDate.day}.${_selectedDate.month}.${_selectedDate.year}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _performRemoveFromPlanning(task);
            },
            child: Text('Убрать', style: TextStyle(color: Colors.orange)),
          ),
        ],
      ),
    );
  }

  void _performRemoveFromPlanning(Task task) {
    setState(() {
      final dateKey = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
      _tasksByDate[dateKey]?.removeWhere((t) => t.id == task.id);

      // TODO: Убрать dueDate у задачи в репозитории
      // final updatedTask = task.copyWith(dueDate: null);
    });
  }

  void _showAddSubtaskDialog(Task task) {
    // TODO: Реализовать диалог добавления подзадачи
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Добавление подзадачи для: ${task.title}')),
    );
  }

  void _showUnplannedTasks() {
    final unplannedTasks = _getAllTasks().where((task) =>
    !task.isCompleted && task.dueDate == null
    ).toList();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Незапланированные задачи'),
        content: Container(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: unplannedTasks.length,
            itemBuilder: (context, index) {
              final task = unplannedTasks[index];
              return ListTile(
                title: Text(task.title),
                subtitle: task.projectId.isNotEmpty ? Text('Проект: ${_getProjectName(task.projectId)}') : null,
                trailing: IconButton(
                  icon: Icon(Icons.schedule),
                  onPressed: () => _rescheduleTask(task, _selectedDate),
                  tooltip: 'Запланировать на выбранную дату',
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  void _handleMenuAction(String value) {
    switch (value) {
      case 'show_completed':
      // TODO: Реализовать показ выполненных задач
        break;
      case 'hide_completed':
      // TODO: Реализовать скрытие выполненных задач
        break;
    }
  }

  // === ВСПОМОГАТЕЛЬНЫЕ МЕТОДЫ ===

  String _getProjectName(String projectId) {
    final project = widget.projects.firstWhere(
          (p) => p.id == projectId,
      orElse: () => Project(
        id: '',
        name: 'Неизвестный проект',
        tasks: [],
        createdAt: DateTime.now(),
        isCompleted: false,
      ),
    );
    return project.name;
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  String _getWeekdayName(int weekday) {
    const weekdays = ['Вс', 'Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб'];
    return weekdays[weekday - 1];
  }

  Color _getProgressColor(double progress) {
    if (progress < 0.3) return Colors.red;
    if (progress < 0.7) return Colors.orange;
    return Colors.green;
  }
}