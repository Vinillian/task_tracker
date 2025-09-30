import 'package:flutter/material.dart';
import '../models/task.dart';
import '../models/project.dart';
import '../services/task_service.dart';
import '../services/completion_service.dart';
import '../widgets/task_list_item.dart';

class CalendarScreen extends StatefulWidget {
  final List<Project> projects;

  const CalendarScreen({Key? key, required this.projects}) : super(key: key);

  @override
  _CalendarScreenState createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late TaskService _taskService;
  late CompletionService _completionService;
  DateTime _selectedDate = DateTime.now();

  // Для группировки задач по датам
  Map<DateTime, List<Task>> _tasksByDate = {};

  @override
  void initState() {
    super.initState();
    _completionService = CompletionService();
    _taskService = TaskService(_completionService);
    _groupTasksByDate();
  }

  @override
  void didUpdateWidget(CalendarScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.projects != oldWidget.projects) {
      _groupTasksByDate();
    }
  }

  // Группируем все задачи по датам (включая подзадачи)
  void _groupTasksByDate() {
    _tasksByDate = {};

    final allTasks = _getAllTasks();

    for (final task in allTasks) {
      // Для задач с dueDate
      if (task.dueDate != null) {
        final date = DateTime(task.dueDate!.year, task.dueDate!.month, task.dueDate!.day);
        _tasksByDate.putIfAbsent(date, () => []).add(task);
      }

      // Для повторяющихся задач - добавляем на сегодня если нужно
      if (task.type.isRecurring && _isTaskDueToday(task)) {
        final today = DateTime.now();
        final date = DateTime(today.year, today.month, today.day);
        _tasksByDate.putIfAbsent(date, () => []).add(task);
      }
    }

    setState(() {});
  }

  // Получаем все задачи из всех проектов (включая подзадачи)
  List<Task> _getAllTasks() {
    final allTasks = <Task>[];

    for (final project in widget.projects) {
      allTasks.addAll(project.allTasks);
    }

    return allTasks;
  }

  // Проверяем, должна ли повторяющаяся задача быть сегодня
  bool _isTaskDueToday(Task task) {
    // TODO: Реализовать логику для повторяющихся задач
    // Пока просто показываем все повторяющиеся задачи
    return task.type.isRecurring;
  }

  // Получаем задачи для выбранной даты
  List<Task> _getTasksForSelectedDate() {
    final dateKey = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    return _tasksByDate[dateKey] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    final tasksForSelectedDate = _getTasksForSelectedDate();

    return Scaffold(
      appBar: AppBar(
        title: Text('Календарь'),
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
        ],
      ),
      body: Column(
        children: [
          // Календарь
          _buildCalendar(),
          // Список задач на выбранную дату
          Expanded(
            child: _buildTaskList(tasksForSelectedDate),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar() {
    return Card(
      margin: EdgeInsets.all(16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // Заголовок месяца и года
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(Icons.chevron_left),
                  onPressed: () {
                    setState(() {
                      _selectedDate = DateTime(_selectedDate.year, _selectedDate.month - 1);
                    });
                  },
                ),
                Text(
                  '${_getMonthName(_selectedDate.month)} ${_selectedDate.year}',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: Icon(Icons.chevron_right),
                  onPressed: () {
                    setState(() {
                      _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + 1);
                    });
                  },
                ),
              ],
            ),
            SizedBox(height: 16),
            // Сетка календаря
            _buildCalendarGrid(),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final firstDayOfMonth = DateTime(_selectedDate.year, _selectedDate.month, 1);
    final lastDayOfMonth = DateTime(_selectedDate.year, _selectedDate.month + 1, 0);
    final daysInMonth = lastDayOfMonth.day;

    // День недели первого дня месяца (0 - воскресенье, 1 - понедельник, etc.)
    final firstWeekday = firstDayOfMonth.weekday;

    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 1.0,
      ),
      itemCount: daysInMonth + firstWeekday - 1,
      itemBuilder: (context, index) {
        if (index < firstWeekday - 1) {
          // Пустые ячейки перед первым днем месяца
          return SizedBox.shrink();
        }

        final day = index - firstWeekday + 2;
        final currentDate = DateTime(_selectedDate.year, _selectedDate.month, day);
        final isSelected = _isSameDay(currentDate, _selectedDate);
        final hasTasks = _tasksByDate.containsKey(DateTime(currentDate.year, currentDate.month, currentDate.day));
        final isToday = _isSameDay(currentDate, DateTime.now());

        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedDate = currentDate;
            });
          },
          child: Container(
            margin: EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.blue
                  : isToday
                  ? Colors.blue.shade50
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isToday ? Colors.blue : Colors.transparent,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$day',
                  style: TextStyle(
                    fontSize: 16,
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
      },
    );
  }

  Widget _buildTaskList(List<Task> tasks) {
    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.task_outlined, size: 64, color: Colors.grey.shade300),
            SizedBox(height: 16),
            Text(
              'Нет задач на ${_selectedDate.day}.${_selectedDate.month}.${_selectedDate.year}',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
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
        return TaskListItem(
          task: task,
          nestingLevel: task.nestingLevel,
          onTap: () => _showTaskDetails(task),
          onComplete: () => _toggleTaskCompletion(task),
          onAddSubtask: task.canAddSubtask() ? () => _showAddSubtaskDialog(task) : null,
          onEdit: () => _showEditTaskDialog(task),
          onDelete: () => _deleteTask(task),
          isSelected: false,
        );
      },
    );
  }

  // === ОБРАБОТЧИКИ СОБЫТИЙ ===

  void _toggleTaskCompletion(Task task) {
    setState(() {
      final updatedTask = task.isCompleted
          ? _taskService.uncompleteTask(task)
          : _taskService.completeTask(task);

      // Находим и обновляем задачу в проекте
      for (final project in widget.projects) {
        final projectTask = project.getTaskById(task.id);
        if (projectTask != null) {
          // TODO: Обновить проект в репозитории
          break;
        }
      }

      _groupTasksByDate(); // Перегруппируем задачи
    });
  }

  void _showTaskDetails(Task task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(task.title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (task.description != null) ...[
                Text(task.description!),
                SizedBox(height: 16),
              ],
              _buildTaskInfoRow(Icons.assignment, 'Тип', task.type.displayName),
              _buildTaskInfoRow(Icons.flag, 'Приоритет', '${task.priority}'),
              if (task.dueDate != null)
                _buildTaskInfoRow(
                    Icons.calendar_today,
                    'Срок',
                    '${task.dueDate!.day}.${task.dueDate!.month}.${task.dueDate!.year}'
                ),
              _buildTaskInfoRow(Icons.timer, 'Оценка времени', '${task.estimatedMinutes} мин'),
              if (task.hasSubtasks)
                _buildTaskInfoRow(Icons.account_tree, 'Подзадачи', '${task.completedSubtasks}/${task.totalSubtasks}'),
            ],
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

  Widget _buildTaskInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade600),
          SizedBox(width: 8),
          Text('$label: ', style: TextStyle(fontWeight: FontWeight.w500)),
          Text(value),
        ],
      ),
    );
  }

  void _showAddSubtaskDialog(Task task) {
    // TODO: Реализовать диалог добавления подзадачи
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Добавление подзадачи для: ${task.title}')),
    );
  }

  void _showEditTaskDialog(Task task) {
    // TODO: Реализовать диалог редактирования
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Редактирование: ${task.title}')),
    );
  }

  void _deleteTask(Task task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Удалить задачу?'),
        content: Text('Задача "${task.title}" будет удалена${task.hasSubtasks ? ' вместе с подзадачами' : ''}.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Удалить задачу из проекта
              _groupTasksByDate();
            },
            child: Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // === ВСПОМОГАТЕЛЬНЫЕ МЕТОДЫ ===

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  String _getMonthName(int month) {
    const months = [
      'Январь', 'Февраль', 'Март', 'Апрель', 'Май', 'Июнь',
      'Июль', 'Август', 'Сентябрь', 'Октябрь', 'Ноябрь', 'Декабрь'
    ];
    return months[month - 1];
  }
}