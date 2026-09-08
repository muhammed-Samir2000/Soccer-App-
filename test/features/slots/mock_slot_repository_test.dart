import 'package:flutter_test/flutter_test.dart';
import 'package:soccer_booking_app/features/slots/data/mock_slot_repository.dart';
import 'package:soccer_booking_app/features/slots/domain/time_slot.dart';

void main() {
  test(
    'returns available, held, and booked slots for the first demo day',
    () async {
      const MockSlotRepository repository = MockSlotRepository();

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
    },
  );
}
