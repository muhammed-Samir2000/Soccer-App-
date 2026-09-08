import 'booking.dart';
import 'booking_draft.dart';
import 'match_result.dart';

abstract interface class BookingRepository {
  Future<Booking> createBooking(BookingDraft draft);

  Future<List<Booking>> getBookings();

  Future<List<Booking>> getBookingsForPlayer(String playerId);

  Future<Booking> createTentativeBooking({
    required String playerName,
    required String phoneNumber,
    required BookingDraft draft,
  });

  Future<Booking> createRecurringBooking({
    required String playerName,
    required String phoneNumber,
    required BookingDraft draft,
  });

  Future<void> saveMatchResult({
    required String bookingReference,
    required MatchResult result,
  });

  Future<void> updateBooking(Booking booking);

  Future<void> deleteBooking(String bookingReference);
}
