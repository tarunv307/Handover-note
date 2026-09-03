class User {
  final int id;
  final String name;
  final String email;
  final String role; // 'admin' or 'employee'
  final String? employeeId;
  final String? createdAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.employeeId,
    this.createdAt,
  });

  bool get isAdmin => role.toLowerCase() == 'admin';

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'employee',
      employeeId: json['employee_id'],
      createdAt: json['created_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'employee_id': employeeId,
      'created_at': createdAt,
    };
  }
}
