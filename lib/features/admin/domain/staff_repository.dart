import 'staff_member.dart';

abstract interface class StaffRepository {
  Future<List<StaffMember>> getStaff();

  Future<void> updateStaff(StaffMember staffMember);
}
