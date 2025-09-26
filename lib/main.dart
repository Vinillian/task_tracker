import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'firebase_options.dart';
import 'screens/task_tracker_screen.dart';
import 'services/firestore_service.dart';
import 'services/auth_service.dart';
import 'screens/auth_screen.dart';
import 'repositories/local_repository.dart';
import 'models/recurrence.dart';
import 'models/recurrence_completion.dart';

// Глобальные ключи для доступа к сервисам
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔹 Инициализируем Hive перед LocalRepository
  await Hive.initFlutter();

  // 🔹 Регистрируем адаптеры для кастомных моделей (ТОЛЬКО ОДИН РАЗ!)
  Hive.registerAdapter(RecurrenceAdapter());
  Hive.registerAdapter(RecurrenceTypeAdapter());
  Hive.registerAdapter(RecurrenceCompletionAdapter()); // УБРАТЬ ДУБЛИРОВАНИЕ

  // 🔹 Локальное хранилище
  final localRepository = LocalRepository();
  await localRepository.init();

  // 🔹 Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(MyApp(localRepository: localRepository));
}

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
        home: AuthWrapper(),
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