import '../models/permission.dart';
import 'api_service.dart';

class PermissionService {
  static Future<List<RoleCount>> getRoles() async {
    final data = await ApiService.get('/permissions/roles');
    final list = data['roles'] as List<dynamic>;
    return list.map((j) => RoleCount.fromJson(j as Map<String, dynamic>)).toList();
  }

  static Future<List<Permission>> getAllPermissions() async {
    final data = await ApiService.get('/permissions');
    final list = data['permissions'] as List<dynamic>;
    return list.map((j) => Permission.fromJson(j as Map<String, dynamic>)).toList();
  }

  static Future<void> update(String role, List<String> permissions) async {
    await ApiService.put('/permissions', {
      'role': role,
      'permissions': permissions,
    });
  }

  static Future<void> reset() async {
    await ApiService.post('/permissions/reset', {});
  }
}
