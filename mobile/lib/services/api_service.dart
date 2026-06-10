import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'http://203.194.115.28/api';
  static const String baseUploadUrl = 'http://203.194.115.28';
  static const Duration _timeout = Duration(seconds: 30);

  static Future<Map<String, String>> _headers({bool multipart = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    final headers = <String, String>{
      if (!multipart) 'Content-Type': 'application/json',
      if (token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
    return headers;
  }

  static Future<Map<String, dynamic>> get(String endpoint) async {
    final headers = await _headers();
    final response = await http
        .get(Uri.parse('$baseUrl$endpoint'), headers: headers)
        .timeout(_timeout);
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    final headers = await _headers();
    final response = await http
        .post(
          Uri.parse('$baseUrl$endpoint'),
          headers: headers,
          body: jsonEncode(body),
        )
        .timeout(_timeout);
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> put(
    String endpoint, [
    Map<String, dynamic>? body,
  ]) async {
    final headers = await _headers();
    final response = await http
        .put(
          Uri.parse('$baseUrl$endpoint'),
          headers: headers,
          body: body != null ? jsonEncode(body) : null,
        )
        .timeout(_timeout);
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> patch(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    final headers = await _headers();
    final response = await http
        .patch(
          Uri.parse('$baseUrl$endpoint'),
          headers: headers,
          body: jsonEncode(body),
        )
        .timeout(_timeout);
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> delete(String endpoint) async {
    final headers = await _headers();
    final response = await http
        .delete(Uri.parse('$baseUrl$endpoint'), headers: headers)
        .timeout(_timeout);
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> uploadFile(
    String endpoint,
    File file, {
    Map<String, String>? fields,
    String method = 'POST',
  }) async {
    final headers = await _headers(multipart: true);
    final request =
        http.MultipartRequest(method, Uri.parse('$baseUrl$endpoint'));
    request.headers.addAll(headers);
    if (fields != null) request.fields.addAll(fields);
    request.files.add(await http.MultipartFile.fromPath('file', file.path));
    final streamed = await request.send().timeout(_timeout);
    final response = await http.Response.fromStream(streamed);
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> multipartPut(
    String endpoint,
    Map<String, String> fields, {
    File? file,
    String fileField = 'file',
  }) async {
    final headers = await _headers(multipart: true);
    final request = http.MultipartRequest('PUT', Uri.parse('$baseUrl$endpoint'));
    request.headers.addAll(headers);
    request.fields.addAll(fields);
    if (file != null) {
      request.files.add(await http.MultipartFile.fromPath(fileField, file.path));
    }
    final streamed = await request.send().timeout(_timeout);
    final response = await http.Response.fromStream(streamed);
    return _handleResponse(response);
  }

  static Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.body.isEmpty) return {};
    final data = jsonDecode(response.body);
    if (data is Map<String, dynamic>) {
      if (response.statusCode >= 200 && response.statusCode < 300) return data;
      throw ApiException(data['error'] ?? 'Unknown error');
    }
    if (response.statusCode >= 200 && response.statusCode < 300) return {};
    throw ApiException('Unknown error');
  }
}

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}
