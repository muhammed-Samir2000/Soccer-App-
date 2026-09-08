import 'package:flutter/material.dart';

import '../../../app/router.dart';
import '../../../shared/widgets/app_page_app_bar.dart';
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
  late Stream<List<TimeSlot>> _slots;

  @override
  void initState() {
    super.initState();
    _selectedDay = MockSlotRepository.weekStart;
    _slots = widget.repository.watchSlotsForDay(_selectedDay);
  }

  void _selectDay(DateTime day) {
    setState(() {
      _selectedDay = day;
      _slots = widget.repository.watchSlotsForDay(day);
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<DateTime> days = List<DateTime>.generate(
      7,
      (int index) => MockSlotRepository.weekStart.add(Duration(days: index)),
    );

    return Scaffold(
      appBar: AppPageAppBar(
        title: 'المواعيد الفاضية',
        actions: [
          Semantics(
            label: 'فتح حجوزاتي',
            button: true,
            child: IconButton(
              tooltip: 'حجوزاتي',
              onPressed: () => Navigator.of(context).pushNamed(
                AppRouter.myBookingsRoute,
                arguments: widget.player.id,
              ),
              icon: const Icon(Icons.calendar_month_outlined),
            ),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 12),
            child: Center(child: Text('أهلاً يا ${widget.player.name}')),
          ),
        ],
      ),
      body: SafeArea(
        child: StreamBuilder<List<TimeSlot>>(
          stream: _slots,
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
                  padding: const EdgeInsetsDirectional.fromSTEB(20, 8, 20, 24),
                  children: [
                    Text(
                      'اختار ميعاد ماتشك',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'المواعيد المتاحة قدامك لمدة ${days.length} أيام.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 92,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: days.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 10),
                        itemBuilder: (BuildContext context, int index) {
                          final DateTime day = days[index];
                          final bool isSelected = _sameDay(day, _selectedDay);
                          return Semantics(
                            label: 'اختيار ${_dayLabel(day)}',
                            selected: isSelected,
                            button: true,
                            child: InkWell(
                              onTap: () => _selectDay(day),
                              borderRadius: BorderRadius.circular(16),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                width: 74,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Theme.of(context).colorScheme.primary
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isSelected
                                        ? Theme.of(context).colorScheme.primary
                                        : Theme.of(
                                            context,
                                          ).colorScheme.outlineVariant,
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      _weekdayName(day),
                                      style: TextStyle(
                                        color: isSelected
                                            ? Theme.of(
                                                context,
                                              ).colorScheme.onPrimary
                                            : null,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${day.day}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(
                                            color: isSelected
                                                ? Theme.of(
                                                    context,
                                                  ).colorScheme.onPrimary
                                                : null,
                                          ),
                                    ),
                                    Text(
                                      'سبتمبر',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isSelected
                                            ? Theme.of(
                                                context,
                                              ).colorScheme.onPrimary
                                            : null,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
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
    final _SlotStyle style = _slotStyle(colors, slot.status);

    return Semantics(
      label: '${_statusLabel(slot.status)}، ${_timeRange(slot)}',
      button: isAvailable,
      enabled: isAvailable,
      child: Material(
        color: style.background,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          key: Key(slot.id),
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(style.icon, color: style.foreground),
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
                      Text(
                        _statusLabel(slot.status),
                        style: TextStyle(color: style.foreground),
                      ),
                    ],
                  ),
                ),
                if (isAvailable)
                  Icon(Icons.arrow_back, color: style.foreground),
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
      spacing: 10,
      runSpacing: 8,
      children: [
        _LegendItem(color: Color(0xFFD7F7E8), label: 'فاضي'),
        _LegendItem(color: Color(0xFFFFF0D6), label: 'محجوز مؤقتاً'),
        _LegendItem(color: Color(0xFFE4E9E7), label: 'محجوز'),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});
  final Color color;
  final String label;
  @override
  Widget build(BuildContext context) => Chip(
    avatar: CircleAvatar(backgroundColor: color, radius: 7),
    label: Text(label),
  );
}

String _dayLabel(DateTime day) {
  return '${_weekdayName(day)} ${day.day} سبتمبر';
}

String _weekdayName(DateTime day) {
  const List<String> weekdays = [
    'الاثنين',
    'الثلاثاء',
    'الأربعاء',
    'الخميس',
    'الجمعة',
    'السبت',
    'الأحد',
  ];
  return weekdays[day.weekday - 1];
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

class _SlotStyle {
  const _SlotStyle({
    required this.background,
    required this.foreground,
    required this.icon,
  });
  final Color background;
  final Color foreground;
  final IconData icon;
}

_SlotStyle _slotStyle(ColorScheme colors, SlotStatus status) =>
    switch (status) {
      SlotStatus.available => const _SlotStyle(
        background: Color(0xFFD7F7E8),
        foreground: Color(0xFF075E42),
        icon: Icons.sports_soccer,
      ),
      SlotStatus.held => const _SlotStyle(
        background: Color(0xFFFFF0D6),
        foreground: Color(0xFF9A5A00),
        icon: Icons.timer_outlined,
      ),
      SlotStatus.booked => _SlotStyle(
        background: const Color(0xFFE4E9E7),
        foreground: colors.onSurfaceVariant,
        icon: Icons.lock_outline,
      ),
    };
