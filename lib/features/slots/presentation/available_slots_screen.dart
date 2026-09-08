import 'package:flutter/material.dart';

import '../../../app/router.dart';
import '../../auth/domain/app_user.dart';
import '../data/mock_slot_repository.dart';
import '../domain/slot_repository.dart';
import '../domain/time_slot.dart';

class AvailableSlotsScreen extends StatefulWidget {
  const AvailableSlotsScreen({
    super.key,
    required this.player,
    required this.repository,
  });

  final AppUser player;
  final SlotRepository repository;

  @override
  State<AvailableSlotsScreen> createState() => _AvailableSlotsScreenState();
}

class _AvailableSlotsScreenState extends State<AvailableSlotsScreen> {
  late DateTime _selectedDay;
  late Future<List<TimeSlot>> _slots;

  @override
  void initState() {
    super.initState();
    _selectedDay = MockSlotRepository.weekStart;
    _slots = widget.repository.getSlotsForDay(_selectedDay);
  }

  void _selectDay(DateTime day) {
    setState(() {
      _selectedDay = day;
      _slots = widget.repository.getSlotsForDay(day);
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<DateTime> days = List<DateTime>.generate(
      7,
      (int index) => MockSlotRepository.weekStart.add(Duration(days: index)),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('المواعيد الفاضية'),
        actions: [
          IconButton(
            tooltip: 'حجوزاتي',
            onPressed: () => Navigator.of(
              context,
            ).pushNamed(AppRouter.myBookingsRoute, arguments: widget.player.id),
            icon: const Icon(Icons.calendar_month_outlined),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: Center(child: Text('أهلاً يا ${widget.player.name}')),
          ),
        ],
      ),
      body: SafeArea(
        child: FutureBuilder<List<TimeSlot>>(
          future: _slots,
          builder:
              (BuildContext context, AsyncSnapshot<List<TimeSlot>> snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: FilledButton.tonal(
                      onPressed: () => _selectDay(_selectedDay),
                      child: const Text('حاول تاني تحميل المواعيد'),
                    ),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                return ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  children: [
                    Text(
                      'اختار ميعاد ماتشك',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'المواعيد المتاحة قدامك لمدة 3 أيام.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 24),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: days.map((DateTime day) {
                          final bool isSelected = _sameDay(day, _selectedDay);
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(_dayLabel(day)),
                              selected: isSelected,
                              onSelected: (_) => _selectDay(day),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'ملعب 1',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    ...snapshot.data!.map(
                      (TimeSlot slot) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _SlotCard(
                          slot: slot,
                          onTap: slot.isAvailable
                              ? () => Navigator.of(context).pushNamed(
                                  AppRouter.bookingSummaryRoute,
                                  arguments: slot,
                                )
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const _SlotLegend(),
                  ],
                );
              },
        ),
      ),
    );
  }
}

class _SlotCard extends StatelessWidget {
  const _SlotCard({required this.slot, required this.onTap});

  final TimeSlot slot;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final bool isAvailable = slot.isAvailable;
    final Color background = isAvailable
        ? colors.primaryContainer
        : colors.surfaceContainerHighest;
    final Color foreground = isAvailable
        ? colors.onPrimaryContainer
        : colors.onSurfaceVariant;

    return Semantics(
      button: isAvailable,
      enabled: isAvailable,
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          key: Key(slot.id),
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(
                  isAvailable ? Icons.sports_soccer : Icons.lock_outline,
                  color: foreground,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _timeRange(slot),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(_statusLabel(slot.status)),
                    ],
                  ),
                ),
                if (isAvailable) Icon(Icons.arrow_back, color: foreground),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SlotLegend extends StatelessWidget {
  const _SlotLegend();

  @override
  Widget build(BuildContext context) {
    return const Wrap(
      spacing: 16,
      children: [Text('الأخضر: فاضي'), Text('الرمادي: مش متاح')],
    );
  }
}

String _dayLabel(DateTime day) {
  const List<String> weekdays = [
    'الاتنين',
    'التلات',
    'الأربع',
    'الخميس',
    'الجمعة',
    'السبت',
    'الأحد',
  ];
  return '${weekdays[day.weekday - 1]} ${day.day} سبتمبر';
}

String _timeRange(TimeSlot slot) =>
    '${_formatTime(slot.startTime)} - ${_formatTime(slot.endTime)}';

String _formatTime(DateTime time) {
  final int hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
  final String suffix = time.hour >= 12 ? 'م' : 'ص';
  return '$hour:00 $suffix';
}

String _statusLabel(SlotStatus status) {
  return switch (status) {
    SlotStatus.available => 'فاضي دلوقتي',
    SlotStatus.held => 'محجوز مؤقتاً',
    SlotStatus.booked => 'محجوز',
  };
}

bool _sameDay(DateTime first, DateTime second) {
  return first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;
}
