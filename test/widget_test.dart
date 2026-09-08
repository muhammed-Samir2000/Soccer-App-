import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soccer_booking_app/app/app.dart';

void main() {
  testWidgets('only an available slot opens the booking summary route', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(SoccerBookingApp());

    expect(find.text('تسجيل الدخول'), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('phone_number_field')),
      '01012345678',
    );
    await tester.scrollUntilVisible(
      find.byKey(const Key('continue_button')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const Key('continue_button')));
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
}
