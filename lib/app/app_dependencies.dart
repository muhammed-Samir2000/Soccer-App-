import '../core/config/backend_configuration.dart';
import '../features/admin/data/mock_notification_repository.dart';
import '../features/admin/data/mock_staff_repository.dart';
import '../features/admin/domain/notification_repository.dart';
import '../features/admin/domain/staff_repository.dart';
import '../features/auth/data/mock_auth_repository.dart';
import '../features/auth/domain/auth_repository.dart';
import '../features/bookings/data/mock_booking_repository.dart';
import '../features/bookings/domain/booking_repository.dart';
import '../features/slots/data/mock_slot_repository.dart';
import '../features/slots/domain/slot_repository.dart';

class AppDependencies {
  const AppDependencies({
    required this.authRepository,
    required this.slotRepository,
    required this.bookingRepository,
    required this.staffRepository,
    required this.notificationRepository,
    this.backendConfiguration = const BackendConfiguration(),
  });

  factory AppDependencies.mock() => AppDependencies(
    authRepository: const MockAuthRepository(),
    slotRepository: const MockSlotRepository(),
    bookingRepository: MockBookingRepository.seeded(),
    staffRepository: MockStaffRepository(),
    notificationRepository: MockNotificationRepository(),
  );

  final AuthRepository authRepository;
  final SlotRepository slotRepository;
  final BookingRepository bookingRepository;
  final StaffRepository staffRepository;
  final NotificationRepository notificationRepository;
  final BackendConfiguration backendConfiguration;
}
