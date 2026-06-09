import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import 'auth_provider.dart';

class PermissionProvider with ChangeNotifier {
  Set<String> _permissions = {};
  bool _loaded = false;
  String? _lastToken;

  bool get loaded => _loaded;
  Set<String> get permissions => _permissions;

  void checkAuth(AuthProvider auth) {
    if (!auth.isAuthenticated) {
      reset();
      return;
    }
    if (auth.token != _lastToken) {
      _lastToken = auth.token;
      load();
    }
  }

  bool can(String resource, String action, {bool isSuperAdmin = false}) {
    if (isSuperAdmin) return true;
    return _permissions.contains('$resource.$action');
  }

  Future<void> load() async {
    _loaded = false;
    try {
      final data = await ApiService.get('/permissions');
      final list = data['permissions'] as List<dynamic>;
      _permissions = list.map((p) {
        final map = p as Map<String, dynamic>;
        final resource = (map['resource'] ?? map['Resource'] ?? '') as String;
        final action = (map['action'] ?? map['Action'] ?? '') as String;
        return resource.isNotEmpty && action.isNotEmpty
            ? '$resource.$action'
            : null;
      }).whereType<String>().toSet();
    } catch (_) {
      _permissions = {};
    }
    _loaded = true;
    notifyListeners();
  }

  void reset() {
    _permissions = {};
    _loaded = false;
    _lastToken = null;
    notifyListeners();
  }
}
