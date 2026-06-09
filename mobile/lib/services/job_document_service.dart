import 'dart:io';
import 'api_service.dart';

class JobDocumentService {
  static Future<Map<String, dynamic>> getDocuments(int jobId) async {
    return await ApiService.get('/jobs/$jobId/documents');
  }

  static Future<Map<String, dynamic>> uploadDocument(
    int jobId,
    String filePath,
    String docType,
  ) async {
    final file = File(filePath);
    return await ApiService.uploadFile('/jobs/$jobId/documents', file, fields: {
      'doc_type': docType,
    });
  }

  static Future<void> updateDocDates(int jobId, {String? tdm, String? tds}) async {
    final body = <String, String>{};
    if (tdm != null && tdm.isNotEmpty) body['tdm'] = tdm;
    if (tds != null && tds.isNotEmpty) body['tds'] = tds;
    if (body.isEmpty) return;
    await ApiService.patch('/jobs/$jobId/doc-dates', body);
  }

  static Future<void> deleteDocument(int jobId, int docId) async {
    await ApiService.delete('/jobs/$jobId/documents/$docId');
  }

  static Future<void> toggleVerification(
    int jobId,
    String step,
    bool checked,
  ) async {
    await ApiService.put('/jobs/$jobId/verification', {
      'step': step,
      'checked': checked,
    });
  }

  static Future<void> updateProgress(int jobId, String progress) async {
    await ApiService.put('/jobs/$jobId/progress', {
      'progress': progress,
    });
  }
}
