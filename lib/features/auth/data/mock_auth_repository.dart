import '../domain/app_user.dart';
import '../domain/auth_repository.dart';

class MockAuthRepository implements AuthRepository {
  const MockAuthRepository();

  Future<AppUser> _userFor(UserRole intendedRole) async {
    return switch (intendedRole) {
      UserRole.player => const AppUser(
        id: 'player-001',
        name: 'الكابتن أحمد',
        role: UserRole.player,
      ),
      UserRole.admin => const AppUser(
        id: 'admin-001',
        name: 'الكابتن سمير',
        role: UserRole.admin,
      ),
    };
  }

  @override
  Future<AppUser> signInWithEmailPassword({
    required String email,
    required String password,
    required UserRole intendedRole,
  }) => _userFor(intendedRole);

  @override
  Future<AppUser> signInWithGoogle({required UserRole intendedRole}) =>
      _userFor(intendedRole);

  @override
  Future<void> requestPasswordReset({required String email}) async {}
}
