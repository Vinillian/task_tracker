import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

class StorageService {
  final String dataKey = "progress_data";

  // Сохранение данных (работает везде)
  Future<void> saveData(List<User> users) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = {'users': users.map((u) => u.toJson()).toList()};
      await prefs.setString(dataKey, json.encode(data));
    } catch (e) {
      print("Error saving data: $e");
    }
  }

  // Загрузка данных (работает везде)
  Future<List<User>> loadData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(dataKey);

      if (jsonString != null) {
        final data = json.decode(jsonString);
        return (data['users'] as List).map((u) => User.fromJson(u)).toList();
      }
    } catch (e) {
      print("Error loading data: $e");
    }
    return [];
  }

  // Экспорт данных как текста (работает везде)
  Future<String> exportData(List<User> users) async {
    try {
      final data = {
        'users': users.map((u) => u.toJson()).toList(),
        'exportDate': DateTime.now().toIso8601String(),
      };

      return json.encode(data); // Просто возвращаем JSON строку
    } catch (e) {
      return 'Ошибка экспорта: $e';
    }
  }

  // Импорт данных из текста (работает везде)
  Future<List<User>> importData(String jsonString) async {
    try {
      final data = json.decode(jsonString);

      if (data['users'] is List) {
        return (data['users'] as List).map((u) => User.fromJson(u)).toList();
      }

      return [];
    } catch (e) {
      print("Error importing data: $e");
      return [];
    }
  }
}