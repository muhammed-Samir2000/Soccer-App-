import 'dart:async';

import '../domain/venue_settings.dart';
import '../domain/venue_settings_repository.dart';

class MockVenueSettingsRepository implements VenueSettingsRepository {
  MockVenueSettingsRepository({
    VenueSettings initialSettings = const VenueSettings(
      fieldCount: 3,
      openingHour: 16,
      closingHour: 21,
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
        settings.closingHour > 24 ||
        settings.openingHour >= settings.closingHour) {
      throw ArgumentError('اختار موعد فتح قبل موعد القفل.');
    }
    _settings = settings;
    _changes.add(settings);
  }
}
