import 'package:flutter_test/flutter_test.dart';
import 'package:soccer_booking_app/features/auth/data/mock_auth_repository.dart';
import 'package:soccer_booking_app/features/auth/domain/app_user.dart';

void main() {
  test('derives the mock user role from the authenticated identity', () async {
    const MockAuthRepository repository = MockAuthRepository();

    final AppUser player = await repository.signInWithEmailPassword(
      email: 'player@example.com',
      password: 'password123',
    );
    final AppUser admin = await repository.signInWithEmailPassword(
      email: 'admin@mal3ab.test',
      password: 'password123',
    );

    expect(player.role, UserRole.player);
    expect(admin.role, UserRole.admin);
  });
}
