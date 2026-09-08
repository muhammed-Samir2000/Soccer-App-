import 'package:flutter/material.dart';

/// A consistent, Arabic calendar control for operational booking dates.
class BookingDatePickerField extends StatelessWidget {
  const BookingDatePickerField({
    super.key,
    required this.selectedDate,
    required this.firstDate,
    required this.lastDate,
    required this.onChanged,
    this.label = 'اليوم',
  });

  final DateTime selectedDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final ValueChanged<DateTime> onChanged;
  final String label;

  @override
  Widget build(BuildContext context) {
    final MaterialLocalizations localizations = MaterialLocalizations.of(
      context,
    );
    return Semantics(
      label: 'اختار $label من التقويم',
      button: true,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          alignment: AlignmentDirectional.centerStart,
          minimumSize: const Size(64, 58),
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: 16,
            vertical: 10,
          ),
        ),
        onPressed: () => _pickDate(context),
        icon: const Icon(Icons.calendar_month_outlined),
        label: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label),
            const SizedBox(height: 2),
            Text(
              localizations.formatMediumDate(selectedDate),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateUtils.dateOnly(selectedDate),
      firstDate: DateUtils.dateOnly(firstDate),
      lastDate: DateUtils.dateOnly(lastDate),
      locale: const Locale('ar', 'EG'),
      helpText: 'اختار يوم الحجز',
      cancelText: 'إلغاء',
      confirmText: 'اختيار',
      builder: (BuildContext context, Widget? child) => Directionality(
        textDirection: TextDirection.rtl,
        child: child ?? const SizedBox.shrink(),
      ),
    );
    if (picked != null) {
      onChanged(DateUtils.dateOnly(picked));
    }
  }
}
