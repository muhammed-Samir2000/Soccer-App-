import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/app_user.dart';
import '../domain/auth_repository.dart';

class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this._client);

  final SupabaseClient _client;

  @override
  bool get usesLiveAuthentication => true;

  @override
  Future<AppUser?> restoreSession() async {
    final User? user = _client.auth.currentUser;
    if (user == null) {
      return null;
    }
    final Map<String, dynamic>? profile = await _client
        .from('profiles')
        .select('full_name, platform_role')
        .eq('id', user.id)
        .maybeSingle();
    final String name =
        profile?['full_name'] as String? ??
        user.userMetadata?['full_name'] as String? ??
        user.email?.split('@').first ??
        'لاعب جديد';
    final String role = profile?['platform_role'] as String? ?? 'player';
    return AppUser(
      id: user.id,
      name: name,
      role: role == 'admin' || role == 'super_admin'
          ? UserRole.admin
          : UserRole.player,
    );
  }

  @override
  Future<void> signOut() => _client.auth.signOut();

  @override
  Future<AppUser> signInAsDemoPlayer() =>
      Future<AppUser>.error(UnsupportedError('الدخول التجريبي غير متاح.'));

  @override
  Future<AppUser> signInAsDemoAdmin() =>
      Future<AppUser>.error(UnsupportedError('الدخول التجريبي غير متاح.'));

  @override
  Future<AppUser?> signInWithGoogle() async {
    await _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: kIsWeb ? Uri.base.origin : null,
    );
    return restoreSession();
  }

  @override
  Future<AppUser> signInWithEmailPassword({
    required String email,
    required String password,
  }) => Future<AppUser>.error(UnsupportedError('غير متاح حالياً.'));

  @override
  Future<void> requestPasswordReset({required String email}) async {}
}
