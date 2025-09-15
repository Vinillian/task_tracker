import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../models/app_user.dart';
import '../repositories/local_repository.dart';
import '../services/firestore_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart'; // ← ДОБАВИТЬ для мобильного экспорта
import 'dart:convert' show utf8;

class DrawerScreen extends StatelessWidget {
  final String? userEmail;
  final AppUser? currentUser;

  const DrawerScreen({
    super.key,
    required this.userEmail,
    required this.currentUser,
  });

  Future<String?> _showJsonInputDialog(BuildContext context) async {
    final controller = TextEditingController();

    return await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Вставьте JSON данные'),
        content: TextField(
          controller: controller,
          maxLines: 10,
          decoration: InputDecoration(
            hintText: 'Вставьте сюда JSON данные...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text('Импортировать'),
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
            SnackBar(content: Text('✅ Данные успешно импортированы')),
          );

          // Просто закрываем drawer, данные обновятся автоматически
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
    Navigator.pop(context); // Закрываем drawer сразу

    try {
      final jsonString = await localRepo.exportToJson();

      if (kIsWeb) {
        // ВЕБ-ВЕРСИЯ - копируем в буфер обмена
        await Clipboard.setData(ClipboardData(text: jsonString));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ Данные скопированы в буфер обмена')),
        );
      } else {
        // МОБИЛЬНАЯ ВЕРСИЯ - сохраняем в файл и делимся
        final fileName = 'task_tracker_export_${DateTime.now().millisecondsSinceEpoch}.json';

        // Создаем временный файл и делимся им
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  currentUser?.username ?? userEmail ?? 'Гость',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text(
                  userEmail ?? '',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                SizedBox(height: 8),
                Text(
                  'Task Tracker',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ],
            ),
          ),

          // КНОПКА ВЫХОДА
          ListTile(
            leading: Icon(Icons.logout),
            title: Text('Выйти'),
            onTap: () async {
              final authService = Provider.of<AuthService>(context, listen: false);
              await authService.signOut();
              Navigator.pop(context);
            },
          ),

          // ЭКСПОРТ ДАННЫХ
          ListTile(
            leading: Icon(Icons.upload),
            title: Text('Экспорт данных'),
            onTap: () => _exportData(context),
          ),

          // ИМПОРТ ДАННЫХ
          ListTile(
            leading: Icon(Icons.download),
            title: Text('Импорт данных'),
            onTap: () => _importFromText(context),
          ),
        ],
      ),
    );
  }
}