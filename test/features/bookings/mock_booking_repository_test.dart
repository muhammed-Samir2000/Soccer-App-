import 'package:flutter_test/flutter_test.dart';
import 'package:soccer_booking_app/features/bookings/data/mock_booking_repository.dart';
import 'package:soccer_booking_app/features/bookings/data/mock_optional_services.dart';
import 'package:soccer_booking_app/features/bookings/domain/booking.dart';
import 'package:soccer_booking_app/features/bookings/domain/booking_draft.dart';
import 'package:soccer_booking_app/features/slots/domain/time_slot.dart';

void main() {
  final TimeSlot slot = TimeSlot(
    id: 'slot-test',
    startTime: DateTime(2026, 9, 7, 16),
    endTime: DateTime(2026, 9, 7, 17),
    status: SlotStatus.available,
  );

  test('creates a confirmed booking that matches the final draft', () async {
    final BookingDraft draft = BookingDraft(
      slot: slot,
      basePrice: 800,
      selectedServices: [MockOptionalServices.all.first],
    );
    final MockBookingRepository repository = MockBookingRepository();

    final Booking booking = await repository.createBooking(draft);

    expect(booking.reference, 'HAGZ-1001');
    expect(booking.playerName, 'الكابتن أحمد');
    expect(booking.status, BookingStatus.confirmed);
    expect(booking.slot, same(slot));
    expect(booking.services, draft.selectedServices);
    expect(booking.totalPrice, draft.totalPrice);
  });

  test('uses a new reference for every mock booking', () async {
    final BookingDraft draft = BookingDraft(slot: slot, basePrice: 800);
    final MockBookingRepository repository = MockBookingRepository();

    final Booking firstBooking = await repository.createBooking(draft);
    final Booking secondBooking = await repository.createBooking(draft);

    expect(firstBooking.reference, 'HAGZ-1001');
    expect(secondBooking.reference, 'HAGZ-1002');
  });

  test(
    'returns initial and newly created bookings through the repository',
    () async {
      final MockBookingRepository repository = MockBookingRepository.seeded();
      final BookingDraft draft = BookingDraft(slot: slot, basePrice: 800);

      await repository.createBooking(draft);
      final List<Booking> bookings = await repository.getBookings();

      expect(bookings, hasLength(2));
      expect(bookings.first.reference, 'HAGZ-1000');
      expect(bookings.last.reference, 'HAGZ-1001');
    },
  );

  test('assigns matching bookings to the three fields in order', () async {
    final MockBookingRepository repository = MockBookingRepository();
    final BookingDraft draft = BookingDraft(slot: slot, basePrice: 800);

    final Booking first = await repository.createBooking(draft);
    final Booking second = await repository.createTentativeBooking(
      playerName: 'الكابتن علي',
      phoneNumber: '01000000000',
      draft: draft,
    );
    final Booking third = await repository.createRecurringBooking(
      playerName: 'مجموعة الجمعة',
      phoneNumber: '01100000000',
      draft: draft,
    );

    expect(
      [first.fieldNumber, second.fieldNumber, third.fieldNumber],
      [1, 2, 3],
    );
    expect(second.status, BookingStatus.tentative);
    expect(third.status, BookingStatus.recurring);
  });

  test('updates and deletes a booking for admin management', () async {
    final MockBookingRepository repository = MockBookingRepository();
    final Booking created = await repository.createBooking(
      BookingDraft(slot: slot, basePrice: 800),
    );

    await repository.updateBooking(
      created.copyWith(playerName: 'الكابتن سامح'),
    );
    expect((await repository.getBookings()).single.playerName, 'الكابتن سامح');

    await repository.deleteBooking(created.reference);
    expect(await repository.getBookings(), isEmpty);
  });

  test('registers an admin player and assigns the next free field', () async {
    final MockBookingRepository repository = MockBookingRepository();
    final BookingDraft draft = BookingDraft(slot: slot, basePrice: 800);

    await repository.createBooking(draft);
    final Booking booking = await repository.createAdminBooking(
      playerName: 'الكابتن محمد',
      phoneNumber: '01012345678',
      draft: draft,
      status: BookingStatus.confirmed,
    );

    expect(booking.playerName, 'الكابتن محمد');
    expect(booking.playerId, 'phone-01012345678');
    expect(booking.status, BookingStatus.confirmed);
    expect(booking.fieldNumber, 2);
  });

  test('uses the configured field count for new booking allocation', () async {
    final MockBookingRepository repository = MockBookingRepository();
    final BookingDraft draft = BookingDraft(slot: slot, basePrice: 800);
    await repository.updateFieldCount(4);

    final List<Booking> bookings = await Future.wait(
      List<Future<Booking>>.generate(4, (_) => repository.createBooking(draft)),
    );

    expect(bookings.map((Booking booking) => booking.fieldNumber), <int>[
      1,
      2,
      3,
      4,
    ]);
  });
}
