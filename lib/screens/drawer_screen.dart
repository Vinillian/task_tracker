import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/firestore_service.dart';
import '../widgets/dialogs.dart';

class DrawerScreen extends StatelessWidget {
  final User? currentUser;
  final Function(User) onUserSelected;
  final FirestoreService _firestoreService = FirestoreService();

  DrawerScreen({
    super.key,
    required this.currentUser,
    required this.onUserSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: StreamBuilder<List<User>>(
        stream: _firestoreService.usersStream(),
        builder: (context, snapshot) {
          final users = snapshot.data ?? [];

          return ListView(
            children: [
              const DrawerHeader(
                decoration: BoxDecoration(color: Colors.blue),
                child: Text(
                  'Пользователи',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),
              ...users.map((user) => ListTile(
                title: Text(user.name),
                selected: user.name == currentUser?.name,
                onTap: () {
                  Navigator.pop(context);
                  onUserSelected(user);
                },
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () async {
                    final confirm = await Dialogs.showConfirmDialog(
                      context: context,
                      title: 'Удалить пользователя',
                      message:
                      'Вы уверены, что хотите удалить ${user.name}?',
                    );
                    if (confirm) await _firestoreService.deleteUser(user);
                  },
                ),
              )),
              ListTile(
                leading: const Icon(Icons.add),
                title: const Text('Добавить пользователя'),
                onTap: () async {
                  final name = await Dialogs.showTextInputDialog(
                    context: context,
                    title: 'Новый пользователь',
                  );
                  if (name != null && name.isNotEmpty) {
                    final newUser =
                    User(name: name, projects: [], progressHistory: []);
                    await _firestoreService.saveUser(newUser);
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
