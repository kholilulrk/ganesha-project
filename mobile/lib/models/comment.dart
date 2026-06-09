class Comment {
  final int id;
  final int jobId;
  final String name;
  final String comment;
  final int? parentId;
  final String? createdAt;

  Comment({
    required this.id,
    required this.jobId,
    required this.name,
    required this.comment,
    this.parentId,
    this.createdAt,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['ID'] ?? json['id'] ?? 0,
      jobId: json['JobID'] ?? json['job_id'] ?? 0,
      name: json['Name'] ?? json['name'] ?? '',
      comment: json['Comment'] ?? json['comment'] ?? '',
      parentId: json['ParentID'] ?? json['parent_id'],
      createdAt: json['CreatedAt'] ?? json['created_at'],
    );
  }
}
