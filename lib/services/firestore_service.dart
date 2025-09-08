import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _usersRef => _firestore.collection('users');

  // --- Stream всех пользователей ---
  Stream<List<User>> usersStream() {
    return _usersRef.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => User.fromFirestore(doc.data() as Map<String, dynamic>))
          .toList();
    });
  }

  // --- Сохранить пользователя (ИСПРАВЛЕННЫЙ) ---
  Future<void> saveUser(User user) async {
    try {
      final userData = {
        'name': user.name,
        'projects': user.projects.map((p) => p.toFirestore()).toList(),
        'progressHistory': user.progressHistory,
      };

      await _usersRef.doc(user.name).set(userData, SetOptions(merge: true));
      print('User ${user.name} saved successfully to Firestore');
    } catch (e) {
      print('Error saving user to Firestore: $e');
      rethrow;
    }
  }

  // --- Удалить пользователя ---
  Future<void> deleteUser(User user) async {
    try {
      await _usersRef.doc(user.name).delete();
      print('User ${user.name} deleted from Firestore');
    } catch (e) {
      print('Error deleting user: $e');
      rethrow;
    }
  }
}