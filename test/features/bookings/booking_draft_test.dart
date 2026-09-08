import 'package:flutter_test/flutter_test.dart';
import 'package:soccer_booking_app/features/bookings/data/mock_optional_services.dart';
import 'package:soccer_booking_app/features/bookings/domain/booking_draft.dart';
import 'package:soccer_booking_app/features/slots/domain/time_slot.dart';

void main() {
  final TimeSlot slot = TimeSlot(
    id: 'slot-test',
    startTime: DateTime(2026, 9, 7, 16),
    endTime: DateTime(2026, 9, 7, 17),
    status: SlotStatus.available,
  );

  test('calculates the total from base price and selected services', () {
    BookingDraft draft = BookingDraft(slot: slot, basePrice: 800);

    draft = draft.toggleService(MockOptionalServices.all[0]);
    draft = draft.toggleService(MockOptionalServices.all[2]);

    expect(draft.servicesTotal, 360);
    expect(draft.totalPrice, 1160);
    expect(draft.selectedServices, hasLength(2));
  });

  test('removes a selected service when it is toggled again', () {
    BookingDraft draft = BookingDraft(slot: slot, basePrice: 800);

    draft = draft.toggleService(MockOptionalServices.all[1]);
    draft = draft.toggleService(MockOptionalServices.all[1]);

    expect(draft.selectedServices, isEmpty);
    expect(draft.totalPrice, 800);
  });

  test('offers only the approved optional services', () {
    expect(MockOptionalServices.all.map((service) => service.id), [
      'drinks',
      'photography',
      'referee',
    ]);
  });
}
