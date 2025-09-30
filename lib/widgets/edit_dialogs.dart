// widgets/edit_dialogs.dart
import 'package:flutter/material.dart';
import '../models/project.dart';
import '../models/task.dart';

class EditProjectDialog extends StatefulWidget {
  final Project project;
  final Function(String, String) onProjectUpdated;

  const EditProjectDialog({
    super.key,
    required this.project,
    required this.onProjectUpdated,
  });

  @override
  State<EditProjectDialog> createState() => _EditProjectDialogState();
}

class _EditProjectDialogState extends State<EditProjectDialog> {
  late String _name;
  late String _description;

  @override
  void initState() {
    super.initState();
    _name = widget.project.name;
    _description = widget.project.description;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Редактировать проект'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            decoration: const InputDecoration(
              labelText: 'Название проекта*',
              hintText: 'Например: Учеба',
            ),
            controller: TextEditingController(text: widget.project.name),
            onChanged: (value) => _name = value,
          ),
          const SizedBox(height: 16),
          TextField(
            decoration: const InputDecoration(
              labelText: 'Описание',
              hintText: 'Краткое описание проекта',
            ),
            controller: TextEditingController(text: widget.project.description),
            onChanged: (value) => _description = value,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Отмена'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_name.isNotEmpty) {
              widget.onProjectUpdated(_name, _description);
              Navigator.pop(context);
            }
          },
          child: const Text('Сохранить'),
        ),
      ],
    );
  }
}

class EditTaskDialog extends StatefulWidget {
  final Task task;
  final Function(String, String) onTaskUpdated;

  const EditTaskDialog({
    super.key,
    required this.task,
    required this.onTaskUpdated,
  });

  @override
  State<EditTaskDialog> createState() => _EditTaskDialogState();
}

class _EditTaskDialogState extends State<EditTaskDialog> {
  late String _title;
  late String _description;

  @override
  void initState() {
    super.initState();
    _title = widget.task.title;
    _description = widget.task.description;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Редактировать задачу'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            decoration: const InputDecoration(
              labelText: 'Название задачи*',
              hintText: 'Например: Сделать домашку',
            ),
            controller: TextEditingController(text: widget.task.title),
            onChanged: (value) => _title = value,
          ),
          const SizedBox(height: 16),
          TextField(
            decoration: const InputDecoration(
              labelText: 'Описание задачи',
              hintText: 'Подробное описание',
            ),
            controller: TextEditingController(text: widget.task.description),
            onChanged: (value) => _description = value,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Отмена'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_title.isNotEmpty) {
              widget.onTaskUpdated(_title, _description);
              Navigator.pop(context);
            }
          },
          child: const Text('Сохранить'),
        ),
      ],
    );
  }
}