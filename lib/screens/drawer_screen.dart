// drawer_screen.dart
import 'package:flutter/material.dart';
import '../models/user.dart';

class DrawerScreen extends StatelessWidget {
  final User? currentUser;
  final Function(User?) onUserChanged;
  final Function() onAddProject;

  const DrawerScreen({
    super.key,
    required this.currentUser,
    required this.onUserChanged,
    required this.onAddProject,
  });

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

  // Метод для создания пользователя:
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
                onUserChanged(User(  // ← ИСПРАВЛЕНО ЗДЕСЬ
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
              // TODO: Переход к настройкам
              Navigator.pop(context);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.exit_to_app),
            title: const Text('Выйти'),
            onTap: () {
              // TODO: Реализовать выход
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.bar_chart),
            title: const Text('Статистика'),
            onTap: () {
              Navigator.pop(context);
              // TODO: Переход к статистике
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
        ],
      ),
    );
  }
}