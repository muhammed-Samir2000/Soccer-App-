import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/venue_profile.dart';
import '../domain/venue_profile_repository.dart';

class SupabaseVenueProfileRepository implements VenueProfileRepository {
  SupabaseVenueProfileRepository(this.client);
  final SupabaseClient client;

  @override
  Future<VenueProfile?> getVenue() async {
    final rows = await client.from('venues')
        .select('id,name,opening_hour,closing_hour,fields(sort_order,hourly_price_cents,is_active)')
        .order('created_at').limit(2);
    if (rows.isEmpty) return null;
    if (rows.length > 1) {
      throw StateError('فيه أكتر من منشأة. اختيار المنشأة مطلوب قبل التشغيل.');
    }
    final row = rows.single;
    final fields = (row['fields'] as List).cast<Map<String, dynamic>>()
        .where((field) => field['is_active'] == true).toList();
    if (fields.isEmpty) throw StateError('المنشأة محتاجة ملاعب مفعّلة.');
    final prices = fields.map((field) => field['hourly_price_cents'] as int).toSet();
    if (prices.length != 1 || prices.single % 100 != 0) {
      throw StateError('الإصدار الحالي بيستخدم سعر موحّد بالجنيه الكامل للملاعب.');
    }
    return VenueProfile(
      id: row['id'] as String,
      name: row['name'] as String,
      fieldCount: fields.length,
      hourlyPrice: prices.single ~/ 100,
      openingHour: row['opening_hour'] as int,
      closingHour: (row['closing_hour'] as int) % 24,
    );
  }

  @override
  Future<VenueProfile> saveVenue(VenueProfile venue) async {
    final error = venue.validate();
    if (error != null) throw ArgumentError(error);
    await client.rpc('save_soccer_venue', params: {
      'p_venue_id': venue.id.isEmpty ? null : venue.id,
      'p_name': venue.name.trim(),
      'p_field_count': venue.fieldCount,
      'p_hourly_price_cents': venue.hourlyPrice * 100,
      'p_opening_hour': venue.openingHour,
      'p_closing_hour': venue.closingHour,
    });
    return (await getVenue())!;
  }
}
