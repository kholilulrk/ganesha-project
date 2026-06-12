import 'api_service.dart';

class AppUpdateInfo {
  final String latestVersion;
  final String downloadUrl;

  AppUpdateInfo({required this.latestVersion, required this.downloadUrl});

  factory AppUpdateInfo.fromJson(Map<String, dynamic> json) {
    return AppUpdateInfo(
      latestVersion: json['latest_version'] ?? '1.0.0',
      downloadUrl: json['download_url'] ?? '',
    );
  }

  bool get hasDownloadUrl => downloadUrl.isNotEmpty;
}

class AppUpdateService {
  static Future<AppUpdateInfo> checkUpdate() async {
    final data = await ApiService.get('/app-version');
    return AppUpdateInfo.fromJson(data);
  }
}
