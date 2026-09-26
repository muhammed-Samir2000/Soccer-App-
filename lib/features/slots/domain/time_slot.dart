import '../../bookings/domain/optional_service.dart';

enum SlotStatus { available, held, booked }

class TimeSlot {
  const TimeSlot({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.status,
    this.basePrice = 800,
    this.services,
  });

  final String id;
  final DateTime startTime;
  final DateTime endTime;
  final SlotStatus status;
  final int basePrice;
  /// Null is the legacy demo catalog; an empty list means no live extras.
  final List<OptionalService>? services;

  bool get isAvailable => status == SlotStatus.available;
}
