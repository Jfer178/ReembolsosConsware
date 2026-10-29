/// Sesión del empleado: token JWT emitido por la API y los datos del usuario.
class Session {
  const Session({
    required this.token,
    required this.expiresAtUtc,
    required this.username,
    required this.fullName,
    required this.department,
    required this.role,
  });

  final String token;
  final DateTime expiresAtUtc;
  final String username;
  final String fullName;
  final String department;
  final String role;

  bool get isExpired => DateTime.now().toUtc().isAfter(expiresAtUtc);

  bool get isEmployee => role == 'Employee';

  String get firstName => fullName.split(' ').first;

  String get initials => fullName
      .split(' ')
      .where((part) => part.isNotEmpty)
      .take(2)
      .map((part) => part[0].toUpperCase())
      .join();

  /// Respuesta de POST /api/auth/login.
  factory Session.fromLoginJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>;
    return Session(
      token: json['token'] as String,
      expiresAtUtc: DateTime.parse(json['expiresAtUtc'] as String),
      username: user['username'] as String,
      fullName: user['fullName'] as String,
      department: user['department'] as String,
      role: user['role'] as String,
    );
  }

  factory Session.fromJson(Map<String, dynamic> json) => Session(
        token: json['token'] as String,
        expiresAtUtc: DateTime.parse(json['expiresAtUtc'] as String),
        username: json['username'] as String,
        fullName: json['fullName'] as String,
        department: json['department'] as String,
        role: json['role'] as String,
      );

  Map<String, dynamic> toJson() => {
        'token': token,
        'expiresAtUtc': expiresAtUtc.toIso8601String(),
        'username': username,
        'fullName': fullName,
        'department': department,
        'role': role,
      };
}
