import 'api_service.dart';

class DashboardService {
  static Future<Map<String, dynamic>> getStats() async {
    return await ApiService.get('/dashboard');
  }
}
