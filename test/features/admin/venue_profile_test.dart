import 'package:flutter_test/flutter_test.dart';
import 'package:soccer_booking_app/features/admin/domain/venue_profile.dart';

void main() {
  test('accepts an overnight venue schedule and entered hourly price', () {
    const venue = VenueProfile(
      id: '',
      name: 'ملعب النصر',
      fieldCount: 3,
      hourlyPrice: 800,
      openingHour: 15,
      closingHour: 2,
    );

    expect(venue.validate(), isNull);
  });

  test('rejects equal opening and closing hours', () {
    const venue = VenueProfile(
      id: '',
      name: 'ملعب النصر',
      fieldCount: 3,
      hourlyPrice: 800,
      openingHour: 15,
      closingHour: 15,
    );

    expect(venue.validate(), contains('مختلفين'));
  });
}
