enum MatchParticipationStatus { invited, going, notGoing }

class MatchParticipant {
  const MatchParticipant({
    required this.playerId,
    required this.displayName,
    required this.status,
    this.isOrganizer = false,
  });

  final String playerId;
  final String displayName;
  final MatchParticipationStatus status;
  final bool isOrganizer;

  MatchParticipant copyWith({MatchParticipationStatus? status}) =>
      MatchParticipant(
        playerId: playerId,
        displayName: displayName,
        status: status ?? this.status,
        isOrganizer: isOrganizer,
      );
}
