import '../domain/staff_member.dart';
import '../domain/staff_repository.dart';

class MockStaffRepository implements StaffRepository {
  MockStaffRepository()
    : _staff = <StaffMember>[
        const StaffMember(
          id: 'staff-001',
          name: 'أحمد الاستقبال',
          canCreateBookings: true,
          canEditBookings: true,
          canViewFinancialReports: false,
        ),
        const StaffMember(
          id: 'staff-002',
          name: 'محمود المشرف',
          canCreateBookings: true,
          canEditBookings: true,
          canViewFinancialReports: true,
        ),
      ];

  final List<StaffMember> _staff;

  @override
  Future<List<StaffMember>> getStaff() async => List.unmodifiable(_staff);

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
