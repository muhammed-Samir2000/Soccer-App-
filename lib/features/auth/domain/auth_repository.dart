import 'app_user.dart';

abstract interface class AuthRepository {
  Future<AppUser> signInWithEmailPassword({
    required String email,
    required String password,
    required UserRole intendedRole,
  });

  Future<AppUser> signInWithGoogle({required UserRole intendedRole});

  Future<void> requestPasswordReset({required String email});
}
