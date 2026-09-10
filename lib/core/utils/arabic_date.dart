const List<String> _arabicMonths = <String>[
  'يناير',
  'فبراير',
  'مارس',
  'أبريل',
  'مايو',
  'يونيو',
  'يوليو',
  'أغسطس',
  'سبتمبر',
  'أكتوبر',
  'نوفمبر',
  'ديسمبر',
];

String arabicMonthName(DateTime date) => _arabicMonths[date.month - 1];

String arabicDateLabel(DateTime date, {String? weekday}) {
  final String prefix = weekday == null ? '' : '$weekday ';
  return '$prefix${date.day} ${arabicMonthName(date)}';
}
