import '../models/app_user.dart';
import '../services/firestore_service.dart';

class DataMigration {
  static Future<void> migrateUserData(AppUser user, FirestoreService service, String uid) async {
    bool needsMigration = false;

    // Проверяем нужна ли миграция
    for (final item in user.progressHistory) {
      if (item is Map<String, dynamic>) {
        // Данные уже в правильном формате
        continue;
      } else {
        // Нашли старые данные - нужна миграция
        needsMigration = true;
        break;
      }
    }

    if (needsMigration) {
      print('Миграция данных пользователя ${user.name}...');

      // Просто сохраняем пользователя - toFirestore() сделает миграцию
      await service.saveUser(user, uid);
      print('Миграция завершена!');
    }
  }
}