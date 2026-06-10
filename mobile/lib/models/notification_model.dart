class NotificationModel {
  final int id;
  final String title;
  final String body;
  final String type;
  final int? refId;
  final String? refType;
  final bool isRead;
  final int createdAt;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.refId,
    this.refType,
    this.isRead = false,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['ID'] ?? json['id'] ?? 0,
      title: json['Title'] ?? json['title'] ?? '',
      body: json['Body'] ?? json['body'] ?? '',
      type: json['Type'] ?? json['type'] ?? '',
      refId: json['RefID'] ?? json['ref_id'],
      refType: json['RefType'] ?? json['ref_type'],
      isRead: json['IsRead'] ?? json['is_read'] ?? false,
      createdAt: json['CreatedAt'] ?? json['created_at'] ?? 0,
    );
  }
}
