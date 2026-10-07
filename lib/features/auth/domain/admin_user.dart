import '../../../core/utils/map_reader.dart';

/// Administrator profile stored in `admins/{uid}`.
/// Passwords are never stored in Firestore.
class AdminUser {
  const AdminUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    required this.active,
    this.createdAt,
  });

  static const String collection = 'admins';
  static const String roleSuperAdmin = 'super_admin';
  static const String roleAdmin = 'admin';
  static const List<String> roles = [roleSuperAdmin, roleAdmin];

  final String uid;
  final String name;
  final String email;
  final String role;
  final bool active;
  final DateTime? createdAt;

  bool get isSuperAdmin => role == roleSuperAdmin;

  factory AdminUser.fromMap(Map<String, dynamic> map, {String uid = ''}) {
    final reader = MapReader(map);
    var role = reader.getString('role', roleAdmin);
    if (!roles.contains(role)) role = roleAdmin;
    return AdminUser(
      uid: uid,
      name: reader.getString('name'),
      email: reader.getString('email'),
      role: role,
      active: reader.getBool('active', true),
      createdAt: reader.getDate('createdAt'),
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'email': email,
        'role': role,
        'active': active,
        'createdAt': createdAt,
      };
}
