import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'screens/task_tracker_screen.dart';
import 'services/firestore_service.dart';
import 'services/auth_service.dart';
import 'screens/auth_screen.dart';
import 'repositories/local_repository.dart'; // ← ДОБАВИТЬ

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Инициализируем локальное хранилище ПЕРЕД runApp
  final localRepository = LocalRepository();
  await localRepository.init();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(MyApp(localRepository: localRepository)); // ← ПЕРЕДАТЬ репозиторий
}

class MyApp extends StatelessWidget {
  final LocalRepository localRepository; // ← ДОБАВИТЬ поле

  const MyApp({super.key, required this.localRepository}); // ← ОБНОВИТЬ конструктор

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<LocalRepository>(create: (_) => localRepository), // ← ДОБАВИТЬ провайдер
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<FirestoreService>(create: (_) => FirestoreService()),
      ],
      child: MaterialApp(
        title: 'Task Tracker',
        theme: ThemeData(primarySwatch: Colors.blue),
        home: AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (snapshot.hasData) {
          return const TaskTrackerScreen();
        }

        return const AuthScreen();
      },
    );
  }
}