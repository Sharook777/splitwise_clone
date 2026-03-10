import '../models/user_model.dart';
import 'database_service.dart';
import 'hive_service.dart';
import 'session_service.dart';

class AuthService {
  /// Handles the sign up process.
  /// If the user already exists, it reuses the user's data for the session.
  /// Otherwise, it creates a new user in Hive and SQLite.
  static Future<void> signUp({
    required String name,
    required String email,
  }) async {
    // Check if user with this email already exists (case-insensitive)
    final existingUser = await DatabaseService.getUserByEmail(email);

    if (existingUser != null) {
      // User already exists — use existing user's data
      await SessionService.saveSession(
        name: existingUser.name,
        email: existingUser.email,
      );
    } else {
      // New user — save to Hive + SQLite
      final user = User(name: name, email: email);
      await HiveService.saveUser(user);
      await DatabaseService.insertUser(user);
      await SessionService.saveSession(name: name, email: email);
    }
  }

  /// Handles the sign out process by clearing the session.
  static Future<void> signOut() async {
    await SessionService.clearSession();
  }
}
