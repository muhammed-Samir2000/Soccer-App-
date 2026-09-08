import 'package:flutter/material.dart';

import '../../../app/router.dart';
import '../../../shared/widgets/app_page_app_bar.dart';
import '../../slots/domain/time_slot.dart';
import '../data/mock_optional_services.dart';
import '../domain/booking_draft.dart';
import '../domain/optional_service.dart';

class BookingSummaryScreen extends StatefulWidget {
  const BookingSummaryScreen({super.key, required this.slot});

  final TimeSlot slot;

  @override
  State<BookingSummaryScreen> createState() => _BookingSummaryScreenState();
}

class _BookingSummaryScreenState extends State<BookingSummaryScreen> {
  late BookingDraft _draft;

  @override
  void initState() {
    super.initState();
    _draft = BookingDraft(slot: widget.slot, basePrice: 800);
  }

  void _toggleService(OptionalService service) {
    setState(() => _draft = _draft.toggleService(service));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppPageAppBar(title: 'ملخص الحجز'),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            Text('راجع حجزك', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              'زود اللي محتاجه قبل ما تكمّل.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            _SummaryCard(
              title: 'ميعاد الماتش',
              child: Text(_timeRange(_draft.slot)),
            ),
            const SizedBox(height: 12),
            _SummaryCard(
              title: 'الأساسيات',
              child: const Row(
                children: [
                  Icon(Icons.sports_soccer),
                  SizedBox(width: 12),
                  Expanded(child: Text('الكرة مشمولة مع الحجز')),
                  Icon(Icons.lock_outline, size: 18),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Text('زود على حجزك', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'كل الخدمات دي اختيارية.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            ...MockOptionalServices.all.map(
              (OptionalService service) => Card(
                clipBehavior: Clip.antiAlias,
                child: CheckboxListTile(
                  key: Key('service-${service.id}'),
                  value: _draft.hasService(service.id),
                  onChanged: (_) => _toggleService(service),
                  title: Text(service.name),
                  subtitle: Text('+ ${_formatPrice(service.price)}'),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              ),
            ),
            const SizedBox(height: 24),
            _TotalCard(draft: _draft),
            const SizedBox(height: 20),
            FilledButton(
              key: const Key('payment_button'),
              onPressed: () {
                Navigator.of(context).pushNamed(
                  AppRouter.paymentPlaceholderRoute,
                  arguments: _draft,
                );
              },
              child: Text('كمّل للدفع - ${_formatPrice(_draft.totalPrice)}'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _TotalCard extends StatelessWidget {
  const _TotalCard({required this.draft});

  final BookingDraft draft;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _PriceRow(label: 'سعر الملعب', price: draft.basePrice),
            if (draft.selectedServices.isNotEmpty) ...[
              const SizedBox(height: 8),
              _PriceRow(label: 'الخدمات الإضافية', price: draft.servicesTotal),
            ],
            const Divider(height: 28),
            _PriceRow(
              label: 'الإجمالي',
              price: draft.totalPrice,
              isTotal: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({
    required this.label,
    required this.price,
    this.isTotal = false,
  });

  final String label;
  final int price;
  final bool isTotal;

  @override
  Widget build(BuildContext context) {
    final TextStyle? style = isTotal
        ? Theme.of(context).textTheme.titleLarge
        : Theme.of(context).textTheme.bodyLarge;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style),
        Text(_formatPrice(price), style: style),
      ],
    );
  }
}

String _formatPrice(int price) => '$price ج.م';

String _timeRange(TimeSlot slot) {
  return '${_formatTime(slot.startTime)} - ${_formatTime(slot.endTime)}';
}

String _formatTime(DateTime time) {
  final int hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
  final String suffix = time.hour >= 12 ? 'م' : 'ص';
  return '$hour:00 $suffix';
}
