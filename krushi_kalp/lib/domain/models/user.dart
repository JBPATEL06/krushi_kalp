enum UserRole {
  Student, // Capitalized to match DB string often, though exact string matching handles case
  Admin
}

class User {
  final String id; // UUID
  final String username;
  final String email;
  final UserRole role; // 'Student' or 'Admin'
  final String? phoneNumber;
  final String? degree;
  final String language; // 'en' or 'gu'

  User({
    required this.id,
    required this.username,
    required this.email,
    this.role = UserRole.Student,
    this.phoneNumber,
    this.degree,
    this.language = 'en',
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username, // Matches DB
      'email': email,
      'role': role.toString().split('.').last, // 'Student' or 'Admin'
      'phonenumber':
          phoneNumber, // Note: DB uses 'phonenumber' (no underscore based on schema provided, wait, schema said 'phonenumber')
      'degree': degree,
      'language': language,
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      username:
          json['username'] as String? ?? json['email']?.split('@')[0] ?? 'User',
      email: json['email'] as String,
      role: UserRole.values.firstWhere(
        (e) =>
            e.toString().split('.').last.toLowerCase() ==
            (json['role'] as String? ?? 'Student').toLowerCase(),
        orElse: () => UserRole.Student,
      ),
      phoneNumber: json['phonenumber'] as String?, // Updated to match schema
      degree: json['degree'] as String?,
      language: json['language'] as String? ?? 'en',
    );
  }
}
