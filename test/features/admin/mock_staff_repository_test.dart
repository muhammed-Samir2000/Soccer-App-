import 'package:flutter_test/flutter_test.dart';
import 'package:soccer_booking_app/features/admin/data/mock_staff_repository.dart';
import 'package:soccer_booking_app/features/admin/domain/staff_member.dart';

void main() {
  test('prevents duplicate staff invitations by normalized e-mail', () async {
    final MockStaffRepository repository = MockStaffRepository();
    final StaffMember invitation = StaffMember(
      id: '',
      name: 'مشرف جديد',
      email: '  Team.Lead@Example.com ',
      role: StaffRole.reception,
      invitationStatus: StaffInvitationStatus.pending,
      canCreateBookings: true,
      canEditBookings: false,
      canViewFinancialReports: false,
    );

    final StaffMember saved = await repository.inviteStaff(invitation);

    expect(saved.email, 'team.lead@example.com');
    expect(saved.invitationStatus, StaffInvitationStatus.pending);
    await expectLater(
      repository.inviteStaff(invitation),
      throwsA(isA<ArgumentError>()),
    );
  });
}
