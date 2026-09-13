import 'booking.dart';
import 'booking_match.dart';
import 'match_participant.dart';

abstract interface class MatchRepository {
  Future<BookingMatch> getOrCreateForBooking(
    Booking booking, {
    int capacity = 10,
  });

  Future<BookingMatch?> getForBooking(String bookingReference);

  /// Resolves a share-link token without exposing booking contact information.
  Future<BookingMatch?> getByInviteToken(String inviteToken);

  Future<BookingMatch> respondToInvite({
    required String inviteToken,
    required String playerId,
    required String playerName,
    required MatchParticipationStatus status,
  });
}
