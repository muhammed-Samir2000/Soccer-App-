import 'package:flutter/material.dart';

import '../features/admin/presentation/admin_bookings_screen.dart';
import '../features/admin/presentation/admin_week_screen.dart';
import '../features/admin/presentation/financial_analytics_screen.dart';
import '../features/auth/domain/app_user.dart';
import '../features/auth/presentation/mock_login_screen.dart';
import '../features/bookings/domain/booking_draft.dart';
import '../features/bookings/domain/booking.dart';
import '../features/bookings/presentation/booking_confirmation_screen.dart';
import '../features/bookings/presentation/booking_summary_screen.dart';
import '../features/bookings/presentation/my_bookings_screen.dart';
import '../features/bookings/presentation/payment_placeholder_screen.dart';
import '../features/slots/domain/time_slot.dart';
import '../features/slots/presentation/available_slots_screen.dart';
import 'app_dependencies.dart';

class AppRouter {
  const AppRouter(this.dependencies);

  final AppDependencies dependencies;

  static const launchRoute = '/';
  static const slotsRoute = '/slots';
  static const bookingSummaryRoute = '/booking-summary';
  static const paymentPlaceholderRoute = '/payment-placeholder';
  static const bookingConfirmationRoute = '/booking-confirmation';
  static const adminBookingsRoute = '/admin-bookings';
  static const adminBookingListRoute = '/admin-booking-list';
  static const adminSettingsRoute = '/admin-settings';
  static const adminLoginRoute = '/admin-login';
  static const adminFinancialAnalyticsRoute = '/admin-financial-analytics';
  static const myBookingsRoute = '/my-bookings';

  Route<void> onGenerateRoute(RouteSettings settings) {
    return MaterialPageRoute<void>(
      settings: settings,
      builder: (BuildContext context) {
        switch (settings.name) {
          case slotsRoute:
            final AppUser? player = _playerFrom(settings.arguments);
            if (player == null) {
              return _playerEntry();
            }
            return AvailableSlotsScreen(
              player: player,
              repository: dependencies.slotRepository,
            );
          case bookingSummaryRoute:
            return BookingSummaryScreen(slot: settings.arguments! as TimeSlot);
          case paymentPlaceholderRoute:
            return PaymentPlaceholderScreen(
              draft: settings.arguments! as BookingDraft,
              repository: dependencies.bookingRepository,
            );
          case bookingConfirmationRoute:
            return BookingConfirmationScreen(
              booking: settings.arguments! as Booking,
            );
          case myBookingsRoute:
            return MyBookingsScreen(
              playerId: settings.arguments! as String,
              repository: dependencies.bookingRepository,
            );
          case adminBookingsRoute:
            if (!dependencies.session.isAdmin) {
              return _playerEntry();
            }
            return AdminWeekScreen(
              bookingRepository: dependencies.bookingRepository,
              staffRepository: dependencies.staffRepository,
              notificationRepository: dependencies.notificationRepository,
              venueSettingsRepository: dependencies.venueSettingsRepository,
            );
          case adminLoginRoute:
            return MockLoginScreen(
              repository: dependencies.authRepository,
              session: dependencies.session,
              audience: LoginAudience.admin,
            );
          case adminBookingListRoute:
            if (!dependencies.session.isAdmin) {
              return _playerEntry();
            }
            return AdminBookingsScreen(
              repository: dependencies.bookingRepository,
            );
          case adminFinancialAnalyticsRoute:
            if (!dependencies.session.isAdmin) {
              return _playerEntry();
            }
            return FinancialAnalyticsScreen(
              repository: dependencies.bookingRepository,
            );
          case adminSettingsRoute:
            if (!dependencies.session.isAdmin) {
              return _playerEntry();
            }
            return VenueSettingsScreen(
              settingsRepository: dependencies.venueSettingsRepository,
              bookingRepository: dependencies.bookingRepository,
            );
          case launchRoute:
          default:
            return _playerEntry();
        }
      },
    );
  }

  AppUser? _playerFrom(Object? arguments) {
    if (arguments case final AppUser user when user.role == UserRole.player) {
      return user;
    }

    final AppUser? sessionUser = dependencies.session.currentUser;
    return sessionUser?.role == UserRole.player ? sessionUser : null;
  }

  Widget _playerEntry() {
    final AppUser? player = _playerFrom(null);
    if (player != null) {
      return AvailableSlotsScreen(
        player: player,
        repository: dependencies.slotRepository,
      );
    }

    return MockLoginScreen(
      repository: dependencies.authRepository,
      session: dependencies.session,
    );
  }
}
