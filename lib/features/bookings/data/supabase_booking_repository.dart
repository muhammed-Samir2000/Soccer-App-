import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../slots/domain/time_slot.dart';
import '../domain/booking.dart';
import '../domain/booking_activity.dart';
import '../domain/booking_draft.dart';
import '../domain/booking_repository.dart';
import '../domain/match_result.dart';
import '../domain/optional_service.dart';

/// The database owns identity, allocation, prices and permissions.
class SupabaseBookingRepository implements BookingRepository {
  SupabaseBookingRepository(this.client, this.venueIdProvider);
  final SupabaseClient client;
  final Future<String> Function() venueIdProvider;
  final _activities = StreamController<BookingActivity>.broadcast();

  static int pounds(Object? cents) {
    if (cents is! int || cents < 0 || cents % 100 != 0) {
      throw StateError('السعر لازم يكون بالجنيه الكامل في الإصدار الحالي.');
    }
    return cents ~/ 100;
  }

  static Booking decode(Map<String, dynamic> row) => Booking(
    reference: row['reference'] as String,
    playerId: row['player_id'] as String,
    playerName: row['player_name'] as String,
    phoneNumber: row['player_phone'] as String? ?? '',
    slot: TimeSlot(id: row['id'] as String,
      startTime: DateTime.parse(row['starts_at'] as String).toLocal(),
      endTime: DateTime.parse(row['ends_at'] as String).toLocal(),
      status: SlotStatus.booked),
    services: (row['services'] as List).map((value) {
      final service = value as Map<String, dynamic>;
      return OptionalService(id: service['id'] as String,
        name: service['name'] as String, price: pounds(service['price_cents']));
    }).toList(),
    totalPrice: pounds(row['total_price_cents']),
    status: BookingStatus.values.byName(row['status'] as String),
    fieldNumber: row['field_number'] as int? ?? (row['fields'] as Map<String,dynamic>)['sort_order'] as int,
  );

  @override
  Future<List<Booking>> getBookings() async {
    final venueId = await venueIdProvider();
    final rows = await client.from('bookings').select('*,fields(sort_order)')
        .eq('venue_id',venueId).neq('status','cancelled').order('starts_at');
    return rows.map(decode).toList();
  }

  @override
  Future<List<Booking>> getBookingsForPlayer(String playerId) async {
    final venueId = await venueIdProvider();
    if (client.auth.currentUser?.id != playerId) throw StateError('سجّل الدخول بحسابك.');
    final rows = await client.from('bookings').select('*,fields(sort_order)')
        .eq('venue_id',venueId).eq('player_id',playerId)
        .neq('status','cancelled').order('starts_at');
    return rows.map(decode).toList();
  }

  Future<Booking> _create(BookingDraft draft, {bool admin=false,
    String? name, String? phone, BookingStatus status=BookingStatus.confirmed}) async {
    try {
      final venueId = await venueIdProvider();
      final data = await client.rpc('soccer_create_booking',params: {
        'p_venue_id':venueId,
        'p_starts_at':draft.slot.startTime.toUtc().toIso8601String(),
        'p_service_ids':draft.selectedServices.map((s)=>s.id).toList(),
        'p_expected_total_cents':draft.totalPrice*100,
        'p_admin':admin,'p_player_name':name,'p_player_phone':phone,'p_status':status.name,
      });
      final booking=decode(Map<String,dynamic>.from(data as Map));
      _activities.add(BookingActivity(type:BookingActivityType.created,booking:booking));
      return booking;
    } on PostgrestException catch (error) {
      if (error.message.contains('fully booked') || error.code=='23P01') {
        throw StateError('الميعاد اتحجز دلوقتي. ارجع للمواعيد واختار ميعاد تاني.');
      }
      if (error.message.contains('Prices changed')) {
        throw StateError('السعر اتغيّر. ارجع للمواعيد وراجع إجمالي الحجز.');
      }
      throw StateError('الحجز ما اكتملش. راجع بياناتك وصلاحية حسابك وحاول تاني.');
    }
  }

  @override
  Future<Booking> createBooking(BookingDraft draft,{required String playerId,required String playerName}) => _create(draft);
  @override
  Future<Booking> createTentativeBooking({required String playerName,required String phoneNumber,required BookingDraft draft}) =>
    _create(draft,admin:true,name:playerName,phone:phoneNumber,status:BookingStatus.tentative);
  @override
  Future<Booking> createAdminBooking({required String playerName,required String phoneNumber,required BookingDraft draft,required BookingStatus status}) =>
    _create(draft,admin:true,name:playerName,phone:phoneNumber,status:status);
  @override
  Stream<BookingActivity> watchActivities() => _activities.stream;

  // These features must not silently fall back to transient mock writes.
  @override
  Future<void> updateFieldCount(int fieldCount) async => throw StateError('عدّل عدد الملاعب من بيانات الملعب والأسعار.');
  @override
  Future<Booking> createRecurringBooking({required String playerName,required String phoneNumber,required BookingDraft draft}) async =>
    throw StateError('الحجز الثابت مش مفعّل في الربط الحالي. احجز كل ميعاد لوحده.');
  @override
  Future<void> saveMatchResult({required String bookingReference,required MatchResult result}) async =>
    throw StateError('تسجيل النتائج مش مفعّل في الربط الحالي.');
  @override
  Future<void> updateBooking(Booking booking) async => throw StateError('تعديل الحجز مش مفعّل في الربط الحالي.');
  @override
  Future<void> deleteBooking(String bookingReference) async => throw StateError('إلغاء الحجز مش مفعّل في الربط الحالي.');
}
