import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'package:provider/provider.dart';
import '../models/app_user.dart'; // ← ДОБАВИТЬ этот импорт

class DrawerScreen extends StatelessWidget {
  final String? userEmail;
  final AppUser? currentUser;  // ← Добавьте этот параметр

  const DrawerScreen({
    super.key,
    required this.userEmail,
    required this.currentUser,  // ← Добавьте этот параметр
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        children: [
          DrawerHeader(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  currentUser?.username ?? userEmail ?? 'Гость',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text(
                  userEmail ?? '',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                SizedBox(height: 8),
                Text(
                  'Task Tracker',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ],
            ),
          ),

          // КНОПКА ВЫХОДА
          ListTile(
            leading: Icon(Icons.logout),
            title: Text('Выйти'),
            onTap: () async {
              final authService = Provider.of<AuthService>(context, listen: false);
              await authService.signOut();
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}