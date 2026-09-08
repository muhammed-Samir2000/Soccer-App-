import 'venue_settings.dart';

abstract interface class VenueSettingsRepository {
  Future<VenueSettings> getSettings();

  Stream<VenueSettings> watchSettings();

  Future<void> updateSettings(VenueSettings settings);
}
