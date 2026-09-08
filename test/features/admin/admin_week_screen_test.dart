import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soccer_booking_app/features/admin/presentation/admin_week_screen.dart';
import 'package:soccer_booking_app/features/bookings/data/mock_booking_repository.dart';
import 'package:soccer_booking_app/features/bookings/domain/booking.dart';
import 'package:soccer_booking_app/features/slots/data/mock_slot_repository.dart';

void main() {
  testWidgets('registers a player from an available admin hour', (
    WidgetTester tester,
  ) async {
    final MockBookingRepository repository = MockBookingRepository();
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ar', 'EG'),
        supportedLocales: const [Locale('ar', 'EG')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: AdminDayScreen(
            day: MockSlotRepository.weekStart,
            repository: repository,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byTooltip('تسجيل لاعب'), findsNWidgets(5));
    await tester.tap(find.byTooltip('تسجيل لاعب').first);
    await tester.pumpAndSettle();

    expect(find.text('تسجيل لاعب جديد'), findsOneWidget);
    expect(find.text('لمرة'), findsOneWidget);
    expect(find.text('ثابت'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).at(0), 'الكابتن عمر');
    await tester.enterText(find.byType(TextFormField).at(1), '01098765432');
    await tester.tap(find.text('حفظ الحجز'));
    await tester.pumpAndSettle();

    final List<Booking> bookings = await repository.getBookings();
    expect(bookings, hasLength(1));
    expect(bookings.single.playerName, 'الكابتن عمر');
    expect(bookings.single.status, BookingStatus.confirmed);
    expect(bookings.single.fieldNumber, 1);
  });

  testWidgets('marks a fixed admin booking as recurring', (
    WidgetTester tester,
  ) async {
    final MockBookingRepository repository = MockBookingRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: AdminDayScreen(
            day: MockSlotRepository.weekStart,
            repository: repository,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('تسجيل لاعب').first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'مجموعة الجمعة');
    await tester.enterText(find.byType(TextFormField).at(1), '01112345678');
    await tester.tap(find.text('ثابت'));
    await tester.tap(find.text('حفظ الحجز'));
    await tester.pumpAndSettle();

    expect(
      (await repository.getBookings()).single.status,
      BookingStatus.recurring,
    );
  });

  testWidgets('opens an Arabic calendar for the quick-booking day', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ar', 'EG'),
        supportedLocales: const [Locale('ar', 'EG')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: AdminBookingToolsScreen(repository: MockBookingRepository()),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.calendar_month_outlined));
    await tester.pumpAndSettle();

    expect(find.text('اختار يوم الحجز'), findsOneWidget);
  });
}
