class VenueSettings {
  const VenueSettings({
    required this.fieldCount,
    required this.openingHour,
    required this.closingHour,
  });

  final int fieldCount;
  final int openingHour;
  final int closingHour;

  /// Supports overnight schedules: 15:00 to 02:00 is an 11-hour shift.
  int get operatingHours => (closingHour - openingHour + 24) % 24;
  int get dailyFieldHours => fieldCount * operatingHours;

  bool get crossesMidnight => closingHour <= openingHour;

  List<int> get operatingHourList => List<int>.generate(
    operatingHours,
    (int index) => (openingHour + index) % 24,
  );

  bool containsOperatingHour(int hour) => operatingHourList.contains(hour);

  VenueSettings copyWith({
    int? fieldCount,
    int? openingHour,
    int? closingHour,
  }) => VenueSettings(
    fieldCount: fieldCount ?? this.fieldCount,
    openingHour: openingHour ?? this.openingHour,
    closingHour: closingHour ?? this.closingHour,
  );
}
