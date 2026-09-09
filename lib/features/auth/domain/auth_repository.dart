import 'app_user.dart';

abstract interface class AuthRepository {
  Future<AppUser> signInWithEmailPassword({
    required String email,
    required String password,
  });

  Future<AppUser> signInWithGoogle();

  Future<void> requestPasswordReset({required String email});
}
