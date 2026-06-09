import '../models/user.dart';
import 'api_service.dart';

class UserService {
  static Future<List<User>> getAll({String? roles}) async {
    String endpoint = '/users';
    if (roles != null && roles.isNotEmpty) {
      endpoint += '?roles=$roles';
    }
    final data = await ApiService.get(endpoint);
    final list = data['users'] as List<dynamic>;
    return list.map((j) => User.fromJson(j as Map<String, dynamic>)).toList();
  }

  static Future<void> create(Map<String, dynamic> body) async {
    await ApiService.post('/users', body);
  }

  static Future<void> update(int id, Map<String, dynamic> body) async {
    await ApiService.put('/users/$id', body);
  }

  static Future<void> delete(int id) async {
    await ApiService.delete('/users/$id');
  }
}
