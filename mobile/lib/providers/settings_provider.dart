import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider with ChangeNotifier {
  bool _biometricEnabled = false;
  String? _currentUsername;

  bool get biometricEnabled => _biometricEnabled;

  Future<void> loadBiometricForUser(String username) async {
    _currentUsername = username;
    final prefs = await SharedPreferences.getInstance();
    _biometricEnabled = prefs.getBool('biometric_enabled_$username') ?? false;
    notifyListeners();
  }

  Future<void> setBiometricEnabled(bool value) async {
    if (_currentUsername == null) return;
    _biometricEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('biometric_enabled_$_currentUsername', value);

    final users = prefs.getStringList('biometric_users') ?? [];
    if (value && !users.contains(_currentUsername)) {
      users.add(_currentUsername!);
      await prefs.setStringList('biometric_users', users);
    } else if (!value) {
      users.remove(_currentUsername);
      await prefs.setStringList('biometric_users', users);
      await prefs.remove('biometric_password_$_currentUsername');
    }
    notifyListeners();
  }

  static Future<List<String>> getEnrolledUsers() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('biometric_users') ?? [];
  }

  static Future<String?> getPasswordForUser(String username) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('biometric_password_$username');
  }

  static Future<void> savePasswordForUser(
      String username, String password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('biometric_password_$username', password);
  }

  static Future<void> removeBiometricForUser(String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('biometric_password_$username');
    await prefs.remove('biometric_enabled_$username');
    final users = prefs.getStringList('biometric_users') ?? [];
    users.remove(username);
    await prefs.setStringList('biometric_users', users);
  }
}
