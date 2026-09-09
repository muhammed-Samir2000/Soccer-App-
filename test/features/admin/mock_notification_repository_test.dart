import 'package:flutter_test/flutter_test.dart';
import 'package:soccer_booking_app/features/admin/data/mock_notification_repository.dart';
import 'package:soccer_booking_app/features/admin/domain/in_app_notification.dart';
import 'package:soccer_booking_app/features/bookings/data/mock_booking_repository.dart';
import 'package:soccer_booking_app/features/bookings/domain/booking.dart';
import 'package:soccer_booking_app/features/bookings/domain/booking_draft.dart';
import 'package:soccer_booking_app/features/bookings/domain/optional_service.dart';
import 'package:soccer_booking_app/features/slots/data/mock_slot_repository.dart';
import 'package:soccer_booking_app/features/slots/domain/time_slot.dart';

void main() {
  test('creates an admin notification from a new booking activity', () async {
    final MockBookingRepository bookings = MockBookingRepository();
    final MockNotificationRepository notifications = MockNotificationRepository(
      bookingRepository: bookings,
      slotRepository: const MockSlotRepository(),
    );
    await bookings.createAdminBooking(
      playerName: 'الكابتن عمر',
      phoneNumber: '01012345678',
      status: BookingStatus.tentative,
      draft: BookingDraft(
        slot: TimeSlot(
          id: 'test-slot',
          startTime: DateTime(2026, 9, 5, 16),
          endTime: DateTime(2026, 9, 5, 17),
          status: SlotStatus.available,
        ),
        basePrice: 800,
        selectedServices: const <OptionalService>[
          OptionalService(id: 'drinks', name: 'مشروبات ساقعة', price: 60),
        ],
      ),
    );

    final messages = await notifications.getNotificationsFor(
      NotificationAudience.admin,
    );

    expect(messages.single.title, 'حجز جديد');
    expect(messages.single.description, contains('الكابتن عمر'));
    expect(messages.single.description, contains('01012345678'));
    expect(messages.single.description, contains('مشروبات ساقعة'));
  });

  test(
    'provides player availability notifications with booking actions',
    () async {
      final MockNotificationRepository notifications =
          MockNotificationRepository(
            slotRepository: const MockSlotRepository(),
          );

      final messages = await notifications.getNotificationsFor(
        NotificationAudience.player,
      );

      expect(messages, hasLength(2));
      expect(messages.first.availableSlots, isNotEmpty);
    },
  );
}
