import 'package:flutter/material.dart';

import '../../../app/router.dart';
import '../../../shared/widgets/app_page_app_bar.dart';
import '../../auth/domain/app_user.dart';
import '../../bookings/domain/booking.dart';
import '../../bookings/domain/booking_repository.dart';
import '../../bookings/presentation/player_bottom_navigation.dart';
import '../../slots/domain/slot_repository.dart';
import '../../slots/domain/time_slot.dart';
import '../../slots/presentation/available_slots_screen.dart';
import '../domain/in_app_notification.dart';
import '../domain/notification_repository.dart';

class NotificationCenterScreen extends StatelessWidget {
  const NotificationCenterScreen({
    super.key,
    required this.user,
    required this.notificationRepository,
    required this.bookingRepository,
    required this.slotRepository,
  });

  final AppUser user;
  final NotificationRepository notificationRepository;
  final BookingRepository bookingRepository;
  final SlotRepository slotRepository;

  NotificationAudience get _audience => user.role == UserRole.admin
      ? NotificationAudience.admin
      : NotificationAudience.player;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: const AppPageAppBar(title: 'الإشعارات'),
    body: StreamBuilder<List<InAppNotification>>(
      stream: notificationRepository.watchNotificationsFor(_audience),
      builder:
          (
            BuildContext context,
            AsyncSnapshot<List<InAppNotification>> snapshot,
          ) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final List<InAppNotification> notifications = snapshot.data!;
            if (notifications.isEmpty) {
              return const Center(child: Text('مفيش إشعارات جديدة دلوقتي.'));
            }
            return ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: notifications.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (BuildContext context, int index) =>
                  _NotificationCard(
                    notification: notifications[index],
                    isAdmin: _audience == NotificationAudience.admin,
                    onRead: () => notificationRepository.markAsRead(
                      notifications[index].id,
                    ),
                    onConfirm: () => _confirm(context, notifications[index]),
                    onCancel: () => _cancel(context, notifications[index]),
                    onEdit: () => Navigator.of(
                      context,
                    ).pushNamed(AppRouter.adminBookingListRoute),
                    onMatchDetails: () =>
                        Navigator.of(context).pushReplacementNamed(
                          AppRouter.myBookingsRoute,
                          arguments: user.id,
                        ),
                    onBookSlot: (TimeSlot slot) => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => AvailableSlotsScreen(
                          player: user,
                          repository: slotRepository,
                          initialDay: slot.startTime,
                        ),
                      ),
                    ),
                  ),
            );
          },
    ),
    bottomNavigationBar: user.role == UserRole.player
        ? PlayerBottomNavigation(selectedIndex: 2, playerId: user.id)
        : null,
  );

  Future<void> _confirm(
    BuildContext context,
    InAppNotification notification,
  ) async {
    final Booking? booking = await _findBooking(notification.bookingReference);
    if (booking == null) {
      return;
    }
    await bookingRepository.updateBooking(
      booking.copyWith(status: BookingStatus.confirmed),
    );
    await notificationRepository.markAsRead(notification.id);
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('اتأكد الحجز.')));
    }
  }

  Future<void> _cancel(
    BuildContext context,
    InAppNotification notification,
  ) async {
    final String? reference = notification.bookingReference;
    if (reference == null) {
      return;
    }
    await bookingRepository.deleteBooking(reference);
    await notificationRepository.markAsRead(notification.id);
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('اتلغى الحجز.')));
    }
  }

  Future<Booking?> _findBooking(String? reference) async {
    if (reference == null) {
      return null;
    }
    final List<Booking> bookings = await bookingRepository.getBookings();
    for (final Booking booking in bookings) {
      if (booking.reference == reference) {
        return booking;
      }
    }
    return null;
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.notification,
    required this.isAdmin,
    required this.onRead,
    required this.onConfirm,
    required this.onCancel,
    required this.onEdit,
    required this.onMatchDetails,
    required this.onBookSlot,
  });
  final InAppNotification notification;
  final bool isAdmin;
  final VoidCallback onRead;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;
  final VoidCallback onEdit;
  final VoidCallback onMatchDetails;
  final ValueChanged<TimeSlot> onBookSlot;

  @override
  Widget build(BuildContext context) => Card(
    color: notification.isRead
        ? null
        : Theme.of(context).colorScheme.secondaryContainer,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                notification.isRead
                    ? Icons.notifications_none
                    : Icons.notifications,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  notification.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              if (!notification.isRead)
                IconButton(
                  tooltip: 'تحديد كمقروء',
                  onPressed: onRead,
                  icon: const Icon(Icons.done),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(notification.description),
          if (notification.availableSlots.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...notification.availableSlots.map(
              (TimeSlot slot) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(child: Text(_timeRange(slot))),
                    FilledButton.tonal(
                      onPressed: () => onBookSlot(slot),
                      child: const Text('احجز دلوقتي'),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (isAdmin && notification.bookingReference != null) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.tonalIcon(
                  onPressed: onConfirm,
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('تأكيد'),
                ),
                OutlinedButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('تعديل'),
                ),
                TextButton.icon(
                  onPressed: onCancel,
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text('إلغاء'),
                ),
              ],
            ),
          ],
          if (!isAdmin &&
              notification.bookingReference != null &&
              notification.availableSlots.isEmpty) ...[
            const SizedBox(height: 12),
            FilledButton.tonalIcon(
              onPressed: onMatchDetails,
              icon: const Icon(Icons.emoji_events_outlined),
              label: const Text('إضافة تفاصيل المباراة'),
            ),
          ],
        ],
      ),
    ),
  );
}

String _timeRange(TimeSlot slot) =>
    '${_formatHour(slot.startTime)} - ${_formatHour(slot.endTime)}';
String _formatHour(DateTime time) {
  final int hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
  return '$hour:00 ${time.hour >= 12 ? 'م' : 'ص'}';
}
