import 'booking.dart';

enum BookingActivityType { created, updated, deleted }

/// A future backend can publish the same activity stream from database events.
class BookingActivity {
  const BookingActivity({required this.type, required this.booking});

  final BookingActivityType type;
  final Booking booking;
}
