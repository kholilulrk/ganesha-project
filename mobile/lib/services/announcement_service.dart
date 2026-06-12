import '../models/announcement.dart';
import 'api_service.dart';

class AnnouncementService {
  static Future<List<Announcement>> getAll() async {
    final data = await ApiService.get('/announcements');
    final list = data['announcements'] as List<dynamic>?;
    if (list == null) return [];
    return list.map((j) => Announcement.fromJson(j as Map<String, dynamic>)).toList();
  }

  static Future<Announcement> create(Map<String, dynamic> body) async {
    final data = await ApiService.post('/announcements', body);
    return Announcement.fromJson(data['announcement'] as Map<String, dynamic>);
  }

  static Future<Announcement> update(int id, Map<String, dynamic> body) async {
    final data = await ApiService.put('/announcements/$id', body);
    return Announcement.fromJson(data['announcement'] as Map<String, dynamic>);
  }

  static Future<void> toggle(int id) async {
    await ApiService.put('/announcements/$id/toggle', {});
  }

  static Future<void> delete(int id) async {
    await ApiService.delete('/announcements/$id');
  }
}
