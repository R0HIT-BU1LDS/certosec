import '../core/constants/app_enums.dart';

/// User is the authenticated operator (typically an institution admin).
///
/// The model is deliberately logic-free: it only maps to/from the backend's
/// JSON shape. Role string parsing tolerates common backend variants
/// (`admin`, `Admin`, `administrator`, `verifier`, ...). Unknown roles
/// default to the least-privilege option, which is the verifier.
class User {
  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.avatarUrl,
  });

  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String? avatarUrl;

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: _parseRole(json['role']),
      avatarUrl: json['avatarUrl']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'role': role.name,
    'avatarUrl': avatarUrl,
  };

  /// First name for friendly greetings ("Good morning, Jane").
  String get firstName {
    final parts = name.trim().split(RegExp(r'\s+'));
    return parts.isEmpty || parts.first.isEmpty ? name : parts.first;
  }

  static UserRole _parseRole(Object? raw) {
    if (raw is String) {
      final normalized = raw.toLowerCase();
      if (normalized.contains('admin')) return UserRole.admin;
      if (normalized.contains('verif')) return UserRole.verifier;
    }
    return UserRole.verifier;
  }
}
