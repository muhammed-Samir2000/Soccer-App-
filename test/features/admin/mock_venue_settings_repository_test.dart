import 'package:flutter_test/flutter_test.dart';
import 'package:soccer_booking_app/features/admin/data/mock_venue_settings_repository.dart';
import 'package:soccer_booking_app/features/admin/domain/venue_settings.dart';

void main() {
  test('stores updated field capacity and operating hours', () async {
    final MockVenueSettingsRepository repository =
        MockVenueSettingsRepository();
    const VenueSettings updated = VenueSettings(
      fieldCount: 5,
      openingHour: 15,
      closingHour: 23,
    );

    await repository.updateSettings(updated);

    expect(await repository.getSettings(), updated);
    expect(updated.dailyFieldHours, 40);
  });

  test('supports an overnight operating schedule', () async {
    final MockVenueSettingsRepository repository =
        MockVenueSettingsRepository();

    const VenueSettings overnight = VenueSettings(
      fieldCount: 3,
      openingHour: 15,
      closingHour: 2,
    );

    await repository.updateSettings(overnight);

    expect(overnight.operatingHours, 11);
    expect(overnight.dailyFieldHours, 33);
    expect(overnight.operatingHourList, <int>[
      15,
      16,
      17,
      18,
      19,
      20,
      21,
      22,
      23,
      0,
      1,
    ]);
  });

  test('rejects an empty operating schedule', () async {
    final MockVenueSettingsRepository repository =
        MockVenueSettingsRepository();

    await expectLater(
      repository.updateSettings(
        const VenueSettings(fieldCount: 3, openingHour: 15, closingHour: 15),
      ),
      throwsArgumentError,
    );
  });
}
