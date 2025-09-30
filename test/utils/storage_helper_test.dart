// test/utils/storage_helper_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_tracker/utils/storage_helper.dart';

void main() {
  // Инициализируем binding для тестов с SharedPreferences
  TestWidgetsFlutterBinding.ensureInitialized();

  group('StorageHelper Tests', () {
    setUp(() async {
      // Мокаем SharedPreferences для тестов
      SharedPreferences.setMockInitialValues({});
    });

    test('Save and load projects', () async {
      final projectsData = [
        {
          'id': '1',
          'name': 'Project 1',
          'description': 'Description 1',
          'tasks': [],
          'createdAt': DateTime.now().millisecondsSinceEpoch,
        },
        {
          'id': '2',
          'name': 'Project 2',
          'description': 'Description 2',
          'tasks': [],
          'createdAt': DateTime.now().millisecondsSinceEpoch,
        }
      ];

      // Сохраняем проекты
      final saveResult = await StorageHelper.saveProjects(projectsData);
      expect(saveResult, true);

      // Загружаем проекты
      final loadedProjects = await StorageHelper.loadProjects();

      expect(loadedProjects.length, 2);
      expect(loadedProjects[0]['name'], 'Project 1');
      expect(loadedProjects[1]['name'], 'Project 2');
    });

    test('Load projects when no data exists', () async {
      final loadedProjects = await StorageHelper.loadProjects();
      expect(loadedProjects, isEmpty);
    });

    test('Clear data', () async {
      // Сначала сохраняем данные
      final projectsData = [
        {
          'id': '1',
          'name': 'Test Project',
          'tasks': [],
          'createdAt': DateTime.now().millisecondsSinceEpoch,
        }
      ];

      await StorageHelper.saveProjects(projectsData);

      // Очищаем данные
      await StorageHelper.clearData();

      // Проверяем что данные очищены
      final loadedProjects = await StorageHelper.loadProjects();
      expect(loadedProjects, isEmpty);
    });
  });
}