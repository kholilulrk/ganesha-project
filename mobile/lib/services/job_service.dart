import 'dart:io';
import '../models/job.dart';
import 'api_service.dart';

class JobService {
  static Future<List<Job>> getJobs([Map<String, String>? params]) async {
    String endpoint = '/jobs';
    if (params != null && params.isNotEmpty) {
      final query = params.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&');
      endpoint += '?$query';
    }
    final data = await ApiService.get(endpoint);
    final list = data['jobs'] as List<dynamic>;
    return list.map((j) => Job.fromJson(j as Map<String, dynamic>)).toList();
  }

  static Future<Map<String, dynamic>> getJobDetail(int id) async {
    return await ApiService.get('/jobs/$id');
  }

  static Future<Job> createJob(Map<String, dynamic> body) async {
    final data = await ApiService.post('/jobs', body);
    return Job.fromJson(data['job'] as Map<String, dynamic>);
  }

  static Future<Map<String, dynamic>> updateJob(
      int id, Map<String, dynamic> body) async {
    return await ApiService.put('/jobs/$id', body);
  }

  // Alias for create
  static Future<void> create(Map<String, dynamic> body) async {
    await ApiService.post('/jobs', body);
  }

  // Alias for update
  static Future<void> update(int id, Map<String, dynamic> body) async {
    await ApiService.put('/jobs/$id', body);
  }

  static Future<void> delete(int id) async {
    await ApiService.delete('/jobs/$id');
  }

  static Future<void> complete(int id) async {
    await ApiService.put('/jobs/$id/complete');
  }

  static Future<void> updateStatus(int id, String status) async {
    await ApiService.patch('/jobs/$id/status', {'status': status});
  }

  static Future<Map<String, dynamic>> generateShareLink(int id) async {
    return await ApiService.post('/jobs/$id/share-link', {});
  }

  static Future<Map<String, dynamic>> uploadDocument(int id, String filePath,
      {String? name, String? type}) async {
    final file = File(filePath);
    return await ApiService.uploadFile('/jobs/$id/documents', file,
        fields: {
          if (name != null) 'name': name,
          if (type != null) 'type': type,
        });
  }

  static Future<Map<String, dynamic>> getShared(String token) async {
    return await ApiService.get('/jobs/shared/$token');
  }

  static Future<Map<String, dynamic>> progresShared(
      String token, int itemId) async {
    return await ApiService.put('/jobs/shared/$token/checklist/$itemId/progres');
  }

  static Future<Map<String, dynamic>> selesaiShared(
      String token, int itemId) async {
    return await ApiService.put('/jobs/shared/$token/checklist/$itemId/selesai');
  }

  static Future<List<dynamic>> getComments(int jobId) async {
    final data = await ApiService.get('/jobs/$jobId/comments');
    return data['comments'] as List<dynamic>? ?? [];
  }

  static Future<Map<String, dynamic>> addComment(
      int id, Map<String, dynamic> body) async {
    return await ApiService.post('/jobs/$id/comments', body);
  }

  static Future<Map<String, dynamic>> deleteComment(int jobId, int commentId) async {
    return await ApiService.delete('/jobs/$jobId/comments/$commentId');
  }

  static Future<Map<String, dynamic>> addCommentShared(
      String token, Map<String, dynamic> body) async {
    return await ApiService.post('/jobs/shared/$token/comments', body);
  }
}
