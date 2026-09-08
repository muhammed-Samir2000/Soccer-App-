import 'app_user.dart';

abstract interface class AuthRepository {
  Future<AppUser> signInAs(UserRole role);

  /// Reserved for a real auth provider; mock mode never sends an SMS.
  Future<void> requestOtp(String phoneNumber);

  /// Reserved for a real auth provider; mock mode never verifies a code.
  Future<AppUser> verifyOtp({
    required String phoneNumber,
    required String code,
    required UserRole role,
  });
}
