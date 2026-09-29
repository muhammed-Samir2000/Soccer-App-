import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/staff_member.dart';
import '../domain/staff_repository.dart';

/// Super-admin team operations are limited to the audited invitation RPCs.
class SupabaseStaffRepository implements StaffRepository {
  SupabaseStaffRepository(this._client, this._venueIdProvider);

  final SupabaseClient _client;
  final Future<String> Function() _venueIdProvider;

  static StaffMember decode(Map<String, dynamic> row) {
    final String email = row['email'] as String;
    final String status = row['status'] as String;
    return StaffMember(
      id: row['id'] as String,
      // The invitation schema intentionally has no arbitrary display-name field.
      name: email.split('@').first,
      email: email,
      phoneNumber: row['phone_number'] as String? ?? '',
      role: StaffRole.values.byName(row['role'] as String),
      invitationStatus: switch (status) {
        'accepted' => StaffInvitationStatus.active,
        'revoked' => StaffInvitationStatus.revoked,
        _ => StaffInvitationStatus.pending,
      },
      canCreateBookings: row['can_create_bookings'] as bool,
      canEditBookings: row['can_edit_bookings'] as bool,
      canViewFinancialReports: row['can_view_financial_reports'] as bool,
    );
  }

  @override
  Future<List<StaffMember>> getStaff() async {
    final String venueId = await _venueIdProvider();
    try {
      final rows = await _client
          .from('admin_email_invitations')
          .select(
            'id,email,phone_number,role,status,can_create_bookings,can_edit_bookings,can_view_financial_reports',
          )
          .eq('venue_id', venueId)
          .order('invited_at', ascending: false);
      return rows
          .map((Object row) => decode(Map<String, dynamic>.from(row as Map)))
          .toList(growable: false);
    } on PostgrestException {
      throw StateError('تعذر تحميل فريق الإدارة. راجع صلاحية السوبر أدمن.');
    }
  }

  @override
  Future<StaffMember> inviteStaff(StaffMember staffMember) =>
      _write('invite_venue_admin', <String, dynamic>{
        'p_email': staffMember.email.trim().toLowerCase(),
        'p_phone_number': staffMember.phoneNumber.trim(),
        'p_role': staffMember.role.name,
        'p_can_create_bookings': staffMember.canCreateBookings,
        'p_can_edit_bookings': staffMember.canEditBookings,
        'p_can_view_financial_reports': staffMember.canViewFinancialReports,
      }, includeVenueId: true);

  @override
  Future<void> updateStaff(StaffMember staffMember) async {
    await _write('update_venue_admin_invitation', <String, dynamic>{
      'p_invitation_id': staffMember.id,
      'p_role': staffMember.role.name,
      'p_can_create_bookings': staffMember.canCreateBookings,
      'p_can_edit_bookings': staffMember.canEditBookings,
      'p_can_view_financial_reports': staffMember.canViewFinancialReports,
    });
  }

  @override
  Future<void> revokeStaff(String staffId) async {
    try {
      await _client.rpc(
        'revoke_venue_admin_invitation',
        params: <String, dynamic>{'p_invitation_id': staffId},
      );
    } on PostgrestException {
      throw StateError('تعذر إلغاء صلاحيات العضو. حاول مرة أخرى.');
    }
  }

  Future<StaffMember> _write(
    String function,
    Map<String, dynamic> parameters, {
    bool includeVenueId = false,
  }) async {
    try {
      final Map<String, dynamic> request = Map<String, dynamic>.from(
        parameters,
      );
      if (includeVenueId) {
        request['p_venue_id'] = await _venueIdProvider();
      }
      final result = await _client.rpc(function, params: request);
      return decode(Map<String, dynamic>.from(result as Map));
    } on PostgrestException catch (error) {
      if (error.code == '42501') {
        throw StateError('العملية متاحة للسوبر أدمن فقط.');
      }
      throw ArgumentError('تعذر حفظ الدعوة أو الصلاحيات. راجع البيانات.');
    }
  }
}
