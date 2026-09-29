import 'package:flutter_test/flutter_test.dart';
import 'package:soccer_booking_app/features/bookings/domain/optional_service.dart';
import 'package:soccer_booking_app/features/slots/data/venue_service_catalog.dart';

void main() {
  const OptionalService drinks = OptionalService(
    id: 'drinks',
    name: 'مشروبات',
    price: 50,
  );

  test('loads a venue catalogue once until explicitly invalidated', () async {
    var calls = 0;
    final VenueServiceCatalog catalog = VenueServiceCatalog((String venueId) {
      calls++;
      return Future<List<OptionalService>>.value(const <OptionalService>[
        drinks,
      ]);
    });

    final first = await catalog.forVenue('venue-1');
    final second = await catalog.forVenue('venue-1');
    catalog.invalidate('venue-1');
    final third = await catalog.forVenue('venue-1');

    expect(first, same(second));
    expect(third, isNot(same(first)));
    expect(calls, 2);
  });

  test('does not retain a failed catalogue request', () async {
    var calls = 0;
    final VenueServiceCatalog catalog = VenueServiceCatalog((String venueId) {
      calls++;
      if (calls == 1) {
        return Future<List<OptionalService>>.error(StateError('offline'));
      }
      return Future<List<OptionalService>>.value(const <OptionalService>[
        drinks,
      ]);
    });

    await expectLater(catalog.forVenue('venue-1'), throwsStateError);
    await catalog.forVenue('venue-1');

    expect(calls, 2);
  });
}
