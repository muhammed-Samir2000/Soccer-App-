import 'package:flutter_test/flutter_test.dart';
import 'package:soccer_booking_app/features/bookings/data/mock_booking_repository.dart';
import 'package:soccer_booking_app/features/bookings/domain/booking_draft.dart';
import 'package:soccer_booking_app/features/slots/data/mock_slot_repository.dart';
import 'package:soccer_booking_app/features/slots/domain/time_slot.dart';

void main() {
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
