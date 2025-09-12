import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Текущий пользователь
  User? get currentUser => _auth.currentUser;

  // Автоматический вход при запуске
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Регистрация
  Future<User?> signUp(String email, String password) async {
    try {
      final result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } catch (e) {
      print('Ошибка регистрации: $e');
      return null;
    }
  }

  // Вход
  Future<User?> signIn(String email, String password) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } catch (e) {
      print('Ошибка входа: $e');
      return null;
    }
  }

  // Выход
  Future<void> signOut() async {
    await _auth.signOut();
  }
}