import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _usersRef => _firestore.collection('users');

  // Сохранить пользователя по UID
  Future<void> saveUser(AppUser user, String uid) async {
    try {
      // Используем метод toFirestore() из модели AppUser
      final userData = user.toFirestore();

      await _usersRef.doc(uid).set(userData, SetOptions(merge: true));
      print('✅ Пользователь ${user.username} сохранен в Firestore (UID: $uid)');
      print('📊 Данные: ${userData.toString()}');
    } catch (e) {
      print('❌ Ошибка сохранения пользователя: $e');
      rethrow;
    }
  }

  // Получить документ пользователя по UID
  Future<DocumentSnapshot> getUserDocument(String uid) async {
    try {
      final doc = await _usersRef.doc(uid).get();
      print('📄 Загружен документ пользователя: ${doc.exists ? "существует" : "не существует"}');
      return doc;
    } catch (e) {
      print('❌ Ошибка загрузки документа: $e');
      rethrow;
    }
  }

  // Stream для конкретного пользователя по UID
  Stream<AppUser?> userStream(String uid) {
    return _usersRef.doc(uid).snapshots().map((snapshot) {
      if (snapshot.exists) {
        print('🔄 Stream: данные пользователя обновлены');
        return AppUser.fromFirestore(snapshot.data() as Map<String, dynamic>);
      }
      print('🔄 Stream: документ не существует');
      return null;
    });
  }

  // Удалить пользователя по UID
  Future<void> deleteUser(String uid) async {
    try {
      await _usersRef.doc(uid).delete();
      print('Пользователь с UID: $uid удален из Firestore');
    } catch (e) {
      print('Ошибка удаления пользователя: $e');
      rethrow;
    }
  }

  // Старый метод для обратной совместимости
  Stream<List<AppUser>> usersStream() {
    return _usersRef.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => AppUser.fromFirestore(doc.data() as Map<String, dynamic>))
          .toList();
    });
  }
}