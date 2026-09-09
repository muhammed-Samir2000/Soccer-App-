import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soccer_booking_app/app/app.dart';
import 'package:soccer_booking_app/app/app_dependencies.dart';
import 'package:soccer_booking_app/app/router.dart';
import 'package:soccer_booking_app/features/auth/domain/app_user.dart';

void main() {
  testWidgets('only an available slot opens the booking summary route', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(SoccerBookingApp());

    expect(find.text('احجز ملعبك بسهولة'), findsOneWidget);
    expect(find.text('المتابعة بحساب Google'), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('email_field')),
      'player@example.com',
    );
    await tester.enterText(
      find.byKey(const Key('password_field')),
      'password123',
    );
    final Finder credentialButton = find.byKey(
      const Key('credential_continue_button'),
    );
    await tester.ensureVisible(credentialButton);
    await tester.pumpAndSettle();
    await tester.tap(credentialButton);
    await tester.pumpAndSettle();

    expect(find.text('المواعيد الفاضية'), findsOneWidget);
    expect(find.text('المواعيد المتاحة قدامك لمدة 7 أيام.'), findsOneWidget);
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

    expect(find.text('لوحة التحكم'), findsOneWidget);
    expect(find.text('احجز ملعبك بسهولة'), findsNothing);
  });

  testWidgets('shows invitation-only guidance on the admin login screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      SoccerBookingApp(initialRoute: AppRouter.adminLoginRoute),
    );

    expect(find.text('دخول فريق الإدارة'), findsOneWidget);
    expect(
      find.text('الحسابات دي بتتفعّل بدعوة من مالك الملعب.'),
      findsOneWidget,
    );
    expect(find.text('لن تستطيع إنشاء صلاحية إدارية من هنا.'), findsOneWidget);
    expect(find.text('إنشاء حساب جديد'), findsNothing);
  });
}
