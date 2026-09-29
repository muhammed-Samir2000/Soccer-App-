import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../bookings/data/supabase_booking_repository.dart';
import '../../bookings/domain/optional_service.dart';
import '../domain/slot_repository.dart';
import '../domain/time_slot.dart';
import 'venue_service_catalog.dart';

class SupabaseSlotRepository implements SlotRepository {
  SupabaseSlotRepository(this.client, this.venueIdProvider);
  final SupabaseClient client;
  final Future<String> Function() venueIdProvider;
  late final VenueServiceCatalog _serviceCatalog = VenueServiceCatalog(
    _loadServices,
  );

  @override
  Future<List<TimeSlot>> getSlotsForDay(DateTime day) async {
    final venueId = await venueIdProvider();
    final options = await _serviceCatalog.forVenue(venueId);
    final data = await client.rpc(
      'soccer_slots',
      params: {
        'p_venue_id': venueId,
        'p_day':
            '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}',
      },
    );
    return (data as List).map((value) {
      final row = value as Map<String, dynamic>;
      return TimeSlot(
        id: '$venueId/${row['starts_at']}',
        startTime: DateTime.parse(row['starts_at'] as String).toLocal(),
        endTime: DateTime.parse(row['ends_at'] as String).toLocal(),
        status: (row['available_fields'] as num) > 0
            ? SlotStatus.available
            : SlotStatus.booked,
        basePrice: SupabaseBookingRepository.pounds(row['price_cents']),
        services: options,
      );
    }).toList();
  }

  Future<List<OptionalService>> _loadServices(String venueId) async {
    final services = await client
        .from('optional_services')
        .select('id,name,price_cents')
        .eq('venue_id', venueId)
        .eq('is_active', true)
        .order('name');
    return services
        .map(
          (s) => OptionalService(
            id: s['id'] as String,
            name: s['name'] as String,
            price: SupabaseBookingRepository.pounds(s['price_cents']),
          ),
        )
        .toList();
  }

  @override
  Stream<List<TimeSlot>> watchSlotsForDay(DateTime day) {
    // Polling is intentional: works without exposing other players' bookings
    // or requiring publication changes. RPC checks capacity again on submit.
    late StreamController<List<TimeSlot>> controller;
    Timer? timer;
    var loading = false;
    var cancelled = false;
    Future<void> refresh() async {
      if (loading || cancelled) return;
      loading = true;
      try {
        final slots = await getSlotsForDay(day);
        if (!cancelled) controller.add(slots);
      } catch (error, stack) {
        if (!cancelled) controller.addError(error, stack);
      } finally {
        loading = false;
      }
    }

    controller = StreamController<List<TimeSlot>>(
      onListen: () {
        refresh();
        timer = Timer.periodic(const Duration(seconds: 15), (_) => refresh());
      },
      onCancel: () {
        cancelled = true;
        timer?.cancel();
      },
    );
    return controller.stream;
  }
}
