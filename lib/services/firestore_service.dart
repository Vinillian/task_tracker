import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _usersRef => _firestore.collection('users');

  // Сохранить пользователя по UID
  Future<void> saveUser(AppUser user, String uid) async {
    try {
      final userData = {
        'name': user.name,
        'projects': user.projects.map((p) => p.toFirestore()).toList(),
        'progressHistory': user.progressHistory,
      };

      await _usersRef.doc(uid).set(userData, SetOptions(merge: true));
      print('User ${user.name} saved successfully to Firestore with UID: $uid');
    } catch (e) {
      print('Error saving user to Firestore: $e');
      rethrow;
    }
  }

  // Получить документ пользователя по UID
  Future<DocumentSnapshot> getUserDocument(String uid) async {
    return await _usersRef.doc(uid).get();
  }

  // Stream для конкретного пользователя по UID
  Stream<AppUser?> userStream(String uid) {
    return _usersRef.doc(uid).snapshots().map((snapshot) {
      if (snapshot.exists) {
        return AppUser.fromFirestore(snapshot.data() as Map<String, dynamic>);
      }
      return null;
    });
  }

  // Удалить пользователя по UID
  Future<void> deleteUser(String uid) async {
    try {
      await _usersRef.doc(uid).delete();
      print('User with UID: $uid deleted from Firestore');
    } catch (e) {
      print('Error deleting user: $e');
      rethrow;
    }
  }

  // Старый метод для обратной совместимости (можно удалить позже)
  Stream<List<AppUser>> usersStream() {
    return _usersRef.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => AppUser.fromFirestore(doc.data() as Map<String, dynamic>))
          .toList();
    });
  }
}