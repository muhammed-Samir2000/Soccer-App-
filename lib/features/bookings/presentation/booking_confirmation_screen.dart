import 'package:flutter/material.dart';

import '../../../app/router.dart';
import '../../../shared/widgets/app_page_app_bar.dart';
import '../../slots/domain/time_slot.dart';
import '../domain/booking.dart';
import '../domain/optional_service.dart';

class BookingConfirmationScreen extends StatelessWidget {
  const BookingConfirmationScreen({super.key, required this.booking});

  final Booking booking;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppPageAppBar(title: 'تأكيد الحجز'),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Icon(
              Icons.check_circle,
              color: Theme.of(context).colorScheme.primary,
              size: 72,
            ),
            const SizedBox(height: 20),
            Text(
              'حجزك اتأكد!',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'مستنيينك في الملعب.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 28),
            _ConfirmationCard(
              children: [
                _DetailRow(label: 'رقم الحجز', value: booking.reference),
                const Divider(height: 28),
                _DetailRow(
                  label: 'ميعاد الماتش',
                  value: _timeRange(booking.slot),
                ),
                const Divider(height: 28),
                _DetailRow(
                  label: 'الملعب المخصص',
                  value: 'ملعب ${booking.fieldNumber}',
                ),
                const Divider(height: 28),
                const _DetailRow(label: 'الكرة', value: 'مشمولة'),
                const Divider(height: 28),
                _ServicesDetails(services: booking.services),
                const Divider(height: 28),
                _DetailRow(
                  label: 'الإجمالي',
                  value: '${booking.totalPrice} ج.م',
                  emphasized: true,
                ),
              ],
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(
                AppRouter.myBookingsRoute,
                (Route<dynamic> route) => route.isFirst,
                arguments: booking.playerId,
              ),
              icon: const Icon(Icons.calendar_month_outlined),
              label: const Text('الانتقال إلى حجوزاتي'),
            ),
            const SizedBox(height: 12),
            const Text(
              'رمز QR هيظهر هنا بعد ربط خدمة التحقق في مرحلة لاحقة.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ConfirmationCard extends StatelessWidget {
  const _ConfirmationCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(children: children),
      ),
    );
  }
}

class _ServicesDetails extends StatelessWidget {
  const _ServicesDetails({required this.services});

  final List<OptionalService> services;

  @override
  Widget build(BuildContext context) {
    final String value = services.isEmpty
        ? 'مفيش خدمات إضافية'
        : services.map((OptionalService service) => service.name).join('، ');
    return _DetailRow(label: 'الخدمات الإضافية', value: value);
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final TextStyle? style = emphasized
        ? Theme.of(context).textTheme.titleLarge
        : Theme.of(context).textTheme.bodyLarge;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: Text(label, style: style)),
        const SizedBox(width: 16),
        Flexible(
          child: Text(value, textAlign: TextAlign.end, style: style),
        ),
      ],
    );
  }
}

String _timeRange(TimeSlot slot) {
  return '${_formatTime(slot.startTime)} - ${_formatTime(slot.endTime)}';
}

String _formatTime(DateTime time) {
  final int hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
  final String suffix = time.hour >= 12 ? 'م' : 'ص';
  return '$hour:00 $suffix';
}
