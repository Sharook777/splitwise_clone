import 'package:hive_flutter/hive_flutter.dart';
import '../models/user_model.dart';

/// Service to manage User data in Hive (local NoSQL storage).
class HiveService {
  static const String _userBoxName = 'users';

  static Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(UserAdapter());
    await Hive.openBox<User>(_userBoxName);
  }

  static Box<User> get _userBox => Hive.box<User>(_userBoxName);

  /// Save a user to Hive
  static Future<void> saveUser(User user) async {
    await _userBox.add(user);
  }

  /// Get all users
  static List<User> getAllUsers() {
    return _userBox.values.toList();
  }

  /// Get a user by index
  static User? getUser(int index) {
    if (index >= 0 && index < _userBox.length) {
      return _userBox.getAt(index);
    }
    return null;
  }
}
