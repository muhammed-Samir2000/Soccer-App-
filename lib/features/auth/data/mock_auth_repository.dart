import '../domain/app_user.dart';
import '../domain/auth_repository.dart';

class MockAuthRepository implements AuthRepository {
  const MockAuthRepository();

  static const String _demoAdminEmail = 'admin@mal3ab.test';

  @override
  Future<AppUser> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    if (email.trim().toLowerCase() == _demoAdminEmail) {
      return const AppUser(
        id: 'admin-001',
        name: 'الكابتن سمير',
        role: UserRole.admin,
      );
    }

    return const AppUser(
      id: 'player-001',
      name: 'الكابتن أحمد',
      role: UserRole.player,
    );
  }

  @override
  Future<AppUser> signInWithGoogle() =>
      signInWithEmailPassword(email: 'player@mal3ab.test', password: '');

  @override
  Future<void> requestPasswordReset({required String email}) async {}
}
