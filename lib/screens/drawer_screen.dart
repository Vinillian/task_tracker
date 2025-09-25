import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../models/app_user.dart';
import '../repositories/local_repository.dart';
import '../services/firestore_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:convert' show utf8;
import 'planning_calendar_screen.dart';

class DrawerScreen extends StatelessWidget {
  final String? userEmail;
  final AppUser? currentUser;
  final TabController tabController;
  final Function(Map<String, dynamic>) onItemCompletedFromPlanning;

  const DrawerScreen({
    super.key,
    required this.userEmail,
    required this.currentUser,
    required this.tabController,
    required this.onItemCompletedFromPlanning,
  });

  Future<String?> _showJsonInputDialog(BuildContext context) async {
    final controller = TextEditingController();

    return await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Вставьте JSON данные'),
        content: TextField(
          controller: controller,
          maxLines: 10,
          decoration: const InputDecoration(
            hintText: 'Вставьте сюда JSON данные...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Импортировать'),
          ),
        ],
      ),
    );
  }

  Future<void> _importFromText(BuildContext context) async {
    final jsonString = await _showJsonInputDialog(context);
    if (jsonString != null && jsonString.isNotEmpty) {
      try {
        final localRepo = Provider.of<LocalRepository>(context, listen: false);
        final importedUser = await localRepo.importFromJson(jsonString);

        final authService = Provider.of<AuthService>(context, listen: false);
        final currentAuthUser = authService.currentUser;

        if (currentAuthUser != null) {
          final firestoreService = Provider.of<FirestoreService>(context, listen: false);
          await firestoreService.saveUser(importedUser, currentAuthUser.uid);
          await localRepo.saveUser(importedUser);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Данные успешно импортированы')),
          );

          Navigator.pop(context);
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка импорта: $e')),
        );
      }
    }
  }

  Future<void> _exportData(BuildContext context) async {
    final localRepo = Provider.of<LocalRepository>(context, listen: false);
    Navigator.pop(context);

    try {
      final jsonString = await localRepo.exportToJson();

      if (kIsWeb) {
        await Clipboard.setData(ClipboardData(text: jsonString));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Данные скопированы в буфер обмена')),
        );
      } else {
        final fileName = 'task_tracker_export_${DateTime.now().millisecondsSinceEpoch}.json';

        await Share.shareXFiles([
          XFile.fromData(
            Uint8List.fromList(utf8.encode(jsonString)),
            name: fileName,
            mimeType: 'application/json',
          )
        ]);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка экспорта: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.blue,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  currentUser?.username ?? userEmail ?? 'Гость',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  userEmail ?? '',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Task Tracker',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ],
            ),
          ),

          // СУЩЕСТВУЮЩИЕ ПУНКТЫ МЕНЮ
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Выйти'),
            onTap: () async {
              final authService = Provider.of<AuthService>(context, listen: false);
              await authService.signOut();
              Navigator.pop(context);
            },
          ),

          ListTile(
            leading: const Icon(Icons.upload),
            title: const Text('Экспорт данных'),
            onTap: () => _exportData(context),
          ),

          ListTile(
            leading: const Icon(Icons.download),
            title: const Text('Импорт данных'),
            onTap: () => _importFromText(context),
          ),

          const Divider(),

          // НАВИГАЦИЯ ПО ОСНОВНЫМ ВКЛАДКАМ
          ListTile(
            leading: const Icon(Icons.list),
            title: const Text('Проекты'),
            onTap: () {
              Navigator.pop(context);
              tabController.animateTo(0);
            },
          ),

          ListTile(
            leading: const Icon(Icons.bar_chart),
            title: const Text('Статистика'),
            onTap: () {
              Navigator.pop(context);
              tabController.animateTo(1);
            },
          ),

          ListTile(
            leading: const Icon(Icons.analytics),
            title: const Text('Аналитика задач'),
            onTap: () {
              Navigator.pop(context);
              tabController.animateTo(2); // ← НОВЫЙ ИНДЕКС ДЛЯ АНАЛИТИКИ
            },
          ),

          ListTile(
            leading: const Icon(Icons.calendar_month),
            title: const Text('Календарь'),
            onTap: () {
              Navigator.pop(context);
              tabController.animateTo(3);
            },
          ),

          const Divider(),

          // ДОПОЛНИТЕЛЬНЫЕ ЭКРАНЫ
          ListTile(
            leading: const Icon(Icons.calendar_today),
            title: const Text('Планирование'),
            subtitle: const Text('Список запланированных задач'),
            onTap: () {
              Navigator.pop(context);

              // Открываем экран планирования как отдельную страницу
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PlanningCalendarScreen(
                    currentUser: currentUser,
                    onItemCompleted: onItemCompletedFromPlanning,
                  ),
                ),
              );
            },
          ),

          // Можно добавить другие дополнительные экраны здесь
          /*
          ListTile(
            leading: Icon(Icons.settings),
            title: Text('Настройки'),
            onTap: () {
              Navigator.pop(context);
              // Открыть экран настроек
            },
          ),
          */
        ],
      ),
    );
  }
}