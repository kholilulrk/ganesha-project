import '../models/todo.dart';
import 'api_service.dart';

class TodoService {
  static Future<List<Todo>> getAll() async {
    final data = await ApiService.get('/todos');
    final list = data['todos'] as List<dynamic>;
    return list.map((j) => Todo.fromJson(j as Map<String, dynamic>)).toList();
  }

  static Future<void> create(String task, {int? assignedTo}) async {
    final body = <String, dynamic>{'task': task};
    if (assignedTo != null && assignedTo > 0) body['assigned_to'] = assignedTo;
    await ApiService.post('/todos', body);
  }

  static Future<void> toggle(int id) async {
    await ApiService.put('/todos/$id/toggle');
  }

  static Future<void> delete(int id) async {
    await ApiService.delete('/todos/$id');
  }
}
