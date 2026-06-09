import '../models/surat.dart';
import 'api_service.dart';

class SuratService {
  static Future<List<Surat>> getAll() async {
    final data = await ApiService.get('/surats');
    final list = data['surats'] as List<dynamic>;
    return list.map((j) => Surat.fromJson(j as Map<String, dynamic>)).toList();
  }

  static Future<List<Surat>> getExpiring() async {
    final data = await ApiService.get('/surats/expiring');
    final list = data['surats'] as List<dynamic>;
    return list.map((j) => Surat.fromJson(j as Map<String, dynamic>)).toList();
  }

  static Future<void> create(Map<String, dynamic> body) async {
    await ApiService.post('/surats', body);
  }

  static Future<void> update(int id, Map<String, dynamic> body) async {
    await ApiService.put('/surats/$id', body);
  }

  static Future<void> delete(int id) async {
    await ApiService.delete('/surats/$id');
  }
}
