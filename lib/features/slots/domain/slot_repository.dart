import 'time_slot.dart';

abstract interface class SlotRepository {
  Future<List<TimeSlot>> getSlotsForDay(DateTime day);

  /// A backend implementation can emit live updates from Supabase or WebSocket.
  Stream<List<TimeSlot>> watchSlotsForDay(DateTime day);
}
