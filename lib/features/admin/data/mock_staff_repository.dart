import '../domain/staff_member.dart';
import '../domain/staff_repository.dart';

class MockStaffRepository implements StaffRepository {
  MockStaffRepository()
    : _staff = <StaffMember>[
        const StaffMember(
          id: 'staff-001',
          name: 'أحمد الاستقبال',
          email: 'ahmed@mal3ab.test',
          role: StaffRole.reception,
          invitationStatus: StaffInvitationStatus.active,
          canCreateBookings: true,
          canEditBookings: true,
          canViewFinancialReports: false,
        ),
        const StaffMember(
          id: 'staff-002',
          name: 'محمود المشرف',
          email: 'mahmoud@mal3ab.test',
          role: StaffRole.manager,
          invitationStatus: StaffInvitationStatus.active,
          canCreateBookings: true,
          canEditBookings: true,
          canViewFinancialReports: true,
        ),
      ];

  final List<StaffMember> _staff;

  @override
  Future<List<StaffMember>> getStaff() async => List.unmodifiable(_staff);

  @override
  Future<StaffMember> inviteStaff(StaffMember staffMember) async {
    final String email = staffMember.email.trim().toLowerCase();
    final bool alreadyInvited = _staff.any(
      (StaffMember item) => item.email.toLowerCase() == email,
    );
    if (alreadyInvited) {
      throw ArgumentError('البريد ده موجود بالفعل ضمن فريق الإدارة.');
    }
    final StaffMember invitation = staffMember.copyWith(
      id: 'staff-${(_staff.length + 1).toString().padLeft(3, '0')}',
      email: email,
      invitationStatus: StaffInvitationStatus.pending,
    );
    _staff.add(invitation);
    return invitation;
  }

  @override
  Future<void> updateStaff(StaffMember staffMember) async {
    final int index = _staff.indexWhere(
      (StaffMember item) => item.id == staffMember.id,
    );
    if (index == -1) {
      throw StateError('Staff member not found');
    }
    _staff[index] = staffMember;
  }
}
