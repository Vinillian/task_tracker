// utils/storage_helper.dart - ОБНОВИМ для лучшей диагностики
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class StorageHelper {
  static const String _projectsKey = 'saved_projects';

  static Future<bool> saveProjects(List<Map<String, dynamic>> projects) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(projects);
      final success = await prefs.setString(_projectsKey, jsonString);

      print('💾 Сохраняем данные: ${projects.length} проектов');
      print('📝 Ключ: $_projectsKey');
      print('✅ Успех сохранения: $success');

      // Проверим что реально сохранилось
      final saved = prefs.getString(_projectsKey);
      print('🔍 Проверка сохраненных данных: ${saved != null ? "ДАННЫЕ ЕСТЬ" : "ДАННЫХ НЕТ"}');

      return success;
    } catch (e) {
      print('❌ Ошибка сохранения: $e');
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> loadProjects() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_projectsKey);

      print('📥 Загружаем данные по ключу: $_projectsKey');
      print('📄 Данные: $jsonString');

      if (jsonString != null && jsonString.isNotEmpty) {
        final List<dynamic> jsonList = jsonDecode(jsonString);
        print('📊 Загружено ${jsonList.length} проектов');
        return jsonList.cast<Map<String, dynamic>>();
      } else {
        print('📭 Нет сохраненных данных');
      }
    } catch (e) {
      print('❌ Ошибка загрузки: $e');
    }

    return [];
  }

  static Future<void> clearData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_projectsKey);
      print('🗑️ Данные очищены');
    } catch (e) {
      print('❌ Ошибка очистки: $e');
    }
  }

  // ✅ НОВЫЙ МЕТОД: Показать все ключи в хранилище
  static Future<void> debugStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      print('🔑 Все ключи в хранилище: $keys');

      for (final key in keys) {
        final value = prefs.getString(key);
        print('   $key: ${value?.substring(0, value.length > 100 ? 100 : value.length)}');
      }
    } catch (e) {
      print('❌ Ошибка отладки: $e');
    }
  }
}