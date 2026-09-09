import '../domain/slot_repository.dart';
import '../domain/time_slot.dart';

class MockSlotRepository implements SlotRepository {
  const MockSlotRepository();

  static DateTime get bookingStart {
    final DateTime now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  static DateTime get bookingEnd {
    final DateTime start = bookingStart;
    return DateTime(start.year, start.month + 1);
  }

  /// Retained as a compatibility alias for existing mock and dashboard flows.
  static DateTime get weekStart => bookingStart;
  static DateTime get firstDay => bookingStart;

  @override
  Future<List<TimeSlot>> getSlotsForDay(DateTime day) async {
    final DateTime normalizedDay = DateTime(day.year, day.month, day.day);

    if (normalizedDay == firstDay) {
      return [
        TimeSlot(
          id: 'slot-001',
          startTime: DateTime(2026, 9, 5, 16),
          endTime: DateTime(2026, 9, 5, 17),
          status: SlotStatus.available,
        ),
        TimeSlot(
          id: 'slot-002',
          startTime: DateTime(2026, 9, 5, 18),
          endTime: DateTime(2026, 9, 5, 19),
          status: SlotStatus.held,
        ),
        TimeSlot(
          id: 'slot-003',
          startTime: DateTime(2026, 9, 5, 20),
          endTime: DateTime(2026, 9, 5, 21),
          status: SlotStatus.booked,
        ),
      ];
    }

    return [
      TimeSlot(
        id: 'slot-004',
        startTime: DateTime(
          normalizedDay.year,
          normalizedDay.month,
          normalizedDay.day,
          17,
        ),
        endTime: DateTime(
          normalizedDay.year,
          normalizedDay.month,
          normalizedDay.day,
          18,
        ),
        status: SlotStatus.available,
      ),
      TimeSlot(
        id: 'slot-005',
        startTime: DateTime(
          normalizedDay.year,
          normalizedDay.month,
          normalizedDay.day,
          19,
        ),
        endTime: DateTime(
          normalizedDay.year,
          normalizedDay.month,
          normalizedDay.day,
          20,
        ),
        status: SlotStatus.available,
      ),
    ];
  }

  @override
  Stream<List<TimeSlot>> watchSlotsForDay(DateTime day) async* {
    yield await getSlotsForDay(day);
  }
}
