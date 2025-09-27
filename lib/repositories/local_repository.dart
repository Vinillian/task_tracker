import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user.dart';
import '../models/project.dart';
import '../models/task.dart';
import '../models/progress_history.dart';
import '../models/step.dart' as custom_step;
import '../models/stage.dart';
import '../models/recurrence_completion.dart';
import '../models/recurrence.dart';


class LocalRepository {
  static const String _userBoxName = 'userData';
  static const String _settingsBoxName = 'settings';

  late Box<AppUser> _userBox;
  late Box<dynamic> _settingsBox;
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    try {
      print('🔄 Инициализация Hive...');

      // Инициализация для Web и мобильных
      if (kIsWeb) {
        await Hive.initFlutter();
      } else {
        final appDocDir = await getApplicationDocumentsDirectory();
        Hive.init(appDocDir.path);
      }

      // Регистрируем адаптеры
      _registerAdapters();

      // Пробуем открыть боксы с обработкой ошибок
      try {
        _userBox = await Hive.openBox<AppUser>(_userBoxName);
        _settingsBox = await Hive.openBox(_settingsBoxName);
        print('✅ Боксы успешно открыты');
      } catch (e) {
        print('⚠️ Ошибка открытия боксов: $e. Очищаем поврежденные данные...');
        await clearCorruptedData();
      }

      _isInitialized = true;
      print('✅ Hive initialized successfully');
    } catch (e, stack) {
      print('❌ Critical error initializing Hive: $e');
      print('Stack trace: $stack');

      // Пытаемся восстановиться
      await Future.delayed(Duration(seconds: 1));
      await _tryRecovery();
    }
  }

  void _registerAdapters() {
    try {
      print('🔄 Регистрация адаптеров Hive...');

      // Закрываем все боксы перед перерегистрацией
      Hive.close();

      // Регистрируем адаптеры в правильном порядке
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
        Hive.registerAdapter(custom_step.StepAdapter());
      }
      if (!Hive.isAdapterRegistered(4)) {
        Hive.registerAdapter(ProgressHistoryAdapter());
      }
      if (!Hive.isAdapterRegistered(5)) {
        Hive.registerAdapter(StageAdapter());
      }

      // ВАЖНО: Сначала регистрируем enum, потом основной класс
      if (!Hive.isAdapterRegistered(7)) {
        Hive.registerAdapter(RecurrenceTypeAdapter());
      }
      if (!Hive.isAdapterRegistered(6)) {
        Hive.registerAdapter(RecurrenceAdapter());
      }
      if (!Hive.isAdapterRegistered(8)) {
        Hive.registerAdapter(RecurrenceCompletionAdapter());
      }

      print('✅ Все адаптеры зарегистрированы');
    } catch (e) {
      print('❌ Ошибка регистрации адаптеров: $e');
      // Пробуем зарегистрировать только основные адаптеры
      _registerBasicAdapters();
    }
  }

  void _registerBasicAdapters() {
    try {
      print('🔄 Регистрация основных адаптеров...');

      Hive.registerAdapter(AppUserAdapter());
      Hive.registerAdapter(ProjectAdapter());
      Hive.registerAdapter(TaskAdapter());
      Hive.registerAdapter(custom_step.StepAdapter());
      Hive.registerAdapter(ProgressHistoryAdapter());
      Hive.registerAdapter(StageAdapter());

      print('✅ Основные адаптеры зарегистрированы');
    } catch (e) {
      print('❌ Ошибка регистрации основных адаптеров: $e');
    }
  }

  // Сохранение пользователя (с проверкой на recurring задачи)
  Future<void> saveUser(AppUser user) async {
    try {
      // Проверяем, есть ли recurring задачи
      final hasRecurringTasks = user.projects.any((project) =>
          project.tasks.any((task) => task.recurrence != null));

      if (hasRecurringTasks) {
        print('⚠️ Пропускаем сохранение в Hive (recurring задачи)');
        return;
      }

      await _userBox.put('currentUser', user);
      print('✅ Пользователь сохранен в Hive: ${user.username}');
    } catch (e) {
      print('❌ Ошибка сохранения в Hive: $e');
      rethrow;
    }
  }

  Future<void> _tryRecovery() async {
    try {
      print('🔄 Попытка восстановления...');
      await Hive.close();

      if (kIsWeb) {
        await Hive.initFlutter();
      } else {
        final appDocDir = await getApplicationDocumentsDirectory();
        Hive.init(appDocDir.path);
      }

      _registerAdapters();

      // Пробуем открыть снова
      _userBox = await Hive.openBox<AppUser>(_userBoxName);
      _settingsBox = await Hive.openBox(_settingsBoxName);

      _isInitialized = true;
      print('✅ Восстановление успешно');
    } catch (e) {
      print('❌ Восстановление не удалось: $e');
      // Создаем пустые боксы в памяти как запасной вариант
      try {
        _userBox = await Hive.openBox<AppUser>('userData_memory');
        _settingsBox = await Hive.openBox('settings_memory');
        _isInitialized = true;
        print('✅ Созданы резервные боксы в памяти');
      } catch (e) {
        print('❌ Критическая ошибка: $e');
        rethrow;
      }
    }
  }

  Future<void> clearCorruptedData() async {
    try {
      print('🔄 Очистка поврежденных данных...');

      // Закрываем боксы если они открыты
      try {
        await _userBox.close();
        await _settingsBox.close();
      } catch (e) {
        print('⚠️ Ошибка закрытия боксов: $e');
      }

      // Удаляем файлы данных (только для мобильных, не для Web)
      if (!kIsWeb) {
        try {
          final appDocDir = await getApplicationDocumentsDirectory();
          final hivePath = appDocDir.path;

          // Удаляем файлы Hive простым способом
          final hiveFiles = [
            '$hivePath/userData.hive',
            '$hivePath/settings.hive',
            '$hivePath/userData.lock',
            '$hivePath/settings.lock',
          ];

          for (final filePath in hiveFiles) {
            final file = File(filePath);
            if (await file.exists()) {
              await file.delete();
              print('✅ Удален $filePath');
            }
          }
        } catch (e) {
          print('⚠️ Ошибка удаления файлов: $e');
        }
      }

      // Переоткрываем боксы
      _userBox = await Hive.openBox<AppUser>(_userBoxName);
      _settingsBox = await Hive.openBox(_settingsBoxName);

      print('✅ Поврежденные данные очищены');
    } catch (e) {
      print('❌ Ошибка очистки данных: $e');
      rethrow;
    }
  }

  // Загрузка пользователя
  AppUser? loadUser() {
    try {
      return _userBox.get('currentUser');
    } catch (e) {
      print('❌ Ошибка загрузки пользователя: $e');
      return null;
    }
  }

  // Экспорт в JSON
  Future<String> exportToJson() async {
    final user = loadUser();
    if (user == null) {
      throw Exception('No user data to export');
    }

    final jsonMap = _convertToJsonCompatible(user.toFirestore());
    final jsonEncoder = JsonEncoder.withIndent('  ');
    return jsonEncoder.convert(jsonMap);
  }

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

      if (!cleanedJsonString.startsWith('{') || !cleanedJsonString.endsWith('}')) {
        throw Exception('Неверный формат JSON файла');
      }

      final jsonMap = jsonDecode(cleanedJsonString) as Map<String, dynamic>;

      if (jsonMap['username'] == null) {
        throw Exception('Неверный формат данных: отсутствует поле username');
      }
      if (jsonMap['email'] == null) {
        throw Exception('Неверный формат данных: отсутствует поле email');
      }

      final user = AppUser.fromFirestore(jsonMap);
      await saveUser(user);

      print('✅ Импорт успешен: ${user.username}, проектов: ${user.projects.length}');
      return user;

    } on FormatException catch (e) {
      throw Exception('Неверный формат JSON: $e');
    } catch (e) {
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

  // Проверка и восстановление данных
  Future<bool> checkAndRecoverData() async {
    try {
      final user = loadUser();
      if (user == null || user.projects.isEmpty) {
        print('⚠️ Данные пользователя отсутствуют или пусты');

        // Проверяем есть ли резервная копия
        final backup = await _checkForBackup();
        if (backup != null) {
          print('✅ Найдена резервная копия, восстанавливаем...');
          await saveUser(backup);
          return true;
        }
        return false;
      }
      return true;
    } catch (e) {
      print('❌ Ошибка проверки данных: $e');
      return false;
    }
  }

  Future<AppUser?> _checkForBackup() async {
    try {
      // Проверяем, инициализирован ли Hive
      if (!Hive.isBoxOpen('userData') && !Hive.isAdapterRegistered(0)) {
        print('⚠️ Hive не инициализирован, пропускаем поиск резервных копий');
        return null;
      }

      // Для Web не ищем файловые резервные копии
      if (kIsWeb) {
        print('⚠️ Для Web поиск файловых резервных копий не поддерживается');
        return null;
      }

      // Для мобильных устройств ищем резервные копии
      try {
        final appDocDir = await getApplicationDocumentsDirectory();
        final hiveDir = Directory(appDocDir.path);

        if (!await hiveDir.exists()) {
          print('⚠️ Директория Hive не существует');
          return null;
        }

        final files = await hiveDir.list().toList();
        final boxNames = files
            .where((file) => file.path.endsWith('.hive'))
            .map((file) => file.uri.pathSegments.last.replaceAll('.hive', ''))
            .toList();

        print('🔍 Доступные боксы: $boxNames');

        for (final boxName in boxNames) {
          if (boxName.contains('backup') || boxName.contains('user')) {
            print('🔍 Проверяем бокс: $boxName');
            try {
              final box = await Hive.openBox(boxName);
              final data = box.get('userBackup');
              if (data != null && data is AppUser) {
                print('✅ Найдена резервная копия в боксе $boxName');
                await box.close();
                return data;
              }
              await box.close();
            } catch (e) {
              print('❌ Ошибка доступа к боксу $boxName: $e');
            }
          }
        }
      } catch (e) {
        print('❌ Ошибка поиска файловых резервных копий: $e');
      }
    } catch (e) {
      print('❌ Ошибка поиска резервной копии: $e');
    }
    return null;
  }
}