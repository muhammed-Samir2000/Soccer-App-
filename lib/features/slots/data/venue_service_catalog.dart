import '../../bookings/domain/optional_service.dart';

/// Keeps the rarely-changing service catalogue out of the 15-second slot poll.
/// A failed fetch is never retained, so the next refresh can recover normally.
class VenueServiceCatalog {
  VenueServiceCatalog(this._loader);

  final Future<List<OptionalService>> Function(String venueId) _loader;
  final Map<String, Future<List<OptionalService>>> _byVenue =
      <String, Future<List<OptionalService>>>{};

  Future<List<OptionalService>> forVenue(String venueId) async {
    final Future<List<OptionalService>>? cached = _byVenue[venueId];
    if (cached != null) {
      return cached;
    }
    final Future<List<OptionalService>> loading = _loader(venueId).then(
      (List<OptionalService> services) =>
          List<OptionalService>.unmodifiable(services),
    );
    _byVenue[venueId] = loading;
    try {
      return await loading;
    } catch (_) {
      if (identical(_byVenue[venueId], loading)) {
        _byVenue.remove(venueId);
      }
      rethrow;
    }
  }

  void invalidate(String venueId) => _byVenue.remove(venueId);
}
