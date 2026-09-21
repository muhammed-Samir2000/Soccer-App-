enum StaffRole {
  manager('مدير'),
  reception('استقبال');

  const StaffRole(this.label);

  final String label;
}

enum StaffInvitationStatus {
  pending('دعوة معلقة'),
  active('مفعّل'),
  revoked('ملغية');

  const StaffInvitationStatus(this.label);

  final String label;
}

class StaffMember {
  const StaffMember({
    required this.id,
    required this.name,
    required this.email,
    required this.phoneNumber,
    required this.role,
    required this.invitationStatus,
    required this.canCreateBookings,
    required this.canEditBookings,
    required this.canViewFinancialReports,
  });

  final String id;
  final String name;
  final String email;
  final String phoneNumber;
  final StaffRole role;
  final StaffInvitationStatus invitationStatus;
  final bool canCreateBookings;
  final bool canEditBookings;
  final bool canViewFinancialReports;

  StaffMember copyWith({
    String? id,
    String? name,
    String? email,
    String? phoneNumber,
    StaffRole? role,
    StaffInvitationStatus? invitationStatus,
    bool? canCreateBookings,
    bool? canEditBookings,
    bool? canViewFinancialReports,
  }) {
    return StaffMember(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      role: role ?? this.role,
      invitationStatus: invitationStatus ?? this.invitationStatus,
      canCreateBookings: canCreateBookings ?? this.canCreateBookings,
      canEditBookings: canEditBookings ?? this.canEditBookings,
      canViewFinancialReports:
          canViewFinancialReports ?? this.canViewFinancialReports,
    );
  }
}
