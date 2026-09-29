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
    this.inviteToken,
    required List<MatchParticipant> participants,
    int? goingCount,
  }) : assert(goingCount == null || goingCount >= 0),
       participants = List<MatchParticipant>.unmodifiable(participants),
       _goingCount = goingCount;

  final String bookingReference;
  final String organizerId;
  final String organizerName;
  final DateTime startsAt;
  final DateTime endsAt;
  final int fieldNumber;
  final int capacity;

  /// Available only immediately after the organizer explicitly creates or
  /// refreshes a share link. Production stores only a token hash.
  final String? inviteToken;
  final List<MatchParticipant> participants;
  final int? _goingCount;

  /// Invite previews receive an aggregate count, not the team's identities.
  int get goingCount =>
      _goingCount ??
      participants
          .where(
            (MatchParticipant participant) =>
                participant.status == MatchParticipationStatus.going,
          )
          .length;

  int get remainingSpots => capacity - goingCount;

  bool get isFull => remainingSpots <= 0;

  BookingMatch copyWith({
    List<MatchParticipant>? participants,
    String? inviteToken,
    int? goingCount,
  }) => BookingMatch(
    bookingReference: bookingReference,
    organizerId: organizerId,
    organizerName: organizerName,
    startsAt: startsAt,
    endsAt: endsAt,
    fieldNumber: fieldNumber,
    capacity: capacity,
    inviteToken: inviteToken ?? this.inviteToken,
    participants: participants ?? this.participants,
    goingCount: goingCount ?? _goingCount,
  );
}
