import 'dart:async';

import '../domain/venue_settings.dart';
import '../domain/venue_settings_repository.dart';

class MockVenueSettingsRepository implements VenueSettingsRepository {
  MockVenueSettingsRepository({
    VenueSettings initialSettings = const VenueSettings(
      fieldCount: 3,
      openingHour: 15,
      closingHour: 2,
    ),
  }) : _settings = initialSettings;

  final StreamController<VenueSettings> _changes =
      StreamController<VenueSettings>.broadcast();
  VenueSettings _settings;

  @override
  Future<VenueSettings> getSettings() async => _settings;

  @override
  Stream<VenueSettings> watchSettings() async* {
    yield _settings;
    yield* _changes.stream;
  }

  @override
  Future<void> updateSettings(VenueSettings settings) async {
    if (settings.fieldCount < 1 || settings.fieldCount > 12) {
      throw ArgumentError('عدد الملاعب لازم يكون بين 1 و12.');
    }
    if (settings.openingHour < 0 ||
        settings.openingHour > 23 ||
        settings.closingHour < 0 ||
        settings.closingHour > 23 ||
        settings.operatingHours == 0) {
      throw ArgumentError(
        'اختار وقتين مختلفين للفتح والقفل. القفل ممكن يكون في اليوم التالي.',
      );
    }
    _settings = settings;
    _changes.add(settings);
  }
}
