import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';
import 'firebase_options.dart';
import 'screens/task_tracker_screen.dart';
import 'services/firestore_service.dart';
import 'services/auth_service.dart';
import 'screens/auth_screen.dart';
import 'repositories/local_repository.dart';


// Глобальные ключи для доступа к сервисам
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // 🔹 Инициализируем Hive перед LocalRepository
    await Hive.initFlutter();

    // 🔹 Локальное хранилище
    final localRepository = LocalRepository();
    await localRepository.init();

    // 🔹 Firebase
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

    runApp(MyApp(localRepository: localRepository));
  } catch (e) {
    debugPrint('❌ Ошибка инициализации приложения: $e');
    // Запускаем приложение даже с ошибкой инициализации
    runApp(const ErrorApp());
  }
}

// 🔹 ДОБАВЬТЕ ЭТОТ КЛАСС ПЕРЕД MyApp
class CalendarRefresh extends ChangeNotifier {
  void refresh() {
    notifyListeners();
  }
}

class MyApp extends StatelessWidget {
  final LocalRepository localRepository;

  const MyApp({super.key, required this.localRepository});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<LocalRepository>(create: (_) => localRepository),
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<FirestoreService>(create: (_) => FirestoreService()),
        ChangeNotifierProvider(create: (_) => CalendarRefresh()),
      ],
      child: MaterialApp(
        title: 'Task Tracker',
        theme: ThemeData(primarySwatch: Colors.blue),
        home: const AuthWrapper(),
        navigatorKey: navigatorKey,
        scaffoldMessengerKey: scaffoldMessengerKey,
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});


  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasData) {
          // 🔹 Загружаем пользователя из локального хранилища
          final localRepo = Provider.of<LocalRepository>(context, listen: false);
          final user = localRepo.loadUser();

          if (user == null) {
            debugPrint('⚠️ Пользователь не найден в локальном хранилище');
          } else {
            debugPrint('✅ Загружен пользователь: ${user.username}');
          }

          return const TaskTrackerScreen();
        } else {
          return const AuthScreen(); // 🔹 добавляем экран авторизации
        }
      },
    );
  }

}

// Простое приложение для отображения ошибки
class ErrorApp extends StatelessWidget {
  const ErrorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'Ошибка инициализации приложения',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Попробуйте перезапустить приложение',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  // Попытка перезапуска (в реальном приложении нужно более сложное решение)
                  main();
                },
                child: const Text('Перезапустить'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}