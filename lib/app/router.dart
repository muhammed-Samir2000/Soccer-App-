import 'package:flutter/material.dart';

import '../features/admin/presentation/admin_bookings_screen.dart';
import '../features/admin/presentation/notification_center_screen.dart';
import '../features/admin/presentation/admin_week_screen.dart';
import '../features/admin/presentation/financial_analytics_screen.dart';
import '../features/auth/domain/app_user.dart';
import '../features/auth/presentation/mock_login_screen.dart';
import '../features/bookings/domain/booking_draft.dart';
import '../features/bookings/domain/booking.dart';
import '../features/bookings/presentation/booking_confirmation_screen.dart';
import '../features/bookings/presentation/booking_summary_screen.dart';
import '../features/bookings/presentation/my_bookings_screen.dart';
import '../features/bookings/presentation/match_hub_screen.dart';
import '../features/bookings/presentation/match_invite_screen.dart';
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
  static const notificationsRoute = '/notifications';
  static const myBookingsRoute = '/my-bookings';
  static const matchHubRoute = '/match-hub';
  static const matchInviteRoute = '/match-invite';

  Route<void> onGenerateRoute(RouteSettings settings) {
    return MaterialPageRoute<void>(
      settings: settings,
      builder: (BuildContext context) {
        final String routeName =
            Uri.tryParse(settings.name ?? launchRoute)?.path ?? launchRoute;
        switch (routeName) {
          case slotsRoute:
            final AppUser? player = _playerFrom(settings.arguments);
            if (player == null) {
              return _playerEntry();
            }
            return AvailableSlotsScreen(
              player: player,
              repository: dependencies.slotRepository,
              onSignOut: () => _signOutAndReturnToEntry(context),
            );
          case bookingSummaryRoute:
            final Object? arguments = settings.arguments;
            if (arguments is! BookingSummaryRouteArguments) {
              return _playerEntry();
            }
            return BookingSummaryScreen(
              slot: arguments.slot,
              player: arguments.player,
            );
          case paymentPlaceholderRoute:
            final Object? arguments = settings.arguments;
            if (arguments is! PaymentPlaceholderRouteArguments) {
              return _playerEntry();
            }
            return PaymentPlaceholderScreen(
              draft: arguments.draft,
              player: arguments.player,
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
          case matchHubRoute:
            return MatchHubScreen(
              booking: settings.arguments! as Booking,
              repository: dependencies.matchRepository,
            );
          case matchInviteRoute:
            final String? inviteToken = _inviteToken(settings.name);
            if (inviteToken == null || inviteToken.isEmpty) {
              return const Scaffold(
                body: Center(child: Text('رابط الدعوة غير صالح.')),
              );
            }
            return MatchInviteScreen(
              inviteToken: inviteToken,
              matchRepository: dependencies.matchRepository,
              authRepository: dependencies.authRepository,
              session: dependencies.session,
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
              canManageTeam: dependencies.session.isSuperAdmin,
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
          case notificationsRoute:
            final AppUser? user = settings.arguments is AppUser
                ? settings.arguments! as AppUser
                : dependencies.session.currentUser;
            if (user == null) {
              return _playerEntry();
            }
            return NotificationCenterScreen(
              user: user,
              notificationRepository: dependencies.notificationRepository,
              bookingRepository: dependencies.bookingRepository,
              slotRepository: dependencies.slotRepository,
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

  Future<void> _signOutAndReturnToEntry(BuildContext context) async {
    try {
      await dependencies.authRepository.signOut();
    } finally {
      dependencies.session.signOut();
    }
    if (context.mounted) {
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(launchRoute, (Route<dynamic> route) => false);
    }
  }

  String? _inviteToken(String? routeName) {
    final String? routeToken = Uri.tryParse(
      routeName ?? '',
    )?.queryParameters['token'];
    if (routeToken != null && routeToken.isNotEmpty) {
      return routeToken;
    }
    // Flutter Web hash routing can expose the query only in Uri.base.
    return Uri.tryParse(Uri.base.fragment)?.queryParameters['token'];
  }

  Widget _playerEntry() {
    final AppUser? player = _playerFrom(null);
    return MockLoginScreen(
      repository: dependencies.authRepository,
      session: dependencies.session,
      initialUser: player,
    );
  }
}

class BookingSummaryRouteArguments {
  const BookingSummaryRouteArguments({
    required this.slot,
    required this.player,
  });

  final TimeSlot slot;
  final AppUser player;
}

class PaymentPlaceholderRouteArguments {
  const PaymentPlaceholderRouteArguments({
    required this.draft,
    required this.player,
  });

  final BookingDraft draft;
  final AppUser player;
}
