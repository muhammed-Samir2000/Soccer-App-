import 'match_participant.dart';

class BookingMatch {
  BookingMatch({
    required this.bookingReference,
    required this.organizerId,
    required this.organizerName,
    required this.startsAt,
    required this.endsAt,
    required this.fieldNumber,
    required this.capacity,
    required this.inviteToken,
    required List<MatchParticipant> participants,
  }) : participants = List<MatchParticipant>.unmodifiable(participants);

  final String bookingReference;
  final String organizerId;
  final String organizerName;
  final DateTime startsAt;
  final DateTime endsAt;
  final int fieldNumber;
  final int capacity;

  /// Mock-only value. Production stores only a token hash and resolves it by RPC.
  final String inviteToken;
  final List<MatchParticipant> participants;

  int get goingCount => participants
      .where(
        (MatchParticipant participant) =>
            participant.status == MatchParticipationStatus.going,
      )
      .length;

  int get remainingSpots => capacity - goingCount;

  bool get isFull => remainingSpots <= 0;

  BookingMatch copyWith({List<MatchParticipant>? participants}) => BookingMatch(
    bookingReference: bookingReference,
    organizerId: organizerId,
    organizerName: organizerName,
    startsAt: startsAt,
    endsAt: endsAt,
    fieldNumber: fieldNumber,
    capacity: capacity,
    inviteToken: inviteToken,
    participants: participants ?? this.participants,
  );
}
