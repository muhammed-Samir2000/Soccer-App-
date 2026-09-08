enum SlotStatus { available, held, booked }

class TimeSlot {
  const TimeSlot({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.status,
  });

  final String id;
  final DateTime startTime;
  final DateTime endTime;
  final SlotStatus status;

  bool get isAvailable => status == SlotStatus.available;
}
