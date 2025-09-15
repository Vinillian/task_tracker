import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import 'package:provider/provider.dart';
import '../services/firestore_service.dart'; // ← ДОБАВИТЬ
import '../models/app_user.dart'; // ← ДОБАВИТЬ

// Добавьте этот класс ПЕРЕД _AuthScreenState
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _usernameController = TextEditingController(); // ← новый контроллер
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isLogin = true;
  String? _errorMessage;

  void _submit() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if ((_isLogin && (email.isEmpty || password.isEmpty)) ||
        (!_isLogin && (username.isEmpty || email.isEmpty || password.isEmpty))) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Заполните все поля';
      });
      return;
    }

    final authService = Provider.of<AuthService>(context, listen: false);
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);

    try {
      User? user;
      if (_isLogin) {
        user = await authService.signIn(email, password);
      } else {
        user = await authService.signUp(email, password);

        // Создаем пользователя в Firestore после регистрации
        if (user != null) {
          final newUser = AppUser(
            username: username,
            email: email,
            projects: [],
            progressHistory: [],
          );
          await firestoreService.saveUser(newUser, user.uid);
        }
      }

      if (user == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = _isLogin
              ? 'Ошибка входа. Проверьте email и пароль'
              : 'Ошибка регистрации. Возможно, email уже используется';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Ошибка: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isLogin ? 'Вход' : 'Регистрация')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Поле никнейма (только для регистрации)
            if (!_isLogin) ...[
              TextField(
                controller: _usernameController,
                decoration: const InputDecoration(
                    labelText: 'Никнейм',
                    hintText: 'Придумайте уникальное имя'
                ),
                maxLength: 20,
              ),
              const SizedBox(height: 16),
            ],

            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Пароль'),
              obscureText: true,
            ),

            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: Colors.red, fontSize: 14),
                ),
              ),

            const SizedBox(height: 20),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
              onPressed: _submit,
              child: Text(_isLogin ? 'Войти' : 'Зарегистрироваться'),
            ),
            TextButton(
              onPressed: () => setState(() {
                _isLogin = !_isLogin;
                _errorMessage = null;
              }),
              child: Text(_isLogin
                  ? 'Нет аккаунта? Зарегистрироваться'
                  : 'Уже есть аккаунт? Войти'),
            ),
          ],
        ),
      ),
    );
  }
}