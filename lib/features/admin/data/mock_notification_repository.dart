import 'dart:async';

import '../../bookings/domain/booking.dart';
import '../../bookings/domain/booking_activity.dart';
import '../../bookings/domain/booking_repository.dart';
import '../../slots/data/mock_slot_repository.dart';
import '../../slots/domain/slot_repository.dart';
import '../../slots/domain/time_slot.dart';
import '../domain/in_app_notification.dart';
import '../domain/notification_repository.dart';
import '../domain/notification_setting.dart';

class MockNotificationRepository implements NotificationRepository {
  MockNotificationRepository({this._bookingRepository, this._slotRepository})
    : _settings = <NotificationSetting>[
        const NotificationSetting(
          id: 'new-booking',
          title: 'حجز جديد',
          description: 'تنبيه للإدارة عند تسجيل حجز جديد.',
          enabled: true,
        ),
        const NotificationSetting(
          id: 'player-reminder',
          title: 'تذكير اللاعب',
          description: 'تذكير قبل الموعد بـ24 ساعة.',
          enabled: true,
        ),
        const NotificationSetting(
          id: 'empty-slots',
          title: 'الساعات الفاضية',
          description: 'ملخص يومي لساعات بكرة الفاضية.',
          enabled: false,
        ),
      ] {
    _bookingRepository?.watchActivities().listen(_handleBookingActivity);
  }

  final List<NotificationSetting> _settings;
  final BookingRepository? _bookingRepository;
  final SlotRepository? _slotRepository;
  final List<InAppNotification> _notifications = <InAppNotification>[];
  final StreamController<void> _changes = StreamController<void>.broadcast();
  bool _seededPlayerAvailability = false;
  final Set<String> _matchResultNotifications = <String>{};

  @override
  Future<List<NotificationSetting>> getSettings() async =>
      List.unmodifiable(_settings);

  @override
  Future<void> updateSetting(NotificationSetting setting) async {
    final int index = _settings.indexWhere(
      (NotificationSetting item) => item.id == setting.id,
    );
    if (index == -1) {
      throw StateError('Notification setting not found');
    }
    _settings[index] = setting;
  }

  @override
  Future<List<InAppNotification>> getNotificationsFor(
    NotificationAudience audience,
  ) async {
    if (audience == NotificationAudience.player) {
      await _seedPlayerAvailability();
      await _seedMatchResultPrompts();
    }
    final List<InAppNotification> result =
        _notifications
            .where((InAppNotification item) => item.audience == audience)
            .toList()
          ..sort(
            (InAppNotification first, InAppNotification second) =>
                second.createdAt.compareTo(first.createdAt),
          );
    return List<InAppNotification>.unmodifiable(result);
  }

  @override
  Stream<List<InAppNotification>> watchNotificationsFor(
    NotificationAudience audience,
  ) async* {
    yield await getNotificationsFor(audience);
    await for (final _ in _changes.stream) {
      yield await getNotificationsFor(audience);
    }
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    final int index = _notifications.indexWhere(
      (InAppNotification item) => item.id == notificationId,
    );
    if (index == -1) {
      return;
    }
    _notifications[index] = _notifications[index].copyWith(isRead: true);
    _changes.add(null);
  }

  Future<void> _seedPlayerAvailability() async {
    if (_seededPlayerAvailability || _slotRepository == null) {
      return;
    }
    _seededPlayerAvailability = true;
    final DateTime today = MockSlotRepository.weekStart;
    final DateTime tomorrow = today.add(const Duration(days: 1));
    await _addAvailabilityNotification(
      title: 'ساعات فاضية النهارده',
      day: today,
      id: 'availability-today',
    );
    await _addAvailabilityNotification(
      title: 'متاح بكرة',
      day: tomorrow,
      id: 'availability-tomorrow',
    );
  }

  Future<void> _seedMatchResultPrompts() async {
    if (_bookingRepository == null) {
      return;
    }
    final DateTime eligibleBefore = DateTime.now().subtract(
      const Duration(hours: 1),
    );
    final List<Booking> bookings = await _bookingRepository
        .getBookingsForPlayer('player-001');
    for (final Booking booking in bookings) {
      if (booking.slot.endTime.isAfter(eligibleBefore) ||
          booking.matchResult != null ||
          !_matchResultNotifications.add(booking.reference)) {
        continue;
      }
      _notifications.add(
        InAppNotification(
          id: 'match-result-${booking.reference}',
          audience: NotificationAudience.player,
          title: 'شاركنا نجوم الماتش',
          description:
              'عدت ساعة على ميعاد ${_timeLabel(booking)}. ضيف رجل المباراة وأفضل هدف.',
          createdAt: booking.slot.endTime.add(const Duration(hours: 1)),
          bookingReference: booking.reference,
        ),
      );
    }
  }

  Future<void> _addAvailabilityNotification({
    required String title,
    required DateTime day,
    required String id,
  }) async {
    final List<TimeSlot> available = (await _slotRepository!.getSlotsForDay(
      day,
    )).where((TimeSlot slot) => slot.isAvailable).toList();
    if (available.isEmpty) {
      return;
    }
    _notifications.add(
      InAppNotification(
        id: id,
        audience: NotificationAudience.player,
        title: title,
        description: 'اختار ساعة مناسبة واحجزها قبل ما تتملي.',
        createdAt: day,
        availableSlots: available,
      ),
    );
  }

  void _handleBookingActivity(BookingActivity activity) {
    if (!_isEnabled('new-booking')) {
      return;
    }
    final Booking booking = activity.booking;
    final String action = switch (activity.type) {
      BookingActivityType.created => 'حجز جديد',
      BookingActivityType.updated => 'تم تعديل حجز',
      BookingActivityType.deleted => 'تم إلغاء حجز',
    };
    final String services = booking.services.isEmpty
        ? 'من غير خدمات إضافية'
        : booking.services.map((service) => service.name).join('، ');
    _notifications.add(
      InAppNotification(
        id: '${activity.type.name}-${booking.reference}-${DateTime.now().microsecondsSinceEpoch}',
        audience: NotificationAudience.admin,
        title: action,
        description:
            '${booking.playerName} | ${booking.phoneNumber.isEmpty ? 'رقم الهاتف غير متاح' : booking.phoneNumber}\n${_timeLabel(booking)} | $services',
        createdAt: DateTime.now(),
        bookingReference: booking.reference,
      ),
    );
    _changes.add(null);
  }

  bool _isEnabled(String id) => _settings.any(
    (NotificationSetting setting) => setting.id == id && setting.enabled,
  );
}

String _timeLabel(Booking booking) =>
    '${_formatHour(booking.slot.startTime)} - ${_formatHour(booking.slot.endTime)}';

String _formatHour(DateTime time) {
  final int hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
  return '$hour:00 ${time.hour >= 12 ? 'م' : 'ص'}';
}
