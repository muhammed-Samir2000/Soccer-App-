import 'app_user.dart';

abstract interface class AuthRepository {
  /// Development-only entry points. Production authentication replaces these.
  Future<AppUser> signInAsDemoPlayer();

  Future<AppUser> signInAsDemoAdmin();

  Future<AppUser> signInWithEmailPassword({
    required String email,
    required String password,
  });

  Future<AppUser> signInWithGoogle();

  Future<void> requestPasswordReset({required String email});
}
