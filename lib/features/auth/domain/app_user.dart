enum UserRole { player, admin, superAdmin }

class AppUser {
  const AppUser({required this.id, required this.name, required this.role});

  final String id;
  final String name;
  final UserRole role;

  bool get canAccessAdmin =>
      role == UserRole.admin || role == UserRole.superAdmin;

  bool get isSuperAdmin => role == UserRole.superAdmin;
}
