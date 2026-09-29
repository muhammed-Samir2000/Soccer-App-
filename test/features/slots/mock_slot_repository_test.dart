import 'package:flutter_test/flutter_test.dart';
import 'package:soccer_booking_app/features/bookings/data/mock_booking_repository.dart';
import 'package:soccer_booking_app/features/bookings/domain/booking_draft.dart';
import 'package:soccer_booking_app/features/slots/data/mock_slot_repository.dart';
import 'package:soccer_booking_app/features/slots/domain/time_slot.dart';

void main() {
  test(
    'returns bookable slots for future dates across month boundaries',
    () async {
      final MockBookingRepository bookings = MockBookingRepository();
      final MockSlotRepository repository = MockSlotRepository(bookings);
      final DateTime today = MockSlotRepository.bookingStart;
      final List<DateTime> futureDays = <DateTime>[
        today.add(const Duration(days: 1)),
        today.add(const Duration(days: 10)),
        DateTime(today.year, today.month + 1),
        DateTime(today.year, today.month + 6, 1),
      ];

      for (final DateTime day in futureDays) {
        final List<TimeSlot> slots = await repository.getSlotsForDay(day);
        expect(slots.where((TimeSlot slot) => slot.isAvailable), isNotEmpty);
      }

      final TimeSlot farFutureSlot = (await repository.getSlotsForDay(
        futureDays.last,
      )).firstWhere((TimeSlot slot) => slot.isAvailable);
      final booking = await bookings.createBooking(
        BookingDraft(slot: farFutureSlot, basePrice: 800),
      );
      expect(booking.slot.startTime, farFutureSlot.startTime);
    },
  );

  test(
    'returns available, held, and booked slots for the first demo day',
    () async {
      final MockBookingRepository bookings = MockBookingRepository();
      final MockSlotRepository repository = MockSlotRepository(bookings);

      final slots = await repository.getSlotsForDay(
        MockSlotRepository.firstDay,
      );

      expect(slots.map((slot) => slot.status), [
        SlotStatus.available,
        SlotStatus.held,
        SlotStatus.booked,
      ]);
      expect(slots.first.isAvailable, isTrue);
      expect(slots[1].isAvailable, isFalse);
      expect(slots[2].isAvailable, isFalse);
      expect(slots.first.startTime.day, MockSlotRepository.firstDay.day);
    },
  );

  test('marks a slot booked after every field is allocated', () async {
    final MockBookingRepository bookings = MockBookingRepository();
    final MockSlotRepository repository = MockSlotRepository(bookings);
    final TimeSlot slot = (await repository.getSlotsForDay(
      MockSlotRepository.firstDay,
    )).first;
    final BookingDraft draft = BookingDraft(slot: slot, basePrice: 800);

    await bookings.createBooking(draft);
    await bookings.createBooking(draft);
    await bookings.createBooking(draft);

    final List<TimeSlot> updated = await repository.getSlotsForDay(
      MockSlotRepository.firstDay,
    );
    expect(updated.first.status, SlotStatus.booked);
  });
}
