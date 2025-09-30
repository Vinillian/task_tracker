// widgets/add_project_dialog.dart
import 'package:flutter/material.dart';

class AddProjectDialog extends StatefulWidget {
  final Function(String, String) onProjectCreated;

  const AddProjectDialog({
    super.key,
    required this.onProjectCreated,
  });

  @override
  State<AddProjectDialog> createState() => _AddProjectDialogState();
}

class _AddProjectDialogState extends State<AddProjectDialog> {
  String _name = '';
  String _description = '';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Создать новый проект'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            decoration: const InputDecoration(
              labelText: 'Название проекта*',
              hintText: 'Например: Учеба',
            ),
            onChanged: (value) => _name = value,
          ),
          const SizedBox(height: 16),
          TextField(
            decoration: const InputDecoration(
              labelText: 'Описание',
              hintText: 'Краткое описание проекта',
            ),
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
              widget.onProjectCreated(_name, _description);
              Navigator.pop(context);
            }
          },
          child: const Text('Создать'),
        ),
      ],
    );
  }
}