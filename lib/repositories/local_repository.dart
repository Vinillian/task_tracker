import 'dart:convert'; // ← ДОБАВИТЬ для jsonEncode/jsonDecode
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:hive_flutter/hive_flutter.dart'; // ← ДОБАВИТЬ для initFlutter
import 'package:cloud_firestore/cloud_firestore.dart'; // ← ДОБАВИТЬ
import '../models/app_user.dart';
import '../models/project.dart';
import '../models/task.dart';
import '../models/subtask.dart';
import '../models/progress_history.dart';

class LocalRepository {
  static const String _userBoxName = 'userData';
  static const String _settingsBoxName = 'settings';

  late Box<AppUser> _userBox;
  late Box<dynamic> _settingsBox;
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    try {
      // Инициализация для Web и мобильных
      if (kIsWeb) {
        // Для Web используем стандартную инициализацию
        await Hive.initFlutter();
      } else {
        final appDocDir = await getApplicationDocumentsDirectory();
        Hive.init(appDocDir.path);
      }

      // Регистрируем адаптеры
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(AppUserAdapter());
      }
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(ProjectAdapter());
      }
      if (!Hive.isAdapterRegistered(2)) {
        Hive.registerAdapter(TaskAdapter());
      }
      if (!Hive.isAdapterRegistered(3)) {
        Hive.registerAdapter(SubtaskAdapter());
      }
      if (!Hive.isAdapterRegistered(4)) {
        Hive.registerAdapter(ProgressHistoryAdapter());
      }

      // Открываем боксы
      _userBox = await Hive.openBox<AppUser>(_userBoxName);
      _settingsBox = await Hive.openBox(_settingsBoxName);

      _isInitialized = true;
      print('✅ Hive initialized successfully');
    } catch (e) {
      print('❌ Error initializing Hive: $e');
      rethrow;
    }
  }


  // Сохранение пользователя
  Future<void> saveUser(AppUser user) async {
    await _userBox.put('currentUser', user);
  }

  // Загрузка пользователя
  AppUser? loadUser() {
    return _userBox.get('currentUser');
  }

  // Экспорт в JSON
  Future<String> exportToJson() async {
    final user = loadUser();
    if (user == null) {
      throw Exception('No user data to export');
    }

    // Конвертируем данные, заменяя Timestamp на DateTime
    final jsonMap = _convertToJsonCompatible(user.toFirestore());

    // ✅ КРАСИВОЕ ФОРМАТИРОВАНИЕ JSON
    final jsonEncoder = JsonEncoder.withIndent('  ');
    return jsonEncoder.convert(jsonMap);
  }

  // Вспомогательный метод для конвертации Timestamp -> DateTime
  Map<String, dynamic> _convertToJsonCompatible(Map<String, dynamic> data) {
    final result = Map<String, dynamic>.from(data);

    result.forEach((key, value) {
      if (value is Timestamp) {
        result[key] = value.toDate().toIso8601String();
      } else if (value is Map<String, dynamic>) {
        result[key] = _convertToJsonCompatible(value);
      } else if (value is List) {
        result[key] = value.map((item) {
          if (item is Timestamp) {
            return item.toDate().toIso8601String();
          } else if (item is Map<String, dynamic>) {
            return _convertToJsonCompatible(item);
          }
          return item;
        }).toList();
      }
    });

    return result;
  }

  // Импорт из JSON
  Future<AppUser> importFromJson(String jsonString) async {
    try {
      // ✅ УБИРАЕМ ЛИШНИЕ ПРОБЕЛЫ И ПЕРЕВОДЫ СТРОК
      final cleanedJsonString = jsonString.trim();

      final jsonMap = jsonDecode(cleanedJsonString) as Map<String, dynamic>;

      // ✅ ПРОВЕРЯЕМ ОБЯЗАТЕЛЬНЫЕ ПОЛЯ
      if (jsonMap['username'] == null || jsonMap['email'] == null) {
        throw Exception('Invalid JSON: missing required fields (username, email)');
      }

      final user = AppUser.fromFirestore(jsonMap);
      await saveUser(user);

      print('✅ Импорт успешен: ${user.username}, проектов: ${user.projects.length}');
      return user;

    } catch (e) {
      print('❌ Ошибка импорта JSON: $e');
      print('❌ JSON данные: ${jsonString.substring(0, 200)}...');
      throw Exception('Invalid JSON format: $e');
    }
  }

  // Очистка данных
  Future<void> clearAllData() async {
    await _userBox.clear();
    await _settingsBox.clear();
  }

  // Закрытие боксов
  Future<void> close() async {
    await _userBox.close();
    await _settingsBox.close();
  }
}