import '../domain/app_user.dart';
import '../domain/auth_repository.dart';

class MockAuthRepository implements AuthRepository {
  const MockAuthRepository();

  @override
  Future<AppUser> signInAs(UserRole role) async {
    return switch (role) {
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
  Future<void> requestOtp(String phoneNumber) async {
    throw UnsupportedError('OTP غير مفعّل في النسخة التجريبية.');
  }

  @override
  Future<AppUser> verifyOtp({
    required String phoneNumber,
    required String code,
    required UserRole role,
  }) => signInAs(role);
}
