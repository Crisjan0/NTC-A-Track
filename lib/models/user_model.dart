/// Represents a system user account (currently the Admin).
class User {
  final int? id;
  final String username;
  final String passwordHash;
  final String salt;
  final String role;
  final DateTime createdAt;

  const User({
    this.id,
    required this.username,
    required this.passwordHash,
    required this.salt,
    this.role = 'admin',
    required this.createdAt,
  });

  factory User.fromMap(Map<String, dynamic> map) => User(
        id: map['id'] as int?,
        username: map['username'] as String,
        passwordHash: map['password_hash'] as String,
        salt: map['salt'] as String,
        role: map['role'] as String? ?? 'admin',
        createdAt: DateTime.parse(map['created_at'] as String),
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'username': username,
        'password_hash': passwordHash,
        'salt': salt,
        'role': role,
        'created_at': createdAt.toIso8601String(),
      };
}