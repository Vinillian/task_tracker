import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'package:provider/provider.dart';
import '../models/app_user.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import '../repositories/local_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../services/firestore_service.dart'; // ← ДОБАВИТЬ

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

          // ТЕСТОВАЯ КНОПКА ДЛЯ ОТЛАДКИ
          ListTile(
            leading: Icon(Icons.bug_report),
            title: Text('Тест экспорта'),
            onTap: () async {
              Navigator.pop(context);
              final localRepo = Provider.of<LocalRepository>(context, listen: false);
              try {
                final jsonString = await localRepo.exportToJson();
                print('✅ ЭКСПОРТ УСПЕШЕН:');
                print(jsonString);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('✅ Данные экспортированы (см. консоль)')),
                );
              } catch (e) {
                print('❌ ОШИБКА ЭКСПОРТА: $e');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Ошибка экспорта: $e')),
                );
              }
            },
          ),

          // ВЕБ-ВЕРСИЯ (работает в Chrome)
          if (kIsWeb) ...[
            ListTile(
              leading: Icon(Icons.upload),
              title: Text('Экспорт данных (Web)'),
              onTap: () async {
                Navigator.pop(context);
                final localRepo = Provider.of<LocalRepository>(context, listen: false);
                try {
                  final jsonString = await localRepo.exportToJson();
                  // Копируем в буфер обмена
                  await Clipboard.setData(ClipboardData(text: jsonString));

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('✅ Данные скопированы в буфер обмена')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Ошибка экспорта: $e')),
                  );
                }
              },
            ),

            ListTile(
              leading: Icon(Icons.download),
              title: Text('Импорт данных (Web)'),
              onTap: () async {
                Navigator.pop(context);
                final localRepo = Provider.of<LocalRepository>(context, listen: false);

                final jsonString = await _showJsonInputDialog(context);
                if (jsonString != null && jsonString.isNotEmpty) {
                  try {
                    final importedUser = await localRepo.importFromJson(jsonString);

                    // ✅ ОБНОВЛЯЕМ СОСТОЯНИЕ ПРИЛОЖЕНИЯ через Provider
                    // Вместо прямого доступа к состоянию, используем более надежный способ
                    final authService = Provider.of<AuthService>(context, listen: false);
                    final currentAuthUser = authService.currentUser;

                    if (currentAuthUser != null) {
                      // Сохраняем в Firestore и локально
                      final firestoreService = Provider.of<FirestoreService>(context, listen: false);
                      await firestoreService.saveUser(importedUser, currentAuthUser.uid);
                      await localRepo.saveUser(importedUser);

                      // Показываем сообщение об успехе
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('✅ Данные успешно импортированы')),
                      );

                      // Перезагружаем страницу для обновления UI
                      Navigator.pushReplacementNamed(context, '/');
                    }
                  } catch (e) {
                    print('❌ Ошибка импорта: $e');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Ошибка импорта: $e')),
                    );
                  }
                }
              },
            ),
          ],

          // МОБИЛЬНАЯ ВЕРСИЯ (скрыта в вебе)
          if (!kIsWeb) ...[
            ListTile(
              leading: Icon(Icons.upload),
              title: Text('Экспорт данных'),
              onTap: () async {
                Navigator.pop(context);
                final localRepo = Provider.of<LocalRepository>(context, listen: false);
                try {
                  final jsonString = await localRepo.exportToJson();
                  final fileName = 'task_tracker_export_${DateTime.now().millisecondsSinceEpoch}.json';

                  final result = await Share.shareXFiles([XFile.fromData(
                    Uint8List.fromList(utf8.encode(jsonString)),
                    name: fileName,
                    mimeType: 'application/json',
                  )]);

                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Ошибка экспорта: $e')),
                  );
                }
              },
            ),

            ListTile(
              leading: Icon(Icons.download),
              title: Text('Импорт данных (Web)'),
              onTap: () async {
                Navigator.pop(context); // Закрываем Drawer

                final jsonString = await _showJsonInputDialog(context);
                if (jsonString != null && jsonString.isNotEmpty) {
                  try {
                    final localRepo = Provider.of<LocalRepository>(context, listen: false);
                    await localRepo.importFromJson(jsonString);

                    // ✅ Простое сообщение - данные сохранены, нужно обновить
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('✅ Данные импортированы в локальное хранилище'),
                        duration: Duration(seconds: 3),
                      ),
                    );

                  } catch (e) {
                    print('❌ Ошибка импорта: $e');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Ошибка импорта: $e')),
                    );
                  }
                }
              },
            ),
          ],
        ],
      ),
    );
  }
}