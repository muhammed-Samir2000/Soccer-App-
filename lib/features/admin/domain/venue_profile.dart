class VenueProfile {
  const VenueProfile({
    required this.id,
    required this.name,
    required this.fieldCount,
    required this.hourlyPrice,
    required this.openingHour,
    required this.closingHour,
  });

  final String id;
  final String name;
  final int fieldCount;
  final int hourlyPrice;
  final int openingHour;
  final int closingHour;

  String? validate() {
    if (name.trim().length < 2 || name.trim().length > 100) {
      return 'اكتب اسم الملعب من حرفين إلى 100 حرف.';
    }
    if (fieldCount < 1 || fieldCount > 12) {
      return 'عدد الملاعب لازم يكون بين 1 و12.';
    }
    if (hourlyPrice < 1 || hourlyPrice > 100000) {
      return 'سعر الساعة لازم يكون بين 1 و100000 جنيه.';
    }
    if (openingHour < 0 || openingHour > 23 ||
        closingHour < 0 || closingHour > 23 || openingHour == closingHour) {
      return 'اختار ساعتين مختلفتين للفتح والقفل.';
    }
    return null;
  }
}
