import '../../slots/domain/time_slot.dart';

enum NotificationAudience { admin, player }

class InAppNotification {
  InAppNotification({
    required this.id,
    required this.audience,
    required this.title,
    required this.description,
    required this.createdAt,
    this.bookingReference,
    List<TimeSlot> availableSlots = const <TimeSlot>[],
    this.isRead = false,
  }) : availableSlots = List<TimeSlot>.unmodifiable(availableSlots);

  final String id;
  final NotificationAudience audience;
  final String title;
  final String description;
  final DateTime createdAt;
  final String? bookingReference;
  final List<TimeSlot> availableSlots;
  final bool isRead;

  InAppNotification copyWith({bool? isRead}) => InAppNotification(
    id: id,
    audience: audience,
    title: title,
    description: description,
    createdAt: createdAt,
    bookingReference: bookingReference,
    availableSlots: availableSlots,
    isRead: isRead ?? this.isRead,
  );
}
