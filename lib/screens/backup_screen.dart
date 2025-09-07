import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../models/user.dart';

class BackupScreen extends StatelessWidget {
  final StorageService storageService;
  final List<User> users;
  final Function(List<User>) onDataImported;

  const BackupScreen({
    super.key,
    required this.storageService,
    required this.users,
    required this.onDataImported,
  });

  Future<void> _exportData(BuildContext context) async {
    try {
      final jsonString = await storageService.exportData(users);

      // Показываем данные в диалоге для копирования
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Экспорт данных'),
          content: SelectableText(jsonString),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Закрыть'),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _importData(BuildContext context) async {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Импорт данных'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Вставьте JSON данные для импорта',
          ),
          maxLines: 5,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                final importedUsers = await storageService.importData(controller.text);

                if (importedUsers.isNotEmpty) {
                  onDataImported(importedUsers);
                  Navigator.pop(context);
                  Navigator.pop(context); // Закрываем backup screen

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Данные успешно импортированы!'),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Ошибка: неверный формат данных'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Импортировать'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Резервное копирование'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => _exportData(context),
              child: const Text('Экспорт данных'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _importData(context),
              child: const Text('Импорт данных'),
            ),
            const SizedBox(height: 20),
            const Text(
              'Данные автоматически сохраняются\nпри каждом изменении',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}