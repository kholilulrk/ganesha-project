import '../models/attendance.dart';
import 'api_service.dart';

class AttendanceService {
  static Future<Attendance?> getToday() async {
    try {
      final data = await ApiService.get('/attendance/today');
      if (data['attendance'] == null) return null;
      return Attendance.fromJson(data['attendance'] as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  static Future<Attendance> hadir(String location) async {
    final data = await ApiService.post('/attendance/hadir', {'location': location});
    return Attendance.fromJson(data['attendance'] as Map<String, dynamic>);
  }

  static Future<Attendance> tidakHadir(String reason) async {
    final data = await ApiService.post('/attendance/tidak-hadir', {'reason': reason});
    return Attendance.fromJson(data['attendance'] as Map<String, dynamic>);
  }

  static Future<Attendance> lemburStart() async {
    final data = await ApiService.post('/attendance/lembur/start', {});
    return Attendance.fromJson(data['attendance'] as Map<String, dynamic>);
  }

  static Future<Attendance> lemburEnd() async {
    final data = await ApiService.post('/attendance/lembur/end', {});
    return Attendance.fromJson(data['attendance'] as Map<String, dynamic>);
  }

  static Future<List<Attendance>> getReport({String? date, String? role}) async {
    final params = <String, String>{};
    if (date != null) params['date'] = date;
    if (role != null) params['role'] = role;
    final queryString = params.entries.map((e) => '${e.key}=${e.value}').join('&');
    final endpoint = '/attendance/report${queryString.isNotEmpty ? '?$queryString' : ''}';
    final data = await ApiService.get(endpoint);
    final list = data['attendance'] as List<dynamic>?;
    if (list == null) return [];
    return list.map((j) => Attendance.fromJson(j as Map<String, dynamic>)).toList();
  }

  static Future<void> update(int id, Map<String, dynamic> body) async {
    await ApiService.put('/attendance/$id', body);
  }

  static Future<void> delete(int id) async {
    await ApiService.delete('/attendance/$id');
  }
}
