import 'match_participant.dart';

class BookingMatch {
  BookingMatch({
    required this.bookingReference,
    required this.organizerId,
    required this.capacity,
    required this.inviteToken,
    required List<MatchParticipant> participants,
  }) : participants = List<MatchParticipant>.unmodifiable(participants);

  final String bookingReference;
  final String organizerId;
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
    capacity: capacity,
    inviteToken: inviteToken,
    participants: participants ?? this.participants,
  );
}
