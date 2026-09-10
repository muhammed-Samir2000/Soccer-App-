String? validatePlayerName(String value) {
  final String name = value.trim();
  if (name.length < 2) {
    return 'اكتب اسم اللاعب أو المجموعة بشكل كامل.';
  }
  if (name.length > 80) {
    return 'الاسم طويل زيادة، اكتبه في 80 حرف أو أقل.';
  }
  if (RegExp(r'[<>\r\n]').hasMatch(name)) {
    return 'الاسم فيه رموز غير مسموح بيها.';
  }
  return null;
}

String? validateEgyptianMobile(String value) {
  final String phone = value.trim();
  if (!RegExp(r'^01[0125][0-9]{8}$').hasMatch(phone)) {
    return 'اكتب رقم موبايل مصري صحيح من 11 رقم.';
  }
  return null;
}

String? validateShortText(String value, String label, {bool required = true}) {
  final String text = value.trim();
  if (required && text.isEmpty) {
    return 'اكتب $label.';
  }
  if (text.length > 80) {
    return '$label طويل زيادة، اكتبه في 80 حرف أو أقل.';
  }
  if (RegExp(r'[<>\r\n]').hasMatch(text)) {
    return '$label فيه رموز غير مسموح بيها.';
  }
  return null;
}

String? validateDescription(String value, String label) {
  if (value.trim().length > 250) {
    return '$label طويل زيادة، اكتبه في 250 حرف أو أقل.';
  }
  return null;
}
