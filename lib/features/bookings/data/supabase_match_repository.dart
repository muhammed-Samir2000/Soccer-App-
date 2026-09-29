import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/booking.dart';
import '../domain/booking_match.dart';
import '../domain/match_participant.dart';
import '../domain/match_repository.dart';

/// Resolves team information exclusively through narrow, authenticated RPCs.
/// Raw invitation tokens exist only in the caller that has just created one.
class SupabaseMatchRepository implements MatchRepository {
  SupabaseMatchRepository(this.client);

  final SupabaseClient client;

  @override
  Future<BookingMatch> createOrRefreshInviteForBooking(
    Booking booking, {
    int capacity = 10,
  }) async {
    if (capacity < 2 || capacity > 30) {
      throw ArgumentError('عدد اللاعبين لازم يكون بين 2 و30.');
    }
    try {
      final dynamic data = await client.rpc(
        'soccer_create_match_invite',
        params: <String, dynamic>{
          'p_booking_reference': booking.reference,
          'p_player_capacity': capacity,
        },
      );
      return decode(Map<String, dynamic>.from(data as Map));
    } on PostgrestException catch (error) {
      throw StateError(_friendlyError(error));
    }
  }

  @override
  Future<BookingMatch?> getForBooking(String bookingReference) async {
    try {
      final dynamic data = await client.rpc(
        'soccer_get_booking_match',
        params: <String, dynamic>{'p_booking_reference': bookingReference},
      );
      if (data == null) {
        return null;
      }
      return decode(Map<String, dynamic>.from(data as Map));
    } on PostgrestException catch (error) {
      throw StateError(_friendlyError(error));
    }
  }

  @override
  Future<BookingMatch?> getByInviteToken(String inviteToken) async {
    try {
      final dynamic data = await client.rpc(
        'soccer_get_match_invite_preview',
        params: <String, dynamic>{'p_invite_token': inviteToken},
      );
      if (data == null) {
        return null;
      }
      return decode(
        Map<String, dynamic>.from(data as Map),
        inviteToken: inviteToken,
      );
    } on PostgrestException catch (error) {
      throw StateError(_friendlyError(error));
    }
  }

  @override
  Future<BookingMatch> respondToInvite({
    required String inviteToken,
    required String playerId,
    required String playerName,
    required MatchParticipationStatus status,
  }) async {
    if (playerName.trim().length < 2 || playerName.trim().length > 80) {
      throw ArgumentError('اكتب اسم من حرفين إلى 80 حرف.');
    }
    try {
      await client.rpc(
        'soccer_respond_to_match_invite',
        params: <String, dynamic>{
          'p_invite_token': inviteToken,
          'p_status': status.name == 'notGoing' ? 'not_going' : status.name,
          'p_display_name': playerName.trim(),
        },
      );
      final BookingMatch? updated = await getByInviteToken(inviteToken);
      if (updated == null) {
        throw StateError('رابط الدعوة غير صالح أو انتهت صلاحيته.');
      }
      return updated;
    } on PostgrestException catch (error) {
      throw StateError(_friendlyError(error));
    }
  }

  static BookingMatch decode(Map<String, dynamic> row, {String? inviteToken}) {
    final List<dynamic> rawParticipants =
        row['participants'] as List<dynamic>? ?? const <dynamic>[];
    final List<MatchParticipant> participants = rawParticipants
        .map((dynamic value) => Map<String, dynamic>.from(value as Map))
        .map(
          (Map<String, dynamic> participant) => MatchParticipant(
            playerId: participant['player_id'] as String,
            displayName: participant['display_name'] as String,
            status: _status(participant['status'] as String),
            isOrganizer: participant['is_organizer'] as bool? ?? false,
          ),
        )
        .toList();
    return BookingMatch(
      bookingReference: row['booking_reference'] as String,
      organizerId: row['organizer_id'] as String? ?? '',
      organizerName: row['organizer_name'] as String,
      startsAt: DateTime.parse(row['starts_at'] as String).toLocal(),
      endsAt: DateTime.parse(row['ends_at'] as String).toLocal(),
      fieldNumber: (row['field_number'] as num).toInt(),
      capacity: (row['player_capacity'] as num).toInt(),
      inviteToken: row['invite_token'] as String? ?? inviteToken,
      participants: participants,
      goingCount: (row['going_count'] as num?)?.toInt(),
    );
  }

  static MatchParticipationStatus _status(String value) => switch (value) {
    'invited' => MatchParticipationStatus.invited,
    'going' => MatchParticipationStatus.going,
    'not_going' => MatchParticipationStatus.notGoing,
    _ => throw StateError('حالة حضور غير معروفة.'),
  };

  static String _friendlyError(PostgrestException error) {
    final String message = error.message;
    if (message.contains('Match is full')) {
      return 'الفريق اكتمل. اختار «مش جاي» أو جرّب ماتش تاني.';
    }
    if (message.contains('invalid or expired')) {
      return 'رابط الدعوة غير صالح أو انتهت صلاحيته.';
    }
    if (message.contains('permission') || message.contains('required')) {
      return 'سجّل الدخول بالحساب المناسب ثم حاول تاني.';
    }
    return 'تعذّر تحديث فريق الماتش. حاول تاني.';
  }
}
