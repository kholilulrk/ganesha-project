class Permission {
  final int id;
  final String role;
  final String resource;
  final String action;

  Permission({
    required this.id,
    required this.role,
    required this.resource,
    required this.action,
  });

  factory Permission.fromJson(Map<String, dynamic> json) {
    return Permission(
      id: json['id'] ?? json['ID'] ?? 0,
      role: json['role'] ?? json['Role'] ?? '',
      resource: json['resource'] ?? json['Resource'] ?? '',
      action: json['action'] ?? json['Action'] ?? '',
    );
  }

  String get key => '$resource.$action';
}

class RoleCount {
  final String role;
  final int count;

  RoleCount({required this.role, required this.count});

  factory RoleCount.fromJson(Map<String, dynamic> json) {
    return RoleCount(
      role: json['role'] ?? '',
      count: json['count'] ?? 0,
    );
  }
}
