import '../../bookings/domain/booking.dart';
import '../../bookings/domain/booking_activity.dart';
import '../../bookings/domain/booking_repository.dart';
import '../domain/slot_repository.dart';
import '../domain/time_slot.dart';

class MockSlotRepository implements SlotRepository {
  MockSlotRepository(
    this._bookingRepository, {
    Future<int> Function()? fieldCountProvider,
  }) : _fieldCountProvider = fieldCountProvider ?? _defaultFieldCount;

  final BookingRepository _bookingRepository;
  final Future<int> Function() _fieldCountProvider;

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

    final List<TimeSlot> seededSlots = normalizedDay == firstDay
        ? <TimeSlot>[
            TimeSlot(
              id: 'slot-001',
              startTime: DateTime(
                normalizedDay.year,
                normalizedDay.month,
                normalizedDay.day,
                16,
              ),
              endTime: DateTime(
                normalizedDay.year,
                normalizedDay.month,
                normalizedDay.day,
                17,
              ),
              status: SlotStatus.available,
            ),
            TimeSlot(
              id: 'slot-002',
              startTime: DateTime(
                normalizedDay.year,
                normalizedDay.month,
                normalizedDay.day,
                18,
              ),
              endTime: DateTime(
                normalizedDay.year,
                normalizedDay.month,
                normalizedDay.day,
                19,
              ),
              status: SlotStatus.held,
            ),
            TimeSlot(
              id: 'slot-003',
              startTime: DateTime(
                normalizedDay.year,
                normalizedDay.month,
                normalizedDay.day,
                20,
              ),
              endTime: DateTime(
                normalizedDay.year,
                normalizedDay.month,
                normalizedDay.day,
                21,
              ),
              status: SlotStatus.booked,
            ),
          ]
        : <TimeSlot>[
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
    final List<Booking> bookings = await _bookingRepository.getBookings();
    final int fieldCount = await _fieldCountProvider();
    return seededSlots
        .map((TimeSlot slot) {
          if (slot.status != SlotStatus.available) {
            return slot;
          }
          final int occupiedFields = bookings
              .where(
                (Booking booking) =>
                    booking.slot.startTime == slot.startTime &&
                    booking.slot.endTime == slot.endTime,
              )
              .map((Booking booking) => booking.fieldNumber)
              .toSet()
              .length;
          return occupiedFields >= fieldCount
              ? TimeSlot(
                  id: slot.id,
                  startTime: slot.startTime,
                  endTime: slot.endTime,
                  status: SlotStatus.booked,
                )
              : slot;
        })
        .toList(growable: false);
  }

  @override
  Stream<List<TimeSlot>> watchSlotsForDay(DateTime day) async* {
    yield await getSlotsForDay(day);
    await for (final BookingActivity activity
        in _bookingRepository.watchActivities()) {
      if (_isSameDay(activity.booking.slot.startTime, day)) {
        yield await getSlotsForDay(day);
      }
    }
  }

  static Future<int> _defaultFieldCount() async => 3;

  static bool _isSameDay(DateTime first, DateTime second) =>
      first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;
}
