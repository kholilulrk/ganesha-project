class User {
  final int id;
  final String name;
  final String username;
  final String role;
  final String? phone;
  final String? photo;
  final String? createdAt;

  User({
    required this.id,
    required this.name,
    required this.username,
    required this.role,
    this.phone,
    this.photo,
    this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['ID'] ?? json['id'] ?? 0,
      name: json['Name'] ?? json['name'] ?? '',
      username: json['Username'] ?? json['username'] ?? '',
      role: json['Role'] ?? json['role'] ?? '',
      phone: json['Phone'] ?? json['phone'],
      photo: json['Photo'] ?? json['photo'],
      createdAt: json['CreatedAt'] ?? json['created_at'],
    );
  }

  bool get isLimitedRole => role == 'Teknisi' || role == 'Logistic';
}
