class VenueSettings {
  const VenueSettings({
    required this.fieldCount,
    required this.openingHour,
    required this.closingHour,
  });

  final int fieldCount;
  final int openingHour;
  final int closingHour;

  int get operatingHours => closingHour - openingHour;
  int get dailyFieldHours => fieldCount * operatingHours;

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
