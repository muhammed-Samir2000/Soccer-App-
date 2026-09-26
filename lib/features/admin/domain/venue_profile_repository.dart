import 'venue_profile.dart';

abstract interface class VenueProfileRepository {
  Future<VenueProfile?> getVenue();
  Future<VenueProfile> saveVenue(VenueProfile venue);
}
