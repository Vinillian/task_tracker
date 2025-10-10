// utils/storage_helper.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'logger.dart';

class StorageHelper {
  static const String _projectsKey = 'saved_projects';

  static Future<bool> saveProjects(List<Map<String, dynamic>> projects) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(projects);
      final success = await prefs.setString(_projectsKey, jsonString);

      Logger.debug('Сохраняем данные: ${projects.length} проектов');
      Logger.debug('Ключ: $_projectsKey');
      Logger.debug('Успех сохранения: $success');

      final saved = prefs.getString(_projectsKey);
      Logger.debug('Проверка сохраненных данных: ${saved != null ? "ДАННЫЕ ЕСТЬ" : "ДАННЫХ НЕТ"}');

      return success;
    } catch (e) {
      Logger.error('Ошибка сохранения проектов', e);
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> loadProjects() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_projectsKey);

      Logger.debug('Загружаем данные по ключу: $_projectsKey');

      if (jsonString != null && jsonString.isNotEmpty) {
        final List<dynamic> jsonList = jsonDecode(jsonString);
        Logger.info('Загружено ${jsonList.length} проектов');
        return jsonList.cast<Map<String, dynamic>>();
      } else {
        Logger.debug('Нет сохраненных данных');
      }
    } catch (e) {
      Logger.error('Ошибка загрузки проектов', e);
    }

    return [];
  }

  static Future<void> clearData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_projectsKey);
      Logger.info('Данные очищены');
    } catch (e) {
      Logger.error('Ошибка очистки данных', e);
    }
  }

  static Future<void> debugStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      Logger.debug('Все ключи в хранилище: $keys');

      for (final key in keys) {
        final value = prefs.getString(key);
        Logger.debug('   $key: ${value?.substring(0, value.length > 100 ? 100 : value.length)}');
      }
    } catch (e) {
      Logger.error('Ошибка отладки хранилища', e);
    }
  }
}