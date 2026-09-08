import 'package:flutter/material.dart';

import '../../../app/router.dart';
import '../../../shared/widgets/app_page_app_bar.dart';
import '../domain/booking.dart';
import '../domain/booking_draft.dart';
import '../domain/booking_repository.dart';

class PaymentPlaceholderScreen extends StatefulWidget {
  const PaymentPlaceholderScreen({
    super.key,
    required this.draft,
    required this.repository,
  });

  final BookingDraft draft;
  final BookingRepository repository;

  @override
  State<PaymentPlaceholderScreen> createState() =>
      _PaymentPlaceholderScreenState();
}

class _PaymentPlaceholderScreenState extends State<PaymentPlaceholderScreen> {
  bool _isCreatingBooking = false;
  String? _errorMessage;

  Future<void> _completeManualPayment() async {
    setState(() {
      _isCreatingBooking = true;
      _errorMessage = null;
    });
    try {
      final Booking booking = await widget.repository.createBooking(
        widget.draft,
      );
      if (!mounted) {
        return;
      }

      Navigator.of(context).pushReplacementNamed(
        AppRouter.bookingConfirmationRoute,
        arguments: booking,
      );
    } catch (_) {
      if (mounted) {
        setState(() {
          _isCreatingBooking = false;
          _errorMessage = 'حصلت مشكلة وإحنا بنأكد الحجز. جرّب تاني.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppPageAppBar(title: 'طريقة الدفع'),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              Icon(
                Icons.payments_outlined,
                color: Theme.of(context).colorScheme.primary,
                size: 64,
              ),
              const SizedBox(height: 20),
              Text(
                'دفع يدوي',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              const Text(
                'دي نسخة تجريبية. اعتبر إنك دفعت كاش في الملعب.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Text(
                'إجمالي حجزك ${widget.draft.totalPrice} ج.م',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const Spacer(),
              FilledButton(
                key: const Key('complete_mock_payment_button'),
                onPressed: _isCreatingBooking ? null : _completeManualPayment,
                child: Text(
                  _isCreatingBooking ? 'بنأكد حجزك...' : 'تم الدفع كاش',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
