// drawer_screen.dart
import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/storage_service.dart';
import 'backup_screen.dart';

class DrawerScreen extends StatelessWidget {
  final User? currentUser;
  final Function(User?) onUserChanged;
  final Function() onAddProject;
  final StorageService storageService;
  final List<User> users;
  final Function(List<User>) onDataImported;

  const DrawerScreen({
    super.key,
    required this.currentUser,
    required this.onUserChanged,
    required this.onAddProject,
    required this.storageService,
    required this.users,
    required this.onDataImported,
  });

  void _showBackupScreen(BuildContext context) {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BackupScreen(
          storageService: storageService,
          users: users,
          onDataImported: onDataImported,
        ),
      ),
    );
  }

  void _showStatistics(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Статистика'),
        content: const Text('Здесь будет статистика. Вернем позже!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showCreateUserDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Новый пользователь'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Имя пользователя'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                onUserChanged(User(
                  name: controller.text,
                  projects: [],
                  progressHistory: [],
                ));
                Navigator.pop(context);
              }
            },
            child: const Text('Создать'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
            ),
            child: Text(
              currentUser?.name ?? 'Пользователь',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.add),
            title: const Text('Создать проект'),
            onTap: () {
              Navigator.pop(context);
              onAddProject();
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Настройки'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.exit_to_app),
            title: const Text('Выйти'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.bar_chart),
            title: const Text('Статистика'),
            onTap: () {
              Navigator.pop(context);
              _showStatistics(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.person_add),
            title: const Text('Новый пользователь'),
            onTap: () {
              Navigator.pop(context);
              _showCreateUserDialog(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.backup),
            title: const Text('Резервное копирование'),
            onTap: () => _showBackupScreen(context),
          ),
        ],
      ),
    );
  }
}