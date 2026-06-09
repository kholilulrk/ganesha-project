class Todo {
  final int id;
  final String task;
  final String status;
  final int assignedTo;
  final int createdBy;
  final String? createdAt;

  Todo({
    required this.id,
    required this.task,
    this.status = 'pending',
    this.assignedTo = 0,
    this.createdBy = 0,
    this.createdAt,
  });

  factory Todo.fromJson(Map<String, dynamic> json) {
    return Todo(
      id: json['ID'] ?? json['id'] ?? 0,
      task: json['Task'] ?? json['task'] ?? '',
      status: json['Status'] ?? json['status'] ?? 'pending',
      assignedTo: json['AssignedTo'] ?? json['assigned_to'] ?? 0,
      createdBy: json['CreatedBy'] ?? json['created_by'] ?? 0,
      createdAt: json['CreatedAt'] ?? json['created_at'],
    );
  }

  bool get isDone => status == 'done';
}
