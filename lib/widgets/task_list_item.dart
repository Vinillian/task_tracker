import 'package:flutter/material.dart';
import '../models/task.dart';
import 'nesting_indicator.dart';

class TaskListItem extends StatelessWidget {
  final Task task;
  final int nestingLevel;
  final VoidCallback onTap;
  final VoidCallback onComplete;
  final VoidCallback onAddSubtask;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool isSelected;

  const TaskListItem({
    Key? key,
    required this.task,
    this.nestingLevel = 0,
    required this.onTap,
    required this.onComplete,
    required this.onAddSubtask,
    required this.onEdit,
    required this.onDelete,
    this.isSelected = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(
        left: nestingLevel * 16.0,
        right: 8.0,
        top: 4.0,
        bottom: 4.0,
      ),
      elevation: 2,
      color: isSelected ? Colors.blue.shade50 : Colors.white,
      child: ListTile(
        leading: NestingIndicator(level: nestingLevel),
        title: Row(
          children: [
            Expanded(
              child: Text(
                task.title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                  color: task.isCompleted ? Colors.grey : Colors.black,
                ),
              ),
            ),
            if (task.hasSubtasks)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${task.completedSubtasks}/${task.totalSubtasks}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade800,
                  ),
                ),
              ),
          ],
        ),
        subtitle: task.description != null && task.description!.isNotEmpty
            ? Text(
          task.description!,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontStyle: FontStyle.italic,
          ),
        )
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Кнопка добавления подзадачи
            if (task.canAddSubtask())
              IconButton(
                icon: Icon(Icons.add, size: 20),
                onPressed: onAddSubtask,
                tooltip: 'Добавить подзадачу',
              ),
            // Кнопка завершения
            IconButton(
              icon: Icon(
                task.isCompleted ? Icons.undo : Icons.check_circle,
                color: task.isCompleted ? Colors.orange : Colors.green,
                size: 20,
              ),
              onPressed: onComplete,
              tooltip: task.isCompleted ? 'Отменить выполнение' : 'Выполнить',
            ),
          ],
        ),
        onTap: onTap,
        onLongPress: () {
          _showContextMenu(context);
        },
      ),
    );
  }

  void _showContextMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.edit),
                title: Text('Редактировать'),
                onTap: () {
                  Navigator.pop(context);
                  onEdit();
                },
              ),
              if (task.canAddSubtask())
                ListTile(
                  leading: Icon(Icons.add),
                  title: Text('Добавить подзадачу'),
                  onTap: () {
                    Navigator.pop(context);
                    onAddSubtask();
                  },
                ),
              ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text('Удалить', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmation(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Удалить задачу?'),
        content: Text('Задача "${task.title}" будет удалена${task.hasSubtasks ? ' вместе со всеми подзадачами' : ''}.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onDelete();
            },
            child: Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}