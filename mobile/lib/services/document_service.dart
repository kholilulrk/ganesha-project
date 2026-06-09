import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/document.dart';
import 'api_service.dart';

class DocumentService {
  static Future<List<Document>> getAll() async {
    final data = await ApiService.get('/documents');
    final list = data['documents'] as List<dynamic>;
    return list.map((j) => Document.fromJson(j as Map<String, dynamic>)).toList();
  }

  static Future<void> create(File file, Map<String, String> fields) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    final uri = Uri.parse('${ApiService.baseUrl}/documents');
    final request = http.MultipartRequest('POST', uri);
    request.headers['Authorization'] = 'Bearer $token';
    request.fields.addAll(fields);
    request.files.add(await http.MultipartFile.fromPath('file', file.path));
    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    if (response.body.isEmpty) return;
    final data = jsonDecode(response.body);
    if (data is Map<String, dynamic>) {
      if (response.statusCode >= 200 && response.statusCode < 300) return;
      throw ApiException(data['error'] ?? 'Gagal upload dokumen');
    }
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    throw ApiException('Gagal upload dokumen');
  }

  static Future<void> update(int id, Map<String, dynamic> body) async {
    await ApiService.put('/documents/$id', body);
  }

  static Future<void> delete(int id) async {
    await ApiService.delete('/documents/$id');
  }
}
