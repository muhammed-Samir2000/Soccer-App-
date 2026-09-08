import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soccer_booking_app/features/admin/presentation/admin_week_screen.dart';
import 'package:soccer_booking_app/features/bookings/data/mock_booking_repository.dart';
import 'package:soccer_booking_app/features/bookings/domain/booking.dart';
import 'package:soccer_booking_app/features/slots/data/mock_slot_repository.dart';

void main() {
  testWidgets('registers a player from an available admin hour', (
    WidgetTester tester,
  ) async {
    final MockBookingRepository repository = MockBookingRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: AdminDayScreen(
            day: MockSlotRepository.weekStart,
            repository: repository,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('تسجيل لاعب'), findsNWidgets(5));
    await tester.tap(find.text('تسجيل لاعب').first);
    await tester.pumpAndSettle();

    expect(find.text('تسجيل لاعب جديد'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).at(0), 'الكابتن عمر');
    await tester.enterText(find.byType(TextFormField).at(1), '01098765432');
    await tester.tap(find.text('حفظ الحجز'));
    await tester.pumpAndSettle();

    final List<Booking> bookings = await repository.getBookings();
    expect(bookings, hasLength(1));
    expect(bookings.single.playerName, 'الكابتن عمر');
    expect(bookings.single.status, BookingStatus.confirmed);
    expect(bookings.single.fieldNumber, 1);
  });
}
