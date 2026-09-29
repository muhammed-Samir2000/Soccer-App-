import 'booking.dart';
import 'booking_match.dart';
import 'match_participant.dart';

abstract interface class MatchRepository {
  /// Reads a match and its roster only for its organizer or authorized staff.
  /// It does not disclose the raw invitation token.
  Future<BookingMatch?> getForBooking(String bookingReference);

  /// Creates a new share token only after the organizer asks for one. Calling
  /// this again intentionally revokes the previous token.
  Future<BookingMatch> createOrRefreshInviteForBooking(
    Booking booking, {
    int capacity = 10,
  });

  /// Resolves a share-link token without exposing booking contact information.
  Future<BookingMatch?> getByInviteToken(String inviteToken);

  Future<BookingMatch> respondToInvite({
    required String inviteToken,
    required String playerId,
    required String playerName,
    required MatchParticipationStatus status,
  });
}
