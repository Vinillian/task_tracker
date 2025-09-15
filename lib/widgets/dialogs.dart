import 'package:flutter/material.dart';

class Dialogs {
  static Future<String?> showTextInputDialog({
    required BuildContext context,
    required String title,
    String? initialValue,
  }) async {
    final controller = TextEditingController(text: initialValue ?? '');
    return await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          autofocus: true,
          controller: controller,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  static Future<bool> showConfirmDialog({
    required BuildContext context,
    required String title,
    required String message,
  }) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Нет'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Да'),
          ),
        ],
      ),
    ) ?? false;
  }

  // НОВЫЙ: Диалог для ввода чисел
  static Future<int?> showNumberInputDialog({
    required BuildContext context,
    required String title,
    String? message,
    String? initialValue,
  }) async {
    final controller = TextEditingController(text: initialValue ?? '');

    return await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(message),
              ),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Количество шагов',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              final steps = int.tryParse(controller.text) ?? 0;
              Navigator.of(context).pop(steps > 0 ? steps : null);
            },
            child: const Text('Добавить'),
          ),
        ],
      ),
    );
  }
}