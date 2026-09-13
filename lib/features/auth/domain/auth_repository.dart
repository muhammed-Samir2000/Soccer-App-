import 'app_user.dart';

abstract interface class AuthRepository {
  bool get usesLiveAuthentication;

  Future<AppUser?> restoreSession();

  Future<void> signOut();

  /// Development-only entry points. Production authentication replaces these.
  Future<AppUser> signInAsDemoPlayer();

  Future<AppUser> signInAsDemoAdmin();

  Future<AppUser> signInWithEmailPassword({
    required String email,
    required String password,
  });

  /// Starts OAuth. A browser redirect can complete the session after reload.
  Future<AppUser?> signInWithGoogle();

  Future<void> requestPasswordReset({required String email});
}
