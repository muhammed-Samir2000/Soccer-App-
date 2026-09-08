import 'time_slot.dart';

abstract interface class SlotRepository {
  Future<List<TimeSlot>> getSlotsForDay(DateTime day);
}
