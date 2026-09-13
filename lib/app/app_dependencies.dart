import '../core/config/backend_configuration.dart';
import '../features/admin/data/mock_notification_repository.dart';
import '../features/admin/data/mock_staff_repository.dart';
import '../features/admin/data/mock_venue_settings_repository.dart';
import '../features/admin/domain/notification_repository.dart';
import '../features/admin/domain/staff_repository.dart';
import '../features/admin/domain/venue_settings_repository.dart';
import '../features/auth/data/mock_auth_repository.dart';
import '../features/auth/domain/app_session.dart';
import '../features/auth/domain/auth_repository.dart';
import '../features/bookings/data/mock_booking_repository.dart';
import '../features/bookings/data/mock_match_repository.dart';
import '../features/bookings/domain/booking_repository.dart';
import '../features/bookings/domain/match_repository.dart';
import '../features/slots/data/mock_slot_repository.dart';
import '../features/slots/domain/slot_repository.dart';

class AppDependencies {
  AppDependencies({
    required this.authRepository,
    required this.session,
    required this.slotRepository,
    required this.bookingRepository,
    required this.matchRepository,
    required this.staffRepository,
    required this.notificationRepository,
    required this.venueSettingsRepository,
    this.backendConfiguration = const BackendConfiguration(),
  });

  factory AppDependencies.mock() {
    final MockBookingRepository bookingRepository =
        MockBookingRepository.seeded();
    final MockSlotRepository slotRepository = MockSlotRepository(
      bookingRepository,
      fieldCountProvider: () async => bookingRepository.fieldCount,
    );
    return AppDependencies(
      authRepository: const MockAuthRepository(),
      session: AppSession(),
      slotRepository: slotRepository,
      bookingRepository: bookingRepository,
      matchRepository: MockMatchRepository(),
      staffRepository: MockStaffRepository(),
      notificationRepository: MockNotificationRepository(
        bookingRepository: bookingRepository,
        slotRepository: slotRepository,
      ),
      venueSettingsRepository: MockVenueSettingsRepository(),
    );
  }

  final AuthRepository authRepository;
  final AppSession session;
  final SlotRepository slotRepository;
  final BookingRepository bookingRepository;
  final MatchRepository matchRepository;
  final StaffRepository staffRepository;
  final NotificationRepository notificationRepository;
  final VenueSettingsRepository venueSettingsRepository;
  final BackendConfiguration backendConfiguration;
}
