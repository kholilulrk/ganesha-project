import '../models/notification_model.dart';
import 'api_service.dart';

class NotificationApiService {
  static Future<void> registerFCMToken(String token) async {
    await ApiService.post('/fcm/register', {'token': token});
  }

  static Future<void> unregisterFCMToken(String token) async {
    await ApiService.post('/fcm/unregister', {'token': token});
  }

  static Future<List<NotificationModel>> getNotifications() async {
    final data = await ApiService.get('/notifications');
    final list = data['notifications'] as List<dynamic>? ?? [];
    return list.map((e) => NotificationModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<int> getUnreadCount() async {
    final data = await ApiService.get('/notifications/unread-count');
    return data['count'] as int? ?? 0;
  }

  static Future<void> markRead(int id) async {
    await ApiService.put('/notifications/$id/read');
  }

  static Future<void> markAllRead() async {
    await ApiService.put('/notifications/read-all');
  }
}
