import '../domain/booking.dart';
import '../domain/booking_match.dart';
import '../domain/match_participant.dart';
import '../domain/match_repository.dart';

class MockMatchRepository implements MatchRepository {
  int _nextTokenNumber = 1;
  final Map<String, BookingMatch> _matchesByBooking = <String, BookingMatch>{};

  @override
  Future<BookingMatch> getOrCreateForBooking(
    Booking booking, {
    int capacity = 10,
  }) async {
    if (capacity < 2 || capacity > 30) {
      throw ArgumentError('عدد اللاعبين لازم يكون بين 2 و30.');
    }
    final BookingMatch? existing = _matchesByBooking[booking.reference];
    if (existing != null) {
      return existing;
    }
    final BookingMatch match = BookingMatch(
      bookingReference: booking.reference,
      organizerId: booking.playerId,
      organizerName: booking.playerName,
      startsAt: booking.slot.startTime,
      endsAt: booking.slot.endTime,
      fieldNumber: booking.fieldNumber,
      capacity: capacity,
      inviteToken: 'demo-${_nextTokenNumber++}-${booking.reference}',
      participants: <MatchParticipant>[
        MatchParticipant(
          playerId: booking.playerId,
          displayName: booking.playerName,
          status: MatchParticipationStatus.going,
          isOrganizer: true,
        ),
      ],
    );
    _matchesByBooking[booking.reference] = match;
    return match;
  }

  @override
  Future<BookingMatch?> getForBooking(String bookingReference) async =>
      _matchesByBooking[bookingReference];

  @override
  Future<BookingMatch?> getByInviteToken(String inviteToken) async {
    for (final BookingMatch match in _matchesByBooking.values) {
      if (match.inviteToken == inviteToken) {
        return match;
      }
    }
    return _restoreDemoInvite(inviteToken);
  }

  /// Lets a copied demo link open in a fresh browser tab. Production never
  /// reconstructs invitations from a token; it resolves a hashed token by RPC.
  BookingMatch? _restoreDemoInvite(String inviteToken) {
    final RegExpMatch? tokenMatch = RegExp(
      r'^demo-\d+-(HAGZ-[A-Z0-9-]+)$',
    ).firstMatch(inviteToken);
    if (tokenMatch == null) {
      return null;
    }
    final String bookingReference = tokenMatch.group(1)!;
    final BookingMatch? existing = _matchesByBooking[bookingReference];
    if (existing != null) {
      return existing;
    }
    final BookingMatch match = BookingMatch(
      bookingReference: bookingReference,
      organizerId: 'demo-organizer',
      organizerName: 'الكابتن أحمد',
      startsAt: DateTime(2026, 9, 15, 19),
      endsAt: DateTime(2026, 9, 15, 20),
      fieldNumber: 1,
      capacity: 10,
      inviteToken: inviteToken,
      participants: const <MatchParticipant>[
        MatchParticipant(
          playerId: 'demo-organizer',
          displayName: 'الكابتن أحمد',
          status: MatchParticipationStatus.going,
          isOrganizer: true,
        ),
      ],
    );
    _matchesByBooking[bookingReference] = match;
    return match;
  }

  @override
  Future<BookingMatch> respondToInvite({
    required String inviteToken,
    required String playerId,
    required String playerName,
    required MatchParticipationStatus status,
  }) async {
    final BookingMatch? match = await getByInviteToken(inviteToken);
    if (match == null) {
      throw StateError('رابط الدعوة غير صالح أو انتهت صلاحيته.');
    }
    final int existingIndex = match.participants.indexWhere(
      (MatchParticipant participant) => participant.playerId == playerId,
    );
    if (status == MatchParticipationStatus.going &&
        existingIndex == -1 &&
        match.isFull) {
      throw StateError(
        'الفريق اكتمل. تقدر تنضم لقائمة الانتظار بعد ربط الخلفية.',
      );
    }
    final List<MatchParticipant> participants = List<MatchParticipant>.from(
      match.participants,
    );
    final MatchParticipant participant = MatchParticipant(
      playerId: playerId,
      displayName: playerName.trim(),
      status: status,
    );
    if (existingIndex == -1) {
      participants.add(participant);
    } else if (!participants[existingIndex].isOrganizer) {
      participants[existingIndex] = participant;
    }
    final BookingMatch updated = match.copyWith(participants: participants);
    _matchesByBooking[updated.bookingReference] = updated;
    return updated;
  }
}
