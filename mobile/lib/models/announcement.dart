class Announcement {
  final int id;
  final String title;
  final String? content;
  final DateTime startAt;
  final DateTime endAt;
  final bool isActive;

  Announcement({
    required this.id,
    required this.title,
    this.content,
    required this.startAt,
    required this.endAt,
    required this.isActive,
  });

  factory Announcement.fromJson(Map<String, dynamic> json) {
    return Announcement(
      id: json['ID'] ?? json['id'] ?? 0,
      title: json['Title'] ?? json['title'] ?? '',
      content: json['Content'] ?? json['content'],
      startAt: _parseDate(json['StartAt'] ?? json['start_at']),
      endAt: _parseDate(json['EndAt'] ?? json['end_at']),
      isActive: json['IsActive'] ?? json['is_active'] ?? true,
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    return value as DateTime;
  }
}
