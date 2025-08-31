import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/user.dart';

class StorageService {
  final String dataFile = "progress_data.json";

  Future<void> saveData(List<User> users) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$dataFile');
      final data = {'users': users.map((u) => u.toJson()).toList()};
      await file.writeAsString(json.encode(data));
    } catch (e) {
      print("Error saving data: $e");
    }
  }

  Future<List<User>> loadData() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$dataFile');

      if (await file.exists()) {
        final contents = await file.readAsString();
        final data = json.decode(contents);
        return (data['users'] as List).map((u) => User.fromJson(u)).toList();
      }
    } catch (e) {
      print("Error loading data: $e");
    }
    return [];
  }
}