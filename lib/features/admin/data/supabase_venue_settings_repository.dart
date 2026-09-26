import '../domain/venue_profile_repository.dart';
import '../domain/venue_settings.dart';
import '../domain/venue_settings_repository.dart';

class SupabaseVenueSettingsRepository implements VenueSettingsRepository {
  SupabaseVenueSettingsRepository(this.profileRepository);

  final VenueProfileRepository profileRepository;

  @override
  Future<VenueSettings> getSettings() async {
    final profile = await profileRepository.getVenue();
    if (profile == null) {
      throw StateError('بيانات الملعب لسه ما اتسجلتش.');
    }
    return VenueSettings(
      fieldCount: profile.fieldCount,
      openingHour: profile.openingHour,
      closingHour: profile.closingHour,
      hourlyPrice: profile.hourlyPrice,
    );
  }

  @override
  Stream<VenueSettings> watchSettings() async* {
    yield await getSettings();
  }

  @override
  Future<void> updateSettings(VenueSettings settings) async {
    throw StateError('عدّل البيانات والسعر من شاشة بيانات الملعب والأسعار.');
  }
}
