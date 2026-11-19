enum UserRole { student, lecturer, hod }

class EleesaUser {
  final String id;
  final String fullName;
  final String email;
  final UserRole role;
  final String token;

  EleesaUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    required this.token,
  });

  factory EleesaUser.fromJson(Map<String, dynamic> json) {
    final rawRole = (json['role'] ?? 'student').toString().toLowerCase();
    final parsedRole = switch (rawRole) {
      'lecturer' => UserRole.lecturer,
      'hod' => UserRole.hod,
      _ => UserRole.student,
    };

    return EleesaUser(
      id: json['id'].toString(),
      fullName: json['fullName'] ?? json['full_name'] ?? '',
      email: json['email'] ?? '',
      role: parsedRole,
      token: json['token'] ?? '',
    );
  }
}