import 'dart:io';
import '../models/checklist_item.dart';
import 'api_service.dart';

class ChecklistService {
  static Future<List<ChecklistItem>> getItems(int jobId, String role) async {
    final data =
        await ApiService.get('/jobs/$jobId/checklist?role=$role');
    final list = data['items'] as List<dynamic>;
    return list
        .map((i) => ChecklistItem.fromJson(i as Map<String, dynamic>))
        .toList();
  }

  static Future<ChecklistItem> addItem(
      int jobId, Map<String, dynamic> body) async {
    final data = await ApiService.post('/jobs/$jobId/checklist', body);
    return ChecklistItem.fromJson(data['item'] as Map<String, dynamic>);
  }

  static Future<void> toggleItem(int jobId, int itemId) async {
    await ApiService.put('/jobs/$jobId/checklist/$itemId');
  }

  static Future<void> updateItem(
      int jobId, int itemId, Map<String, dynamic> body) async {
    await ApiService.patch('/jobs/$jobId/checklist/$itemId', body);
  }

  static Future<void> progres(int jobId, int itemId) async {
    await ApiService.put('/jobs/$jobId/checklist/$itemId/progres');
  }

  static Future<void> selesai(int jobId, int itemId) async {
    await ApiService.put('/jobs/$jobId/checklist/$itemId/selesai');
  }

  static Future<void> uploadImage(
      int jobId, int itemId, String role, File file) async {
    await ApiService.uploadFile(
        '/jobs/$jobId/checklist/$itemId/images?role=$role', file);
  }

  static Future<void> deleteImage(
      int jobId, int itemId, String filename) async {
    await ApiService.delete(
        '/jobs/$jobId/checklist/$itemId/images?filename=$filename');
  }

  static Future<void> deleteItem(int jobId, int itemId) async {
    await ApiService.delete('/jobs/$jobId/checklist/$itemId');
  }
}
