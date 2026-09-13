import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soccer_booking_app/app/app.dart';
import 'package:soccer_booking_app/app/app_dependencies.dart';
import 'package:soccer_booking_app/app/router.dart';
import 'package:soccer_booking_app/features/auth/domain/app_user.dart';
import 'package:soccer_booking_app/features/bookings/domain/booking.dart';
import 'package:soccer_booking_app/features/bookings/domain/booking_match.dart';
import 'package:soccer_booking_app/features/bookings/domain/match_repository.dart';
import 'package:soccer_booking_app/features/slots/domain/time_slot.dart';

void main() {
  testWidgets('only an available slot opens the booking summary route', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(SoccerBookingApp());

    expect(find.text('احجز ملعبك بسهولة'), findsOneWidget);
    expect(find.text('ادخل وجرب الحجز'), findsOneWidget);
    expect(find.byType(TextFormField), findsNothing);
    await tester.tap(find.byKey(const Key('demo_entry_button')));
    await tester.pumpAndSettle();

    expect(find.text('المواعيد الفاضية'), findsOneWidget);
    expect(find.textContaining('المواعيد المتاحة قدامك لمدة'), findsOneWidget);
    expect(find.text('جاهز للماتش؟'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const Key('slot-003')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('محجوز مؤقتاً'), findsAtLeastNWidgets(1));
    expect(find.text('محجوز'), findsAtLeastNWidgets(1));
    expect(find.byIcon(Icons.timer_outlined), findsOneWidget);
    expect(find.byTooltip('احجز الموعد'), findsAtLeastNWidgets(1));

    await tester.tap(find.byKey(const Key('slot-003')));
    await tester.pumpAndSettle();
    expect(find.text('ملخص الحجز'), findsNothing);

    await tester.scrollUntilVisible(
      find.byKey(const Key('slot-001')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const Key('slot-001')));
    await tester.pumpAndSettle();

    expect(find.text('ملخص الحجز'), findsOneWidget);
    expect(find.byTooltip('رجوع'), findsOneWidget);
    expect(find.text('الكرة مشمولة مع الحجز'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.byKey(const Key('service-drinks')),
      300,
    );
    await tester.tap(find.byKey(const Key('service-drinks')));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const Key('payment_button')),
      300,
    );
    expect(find.textContaining('860'), findsAtLeastNWidgets(1));
    await tester.tap(find.byKey(const Key('payment_button')));
    await tester.pumpAndSettle();

    expect(find.text('طريقة الدفع'), findsOneWidget);
    expect(find.textContaining('860'), findsAtLeastNWidgets(1));

    await tester.tap(find.byKey(const Key('complete_mock_payment_button')));
    await tester.pumpAndSettle();

    expect(find.text('تأكيد الحجز'), findsOneWidget);
    expect(find.text('حجزك اتأكد!'), findsOneWidget);
    expect(find.text('HAGZ-1001'), findsOneWidget);
    expect(find.text('مشروبات ساقعة'), findsOneWidget);
    expect(find.textContaining('860'), findsAtLeastNWidgets(1));
  });

  testWidgets('keeps a public admin link out of the player experience', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      SoccerBookingApp(initialRoute: AppRouter.adminBookingsRoute),
    );

    expect(find.text('احجز ملعبك بسهولة'), findsOneWidget);
    expect(find.text('دخول لوحة الإدارة'), findsNothing);
  });

  testWidgets('opens the admin dashboard only for an admin session', (
    WidgetTester tester,
  ) async {
    final AppDependencies dependencies = AppDependencies.mock();
    dependencies.session.signIn(
      const AppUser(
        id: 'admin-test',
        name: 'مدير الاختبار',
        role: UserRole.admin,
      ),
    );

    await tester.pumpWidget(
      SoccerBookingApp(
        dependencies: dependencies,
        initialRoute: AppRouter.adminBookingsRoute,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('لوحة التحكم'), findsAtLeastNWidgets(1));
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('احجز ملعبك بسهولة'), findsNothing);
  });

  testWidgets('keeps primary admin destinations in a fixed bottom bar', (
    WidgetTester tester,
  ) async {
    final AppDependencies dependencies = AppDependencies.mock();
    dependencies.session.signIn(
      const AppUser(
        id: 'admin-test',
        name: 'مدير الاختبار',
        role: UserRole.admin,
      ),
    );

    await tester.pumpWidget(
      SoccerBookingApp(
        dependencies: dependencies,
        initialRoute: AppRouter.adminBookingsRoute,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('المالية'));
    await tester.pumpAndSettle();

    expect(find.text('التحصيل المالي'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('shows invitation-only guidance on the admin login screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      SoccerBookingApp(initialRoute: AppRouter.adminLoginRoute),
    );

    expect(find.text('دخول فريق الإدارة'), findsOneWidget);
    expect(find.text('ادخل وجرب لوحة الإدارة'), findsOneWidget);
    expect(find.byType(TextFormField), findsNothing);
  });

  testWidgets('lets an invited player confirm attendance from a secure route', (
    WidgetTester tester,
  ) async {
    final AppDependencies dependencies = AppDependencies.mock();
    final MatchRepository repository = dependencies.matchRepository;
    final BookingMatchFixture fixture = await _createInviteFixture(repository);

    await tester.pumpWidget(
      SoccerBookingApp(
        dependencies: dependencies,
        initialRoute: '${AppRouter.matchInviteRoute}?token=${fixture.token}',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('مطلوب لاعب للماتش'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), 'الكابتن علي');
    await tester.scrollUntilVisible(
      find.byKey(const Key('match_invite_going_button')),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.byKey(const Key('match_invite_going_button')));
    await tester.pumpAndSettle();

    expect(find.text('2 من 10 أكدوا حضورهم'), findsOneWidget);
  });
}

class BookingMatchFixture {
  const BookingMatchFixture(this.token);
  final String token;
}

Future<BookingMatchFixture> _createInviteFixture(
  MatchRepository repository,
) async {
  final Booking booking = Booking(
    reference: 'HAGZ-INVITE-1',
    playerId: 'organizer-1',
    playerName: 'الكابتن أحمد',
    slot: TimeSlot(
      id: 'invite-slot',
      startTime: DateTime(2026, 9, 15, 19),
      endTime: DateTime(2026, 9, 15, 20),
      status: SlotStatus.booked,
    ),
    services: const [],
    totalPrice: 800,
    status: BookingStatus.confirmed,
    fieldNumber: 1,
  );
  final BookingMatch match = await repository.getOrCreateForBooking(booking);
  return BookingMatchFixture(match.inviteToken);
}
