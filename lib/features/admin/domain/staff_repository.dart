import 'staff_member.dart';

abstract interface class StaffRepository {
  Future<List<StaffMember>> getStaff();

  Future<StaffMember> inviteStaff(StaffMember staffMember);

  Future<void> updateStaff(StaffMember staffMember);

  /// Revocation must also remove server-side venue access in a live adapter.
  Future<void> revokeStaff(String staffId);
}
