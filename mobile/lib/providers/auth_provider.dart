import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../models/user.dart';

class AuthProvider with ChangeNotifier {
  String? _token;
  User? _user;
  bool _loading = false;
  bool _initialized = false;

  String? get token => _token;
  User? get user => _user;
  bool get loading => _loading;
  bool get initialized => _initialized;
  bool get isAuthenticated => _token != null;

  AuthProvider() {
    _loadToken();
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
    if (_token != null) {
      try {
        await getProfile();
      } catch (_) {
        _token = null;
        await prefs.remove('token');
      }
    }
    _initialized = true;
    notifyListeners();
  }

  Future<void> register(
      String name, String role, String username, String password) async {
    _loading = true;
    notifyListeners();
    try {
      await ApiService.post('/auth/register', {
        'name': name,
        'role': role,
        'username': username,
        'password': password,
      });
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> login(String username, String password) async {
    _loading = true;
    notifyListeners();
    try {
      final data = await ApiService.post('/auth/login', {
        'username': username,
        'password': password,
      });
      _token = data['token'] as String;
      _user = User.fromJson(data['user'] as Map<String, dynamic>);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', _token!);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> getProfile() async {
    final data = await ApiService.get('/profile');
    _user = User.fromJson(data['user'] as Map<String, dynamic>);
    notifyListeners();
  }

  Future<void> updateProfile({
    String? name,
    String? username,
    String? phone,
    String? password,
    File? photo,
  }) async {
    final fields = <String, String>{};
    if (name != null && name.isNotEmpty) fields['name'] = name;
    if (username != null && username.isNotEmpty) fields['username'] = username;
    if (phone != null && phone.isNotEmpty) fields['phone'] = phone;
    if (password != null && password.isNotEmpty) fields['password'] = password;
    final data = await ApiService.multipartPut('/profile', fields, file: photo, fileField: 'photo');
    _user = User.fromJson(data['user'] as Map<String, dynamic>);
    notifyListeners();
  }

  Future<void> uploadPhoto(File file) async {
    final data = await ApiService.multipartPut('/profile', {}, file: file, fileField: 'photo');
    _user = User.fromJson(data['user'] as Map<String, dynamic>);
    notifyListeners();
  }

  Future<void> logout() async {
    _token = null;
    _user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    notifyListeners();
  }
}
