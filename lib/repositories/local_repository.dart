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
    print('🔄 Начало импорта JSON, длина: ${jsonString.length} символов');

    try {
      final cleanedJsonString = jsonString.trim();
      print('✅ JSON очищен, длина: ${cleanedJsonString.length} символов');

      // Логируем начало строки для диагностики
      if (cleanedJsonString.length > 100) {
        print('📝 Начало JSON: ${cleanedJsonString.substring(0, 100)}...');
      } else {
        print('📝 Весь JSON: $cleanedJsonString');
      }

      // Проверяем, что это валидный JSON
      if (!cleanedJsonString.startsWith('{') || !cleanedJsonString.endsWith('}')) {
        print('❌ Неверный формат JSON: должен начинаться с { и заканчиваться }');
        throw Exception('Неверный формат JSON файла');
      }

      final jsonMap = jsonDecode(cleanedJsonString) as Map<String, dynamic>;
      print('✅ JSON успешно распарсен');

      // ✅ ПРОВЕРЯЕМ ОБЯЗАТЕЛЬНЫЕ ПОЛЯ с логированием
      if (jsonMap['username'] == null) {
        print('❌ Отсутствует обязательное поле: username');
        throw Exception('Неверный формат данных: отсутствует поле username');
      }
      if (jsonMap['email'] == null) {
        print('❌ Отсутствует обязательное поле: email');
        throw Exception('Неверный формат данных: отсутствует поле email');
      }
      if (jsonMap['projects'] == null) {
        print('❌ Отсутствует обязательное поле: projects');
        throw Exception('Неверный формат данных: отсутствует поле projects');
      }

      print('📊 Загружаем данные пользователя: ${jsonMap['username']}');
      print('📧 Email: ${jsonMap['email']}');
      print('📦 Проектов: ${jsonMap['projects'] is List ? (jsonMap['projects'] as List).length : 'неверный формат'}');

      final user = AppUser.fromFirestore(jsonMap);
      await saveUser(user);

      print('✅ Импорт успешен: ${user.username}, проектов: ${user.projects.length}');
      print('📈 Записей в истории: ${user.progressHistory.length}');

      return user;

      // Исправляем обработку ошибок в importFromJson
    } on FormatException catch (e) {
      print('❌ Ошибка формата JSON: $e');
      // Убираем e.stackTrace, так как его нет в FormatException
      throw Exception('Неверный формат JSON: $e');
    } catch (e) {
      print('❌ Неожиданная ошибка импорта JSON: $e');
      // Для общего исключения можно использовать stackTrace если нужно
      throw Exception('Ошибка импорта: $e');
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