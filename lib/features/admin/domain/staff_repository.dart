import 'staff_member.dart';

abstract interface class StaffRepository {
  Future<List<StaffMember>> getStaff();

  Future<StaffMember> inviteStaff(StaffMember staffMember);

  Future<void> updateStaff(StaffMember staffMember);
}
