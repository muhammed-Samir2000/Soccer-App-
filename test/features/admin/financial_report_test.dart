import 'package:flutter_test/flutter_test.dart';
import 'package:soccer_booking_app/features/admin/domain/financial_report.dart';
import 'package:soccer_booking_app/features/bookings/domain/booking.dart';
import 'package:soccer_booking_app/features/slots/domain/time_slot.dart';

void main() {
  test('calculates collected revenue and compares the prior period', () {
    final FinancialReport report = FinancialReport.fromBookings(
      bookings: <Booking>[
        _booking(
          'apr-confirmed',
          DateTime(2026, 4, 10),
          800,
          BookingStatus.confirmed,
        ),
        _booking(
          'may-recurring',
          DateTime(2026, 5, 10),
          900,
          BookingStatus.recurring,
        ),
        _booking(
          'jun-confirmed',
          DateTime(2026, 6, 10),
          1200,
          BookingStatus.confirmed,
        ),
        _booking(
          'jun-tentative',
          DateTime(2026, 6, 11),
          700,
          BookingStatus.tentative,
        ),
      ],
      startMonth: DateTime(2026, 6),
      endMonth: DateTime(2026, 6),
    );

    expect(report.collectedAmount, 1200);
    expect(report.pendingAmount, 700);
    expect(report.collectedBookings, 1);
    expect(report.comparisonAmount, 900);
    expect(report.differenceFromPrevious, 300);
    expect(report.trend.single.collectedAmount, 1200);
  });
}

Booking _booking(
  String reference,
  DateTime start,
  int totalPrice,
  BookingStatus status,
) => Booking(
  reference: reference,
  playerId: 'player-$reference',
  playerName: 'فريق الاختبار',
  slot: TimeSlot(
    id: 'slot-$reference',
    startTime: start,
    endTime: start.add(const Duration(hours: 1)),
    status: SlotStatus.booked,
  ),
  services: const [],
  totalPrice: totalPrice,
  status: status,
  fieldNumber: 1,
);
