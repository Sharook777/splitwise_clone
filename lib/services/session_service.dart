import 'package:shared_preferences/shared_preferences.dart';
import 'database_service.dart';

/// Service to manage the current session user using SharedPreferences.
class SessionService {
  static const String _nameKey = 'session_user_name';
  static const String _emailKey = 'session_user_email';
  static const String _isLoggedInKey = 'is_logged_in';

  static const String _currencyKey = 'session_user_currency';

  /// Save the current user session
  static Future<void> saveSession({
    required String name,
    required String email,
    String? currency,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_nameKey, name);
    await prefs.setString(_emailKey, email);
    await prefs.setBool(_isLoggedInKey, true);
  }

  /// Get the current session user's currency
  static Future<String?> getCurrency() async {
    final dbCurrency = await DatabaseService.getConfig('currency');
    if (dbCurrency != null) {
      // Sync to SharedPreferences for fast access
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_currencyKey, dbCurrency);
      return dbCurrency;
    }
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_currencyKey) ?? '₹ INR';
  }

  /// Get the currency symbol only (e.g., '₹')
  static Future<String> getCurrencySymbol() async {
    final currency = await getCurrency();
    if (currency == null) return '₹';
    return currency.split(' ').first;
  }

  /// Save the user's currency preference
  static Future<void> saveCurrency(String currency) async {
    await DatabaseService.updateConfig('currency', currency);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currencyKey, currency);
  }

  /// Check if a user is currently logged in
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool(_isLoggedInKey);
    return isLoggedIn ?? false;
  }

  /// Get the current session user's name
  static Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_nameKey);
  }

  /// Get the current session user's email
  static Future<String?> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_emailKey);
  }

  /// Clear the current session
  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_nameKey);
    await prefs.remove(_emailKey);
    await prefs.remove(_currencyKey);
    await prefs.setBool(_isLoggedInKey, false);
  }
}
