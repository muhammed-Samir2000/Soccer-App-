import 'package:flutter/material.dart';

import '../../../core/utils/arabic_date.dart';
import '../../../core/utils/booking_input_validators.dart';
import '../../../shared/widgets/app_page_app_bar.dart';

import '../../bookings/domain/booking.dart';
import '../../bookings/domain/booking_repository.dart';
import '../../bookings/domain/optional_service.dart';
import 'admin_bottom_navigation.dart';

class AdminBookingsScreen extends StatefulWidget {
  const AdminBookingsScreen({super.key, required this.repository});

  final BookingRepository repository;

  @override
  State<AdminBookingsScreen> createState() => _AdminBookingsScreenState();
}

class _AdminBookingsScreenState extends State<AdminBookingsScreen> {
  late Future<List<Booking>> _bookings;

  @override
  void initState() {
    super.initState();
    _bookings = widget.repository.getBookings();
  }

  void _reload() => setState(() => _bookings = widget.repository.getBookings());

  Future<void> _editBooking(Booking booking) async {
    final TextEditingController name = TextEditingController(
      text: booking.playerName,
    );
    final TextEditingController phone = TextEditingController(
      text: booking.phoneNumber,
    );
    BookingStatus selectedStatus = booking.status;
    final bool? shouldSave = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setDialogState) =>
            AlertDialog(
              title: const Text('تعديل الحجز'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: name,
                      maxLength: 80,
                      decoration: const InputDecoration(
                        labelText: 'اسم اللاعب أو المجموعة',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: phone,
                      maxLength: 11,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'رقم الهاتف',
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<BookingStatus>(
                      initialValue: selectedStatus,
                      decoration: const InputDecoration(
                        labelText: 'حالة الحجز',
                      ),
                      items: BookingStatus.values
                          .map(
                            (BookingStatus status) => DropdownMenuItem(
                              value: status,
                              child: Text(_statusLabel(status)),
                            ),
                          )
                          .toList(),
                      onChanged: (BookingStatus? status) {
                        if (status != null) {
                          setDialogState(() => selectedStatus = status);
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('إلغاء'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('حفظ التعديل'),
                ),
              ],
            ),
      ),
    );
    if (shouldSave == true) {
      final String? nameError = validatePlayerName(name.text);
      final String? phoneError = validateEgyptianMobile(phone.text);
      if (nameError != null || phoneError != null) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(nameError ?? phoneError!)));
        }
      } else {
        try {
          await widget.repository.updateBooking(
            booking.copyWith(
              playerName: name.text.trim(),
              phoneNumber: phone.text.trim(),
              status: selectedStatus,
            ),
          );
          _reload();
        } on ArgumentError catch (error) {
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(error.message.toString())));
          }
        }
      }
    }
    name.dispose();
    phone.dispose();
  }

  Future<void> _deleteBooking(Booking booking) async {
    final bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('حذف الحجز'),
        content: Text('متأكد إنك عايز تلغي حجز ${booking.playerName}؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('رجوع'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (shouldDelete == true) {
      await widget.repository.deleteBooking(booking.reference);
      _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppPageAppBar(title: 'حجوزات الأدمن'),
      body: SafeArea(
        child: FutureBuilder<List<Booking>>(
          future: _bookings,
          builder:
              (BuildContext context, AsyncSnapshot<List<Booking>> snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: FilledButton.tonal(
                      onPressed: () {
                        setState(
                          () => _bookings = widget.repository.getBookings(),
                        );
                      },
                      child: const Text('حاول تاني تحميل الحجوزات'),
                    ),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.data!.isEmpty) {
                  return const Center(child: Text('مفيش حجوزات لسه.'));
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  itemCount: snapshot.data!.length + 1,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (BuildContext context, int index) {
                    if (index == 0) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'كل الحجوزات',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${snapshot.data!.length} حجز متسجلين دلوقتي.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      );
                    }
                    final Booking booking = snapshot.data![index - 1];
                    return _BookingCard(
                      booking: booking,
                      onEdit: () => _editBooking(booking),
                      onDelete: () => _deleteBooking(booking),
                    );
                  },
                );
              },
        ),
      ),
      bottomNavigationBar: const AdminBottomNavigation(selectedIndex: 1),
    );
  }
}

class _BookingCard extends StatelessWidget {
  const _BookingCard({
    required this.booking,
    required this.onEdit,
    required this.onDelete,
  });

  final Booking booking;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    booking.playerName,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                _StatusChip(status: booking.status),
              ],
            ),
            const SizedBox(height: 6),
            Text('رقم الحجز: ${booking.reference}'),
            const Divider(height: 24),
            _Detail(label: 'الميعاد', value: _slotLabel(booking)),
            const SizedBox(height: 8),
            _Detail(label: 'الخدمات', value: _servicesLabel(booking.services)),
            const SizedBox(height: 8),
            _Detail(label: 'الإجمالي', value: '${booking.totalPrice} ج.م'),
            if (booking.phoneNumber.isNotEmpty) ...[
              const SizedBox(height: 8),
              _Detail(label: 'الهاتف', value: booking.phoneNumber),
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('تعديل'),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('حذف'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final BookingStatus status;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Chip(
      label: Text(_statusLabel(status)),
      backgroundColor: colors.primaryContainer,
      side: BorderSide.none,
      labelStyle: TextStyle(color: colors.onPrimaryContainer),
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w700)),
        Expanded(child: Text(value)),
      ],
    );
  }
}

String _statusLabel(BookingStatus status) {
  return switch (status) {
    BookingStatus.tentative => 'مبدئي',
    BookingStatus.confirmed => 'مؤكد',
    BookingStatus.recurring => 'ثابت',
  };
}

String _slotLabel(Booking booking) {
  return '${arabicDateLabel(booking.slot.startTime)} | '
      '${_formatTime(booking.slot.startTime)} - ${_formatTime(booking.slot.endTime)}';
}

String _servicesLabel(List<OptionalService> services) {
  return services.isEmpty
      ? 'مفيش خدمات إضافية'
      : services.map((OptionalService service) => service.name).join('، ');
}

String _formatTime(DateTime time) {
  final int hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
  final String suffix = time.hour >= 12 ? 'م' : 'ص';
  return '$hour:00 $suffix';
}
