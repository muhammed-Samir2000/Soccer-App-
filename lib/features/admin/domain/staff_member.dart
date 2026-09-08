class StaffMember {
  const StaffMember({
    required this.id,
    required this.name,
    required this.canCreateBookings,
    required this.canEditBookings,
    required this.canViewFinancialReports,
  });

  final String id;
  final String name;
  final bool canCreateBookings;
  final bool canEditBookings;
  final bool canViewFinancialReports;

  StaffMember copyWith({
    bool? canCreateBookings,
    bool? canEditBookings,
    bool? canViewFinancialReports,
  }) {
    return StaffMember(
      id: id,
      name: name,
      canCreateBookings: canCreateBookings ?? this.canCreateBookings,
      canEditBookings: canEditBookings ?? this.canEditBookings,
      canViewFinancialReports:
          canViewFinancialReports ?? this.canViewFinancialReports,
    );
  }
}
