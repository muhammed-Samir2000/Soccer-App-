import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soccer_booking_app/features/admin/presentation/admin_bookings_screen.dart';
import 'package:soccer_booking_app/features/bookings/data/mock_booking_repository.dart';
import 'package:soccer_booking_app/features/bookings/domain/booking.dart';
import 'package:soccer_booking_app/features/bookings/domain/booking_draft.dart';
import 'package:soccer_booking_app/features/bookings/domain/booking_repository.dart';
import 'package:soccer_booking_app/features/bookings/domain/match_result.dart';

void main() {
  testWidgets('shows booking details from the repository', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: AdminBookingsScreen(
            repository: MockBookingRepository.seeded(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('حجوزات الأدمن'), findsOneWidget);
    expect(find.text('الكابتن كريم'), findsOneWidget);
    expect(find.textContaining('HAGZ-1000'), findsOneWidget);
    expect(find.text('مؤكد'), findsAtLeastNWidgets(1));
    expect(find.text('حكم'), findsOneWidget);
    expect(find.textContaining('1100'), findsOneWidget);
  });

  testWidgets('shows a clear empty state', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: AdminBookingsScreen(repository: _EmptyBookingRepository()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('مفيش حجوزات لسه.'), findsOneWidget);
  });

  testWidgets('offers a retry action after a repository error', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: AdminBookingsScreen(repository: _FailingBookingRepository()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('حاول تاني تحميل الحجوزات'), findsOneWidget);
  });
}

class _EmptyBookingRepository implements BookingRepository {
  @override
  Future<Booking> createBooking(BookingDraft draft) =>
      throw UnimplementedError();

  @override
  Future<List<Booking>> getBookings() async => <Booking>[];

  @override
  Future<Booking> createRecurringBooking({
    required String playerName,
    required String phoneNumber,
    required BookingDraft draft,
  }) => throw UnimplementedError();

  @override
  Future<Booking> createTentativeBooking({
    required String playerName,
    required String phoneNumber,
    required BookingDraft draft,
  }) => throw UnimplementedError();

  @override
  Future<Booking> createAdminBooking({
    required String playerName,
    required String phoneNumber,
    required BookingDraft draft,
    required BookingStatus status,
  }) => throw UnimplementedError();

  @override
  Future<void> updateFieldCount(int fieldCount) async {}

  @override
  Future<List<Booking>> getBookingsForPlayer(String playerId) async =>
      <Booking>[];

  @override
  Future<void> saveMatchResult({
    required String bookingReference,
    required MatchResult result,
  }) async {}

  @override
  Future<void> updateBooking(Booking booking) async {}

  @override
  Future<void> deleteBooking(String bookingReference) async {}
}

class _FailingBookingRepository implements BookingRepository {
  @override
  Future<Booking> createBooking(BookingDraft draft) =>
      throw UnimplementedError();

  @override
  Future<List<Booking>> getBookings() =>
      Future<List<Booking>>.error(StateError('Mock load failure'));

  @override
  Future<Booking> createRecurringBooking({
    required String playerName,
    required String phoneNumber,
    required BookingDraft draft,
  }) => throw UnimplementedError();

  @override
  Future<Booking> createTentativeBooking({
    required String playerName,
    required String phoneNumber,
    required BookingDraft draft,
  }) => throw UnimplementedError();

  @override
  Future<Booking> createAdminBooking({
    required String playerName,
    required String phoneNumber,
    required BookingDraft draft,
    required BookingStatus status,
  }) => throw UnimplementedError();

  @override
  Future<void> updateFieldCount(int fieldCount) async {}

  @override
  Future<List<Booking>> getBookingsForPlayer(String playerId) =>
      Future<List<Booking>>.error(StateError('Mock load failure'));

  @override
  Future<void> saveMatchResult({
    required String bookingReference,
    required MatchResult result,
  }) async {}

  @override
  Future<void> updateBooking(Booking booking) async {}

  @override
  Future<void> deleteBooking(String bookingReference) async {}
}
