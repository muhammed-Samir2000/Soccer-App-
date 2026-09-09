import '../../bookings/domain/booking.dart';

class FinancialReport {
  const FinancialReport({
    required this.startMonth,
    required this.endMonth,
    required this.collectedAmount,
    required this.pendingAmount,
    required this.collectedBookings,
    required this.comparisonAmount,
    required this.trend,
  });

  final DateTime startMonth;
  final DateTime endMonth;
  final int collectedAmount;
  final int pendingAmount;
  final int collectedBookings;
  final int comparisonAmount;
  final List<MonthlyCollection> trend;

  int get differenceFromPrevious => collectedAmount - comparisonAmount;

  double? get changeRate =>
      comparisonAmount == 0 ? null : differenceFromPrevious / comparisonAmount;

  static FinancialReport fromBookings({
    required List<Booking> bookings,
    required DateTime startMonth,
    required DateTime endMonth,
  }) {
    final DateTime start = _monthStart(startMonth);
    final DateTime end = _monthStart(endMonth);
    final int monthCount = _monthDistance(start, end) + 1;
    final DateTime selectedEndExclusive = _addMonths(end, 1);
    final DateTime comparisonStart = _addMonths(start, -monthCount);

    final List<Booking> selected = bookings
        .where(
          (Booking booking) =>
              _isWithin(booking.slot.startTime, start, selectedEndExclusive),
        )
        .toList();
    final int collectedAmount = selected
        .where(_isCollected)
        .fold(0, (int total, Booking booking) => total + booking.totalPrice);
    final int pendingAmount = selected
        .where((Booking booking) => booking.status == BookingStatus.tentative)
        .fold(0, (int total, Booking booking) => total + booking.totalPrice);
    final int comparisonAmount = bookings
        .where(
          (Booking booking) =>
              _isWithin(booking.slot.startTime, comparisonStart, start),
        )
        .where(_isCollected)
        .fold(0, (int total, Booking booking) => total + booking.totalPrice);

    return FinancialReport(
      startMonth: start,
      endMonth: end,
      collectedAmount: collectedAmount,
      pendingAmount: pendingAmount,
      collectedBookings: selected.where(_isCollected).length,
      comparisonAmount: comparisonAmount,
      trend: List<MonthlyCollection>.generate(monthCount, (int index) {
        final DateTime month = _addMonths(start, index);
        final DateTime nextMonth = _addMonths(month, 1);
        final int amount = bookings
            .where(
              (Booking booking) =>
                  _isWithin(booking.slot.startTime, month, nextMonth),
            )
            .where(_isCollected)
            .fold(
              0,
              (int total, Booking booking) => total + booking.totalPrice,
            );
        return MonthlyCollection(month: month, collectedAmount: amount);
      }),
    );
  }

  static bool _isCollected(Booking booking) =>
      booking.status == BookingStatus.confirmed ||
      booking.status == BookingStatus.recurring;

  static bool _isWithin(DateTime date, DateTime start, DateTime endExclusive) =>
      !date.isBefore(start) && date.isBefore(endExclusive);

  static DateTime _monthStart(DateTime date) => DateTime(date.year, date.month);

  static int _monthDistance(DateTime start, DateTime end) =>
      (end.year - start.year) * 12 + end.month - start.month;

  static DateTime _addMonths(DateTime date, int count) =>
      DateTime(date.year, date.month + count);
}

class MonthlyCollection {
  const MonthlyCollection({required this.month, required this.collectedAmount});

  final DateTime month;
  final int collectedAmount;
}
