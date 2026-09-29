import 'package:flutter/material.dart';

/// Shared booking-date rules. The product intentionally has no booking horizon:
/// any calendar day from today onward can be requested.
abstract final class BookingDates {
  static DateTime get today {
    final DateTime now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  /// Flutter's date picker requires a finite value; this is the framework's
  /// maximum calendar year, not a business booking limit.
  static DateTime get calendarLastDate => DateTime(9999, 12, 31);

  static DateTime dateOnly(DateTime value) => DateUtils.dateOnly(value);

  static DateTime clampToBookableDay(DateTime value) {
    final DateTime day = dateOnly(value);
    return day.isBefore(today) ? today : day;
  }

  static List<DateTime> sevenDaysFrom(DateTime start) =>
      List<DateTime>.generate(
        7,
        (int index) => dateOnly(start).add(Duration(days: index)),
        growable: false,
      );
}
