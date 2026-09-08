import 'package:flutter/material.dart';

import '../../bookings/domain/booking.dart';
import '../../bookings/domain/booking_draft.dart';
import '../../bookings/domain/booking_repository.dart';
import '../../slots/data/mock_slot_repository.dart';
import '../../slots/domain/time_slot.dart';
import '../../../shared/widgets/app_page_app_bar.dart';
import '../../../shared/widgets/booking_date_picker_field.dart';
import '../domain/notification_repository.dart';
import '../domain/staff_repository.dart';
import 'admin_dashboard_screen.dart'
    show NotificationSettingsScreen, StaffPermissionsScreen;

class AdminWeekScreen extends StatefulWidget {
  const AdminWeekScreen({
    super.key,
    required this.bookingRepository,
    required this.staffRepository,
    required this.notificationRepository,
  });

  final BookingRepository bookingRepository;
  final StaffRepository staffRepository;
  final NotificationRepository notificationRepository;

  @override
  State<AdminWeekScreen> createState() => _AdminWeekScreenState();
}

class _AdminWeekScreenState extends State<AdminWeekScreen> {
  late Future<List<Booking>> _bookings;

  @override
  void initState() {
    super.initState();
    _bookings = widget.bookingRepository.getBookings();
  }

  void _reload() {
    setState(() {
      _bookings = widget.bookingRepository.getBookings();
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppPageAppBar(
      title: 'إدارة الملاعب',
      actions: [
        Semantics(
          label: 'إعدادات لوحة الأدمن',
          button: true,
          child: PopupMenuButton<String>(
            tooltip: 'الإعدادات',
            icon: const Icon(Icons.settings_outlined),
            onSelected: (String value) {
              final Widget page = value == 'staff'
                  ? StaffPermissionsScreen(repository: widget.staffRepository)
                  : NotificationSettingsScreen(
                      repository: widget.notificationRepository,
                    );
              Navigator.of(
                context,
              ).push(MaterialPageRoute<void>(builder: (_) => page));
            },
            itemBuilder: (BuildContext context) => const [
              PopupMenuItem(value: 'staff', child: Text('الصلاحيات')),
              PopupMenuItem(value: 'notifications', child: Text('التنبيهات')),
            ],
          ),
        ),
      ],
    ),
    floatingActionButton: Semantics(
      label: 'إضافة حجز سريع أو ثابت',
      button: true,
      child: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) =>
                  AdminBookingToolsScreen(repository: widget.bookingRepository),
            ),
          );
          _reload();
        },
        icon: const Icon(Icons.add),
        label: const Text('حجز سريع أو ثابت'),
      ),
    ),
    body: FutureBuilder<List<Booking>>(
      future: _bookings,
      builder: (BuildContext context, AsyncSnapshot<List<Booking>> snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final List<DateTime> week = List<DateTime>.generate(
          7,
          (int index) =>
              MockSlotRepository.weekStart.add(Duration(days: index)),
        );
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'الأسبوع يبدأ السبت',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 6),
            const Text('اختار يوم علشان تشوف الساعات المتاحة وتدير حجوزاته.'),
            const SizedBox(height: 16),
            ...week.map(
              (DateTime day) => _DaySummaryCard(
                day: day,
                freeFieldHours: _freeFieldHours(day, snapshot.data!),
                onTap: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => AdminDayScreen(
                        day: day,
                        repository: widget.bookingRepository,
                      ),
                    ),
                  );
                  _reload();
                },
              ),
            ),
            const SizedBox(height: 96),
          ],
        );
      },
    ),
  );
}

class _DaySummaryCard extends StatelessWidget {
  const _DaySummaryCard({
    required this.day,
    required this.freeFieldHours,
    required this.onTap,
  });
  final DateTime day;
  final int freeFieldHours;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      onTap: onTap,
      leading: const CircleAvatar(child: Icon(Icons.calendar_today_outlined)),
      title: Text(_dayLabel(day)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text('$freeFieldHours ساعة ملعب فاضية'),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: freeFieldHours / 15,
              minHeight: 7,
              backgroundColor: Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest,
            ),
          ),
        ],
      ),
      trailing: const Icon(Icons.arrow_back),
    ),
  );
}

class AdminDayScreen extends StatefulWidget {
  const AdminDayScreen({
    super.key,
    required this.day,
    required this.repository,
  });
  final DateTime day;
  final BookingRepository repository;
  @override
  State<AdminDayScreen> createState() => _AdminDayScreenState();
}

class _AdminDayScreenState extends State<AdminDayScreen> {
  late Future<List<Booking>> _bookings;
  @override
  void initState() {
    super.initState();
    _bookings = widget.repository.getBookings();
  }

  void _reload() {
    setState(() {
      _bookings = widget.repository.getBookings();
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppPageAppBar(title: _dayLabel(widget.day)),
    body: FutureBuilder<List<Booking>>(
      future: _bookings,
      builder: (BuildContext context, AsyncSnapshot<List<Booking>> snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final List<Booking> dayBookings = snapshot.data!
            .where(
              (Booking booking) => _sameDay(booking.slot.startTime, widget.day),
            )
            .toList();
        final List<int> availableHours = <int>[16, 17, 18, 19, 20]
            .where(
              (int hour) =>
                  dayBookings
                      .where(
                        (Booking booking) =>
                            booking.slot.startTime.hour == hour,
                      )
                      .length <
                  3,
            )
            .toList();
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'الساعات المتاحة',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 6),
            const Text('بتظهر الساعة لو فيها ملعب واحد فاضي على الأقل.'),
            const SizedBox(height: 12),
            if (availableHours.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('مفيش ساعات فاضية في اليوم ده.'),
                ),
              ),
            ...availableHours.map((int hour) {
              final int freeFields =
                  3 -
                  dayBookings
                      .where(
                        (Booking booking) =>
                            booking.slot.startTime.hour == hour,
                      )
                      .length;
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.sports_soccer),
                  title: Text(
                    '${_formatHour(hour)} - ${_formatHour(hour + 1)}',
                  ),
                  subtitle: Text('$freeFields ملعب فاضي'),
                  trailing: Semantics(
                    label: 'تسجيل لاعب في الساعة دي',
                    button: true,
                    child: IconButton.filledTonal(
                      tooltip: 'تسجيل لاعب',
                      onPressed: () => _registerPlayer(hour, freeFields),
                      icon: const Icon(Icons.person_add_alt_1_outlined),
                    ),
                  ),
                  onTap: () => _registerPlayer(hour, freeFields),
                ),
              );
            }),
            const SizedBox(height: 24),
            ExpansionTile(
              title: const Text('إدارة الحجوزات المسجلة'),
              subtitle: Text('${dayBookings.length} حجز'),
              children: dayBookings.isEmpty
                  ? const [
                      Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('مفيش حجوزات في اليوم ده.'),
                      ),
                    ]
                  : dayBookings
                        .map(
                          (Booking booking) => ListTile(
                            title: Text(
                              '${booking.playerName} - ملعب ${booking.fieldNumber}',
                            ),
                            subtitle: Text(
                              '${_formatHour(booking.slot.startTime.hour)} | ${_bookingStatus(booking.status)}',
                            ),
                            trailing: Wrap(
                              spacing: 0,
                              children: [
                                IconButton(
                                  tooltip: 'تعديل',
                                  onPressed: () => _editBooking(booking),
                                  icon: const Icon(Icons.edit_outlined),
                                ),
                                IconButton(
                                  tooltip: 'حذف',
                                  onPressed: () => _deleteBooking(booking),
                                  icon: const Icon(Icons.delete_outline),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
            ),
          ],
        );
      },
    ),
  );

  Future<void> _editBooking(Booking booking) async {
    final TextEditingController name = TextEditingController(
      text: booking.playerName,
    );
    DateTime selectedDay = DateTime(
      booking.slot.startTime.year,
      booking.slot.startTime.month,
      booking.slot.startTime.day,
    );
    int selectedHour = booking.slot.startTime.hour;
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
                      decoration: const InputDecoration(
                        labelText: 'اسم اللاعب أو المجموعة',
                      ),
                    ),
                    const SizedBox(height: 12),
                    BookingDatePickerField(
                      selectedDate: selectedDay,
                      firstDate: MockSlotRepository.weekStart,
                      lastDate: MockSlotRepository.weekStart.add(
                        const Duration(days: 6),
                      ),
                      onChanged: (DateTime day) {
                        setDialogState(() => selectedDay = day);
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      initialValue: selectedHour,
                      decoration: const InputDecoration(labelText: 'الساعة'),
                      items: <int>[16, 17, 18, 19, 20]
                          .map(
                            (int hour) => DropdownMenuItem<int>(
                              value: hour,
                              child: Text(
                                '${_formatHour(hour)} - ${_formatHour(hour + 1)}',
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (int? hour) {
                        if (hour != null) {
                          setDialogState(() => selectedHour = hour);
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
                  child: const Text('حفظ'),
                ),
              ],
            ),
      ),
    );
    if (shouldSave == true) {
      try {
        final TimeSlot updatedSlot = TimeSlot(
          id: booking.slot.id,
          startTime: DateTime(
            selectedDay.year,
            selectedDay.month,
            selectedDay.day,
            selectedHour,
          ),
          endTime: DateTime(
            selectedDay.year,
            selectedDay.month,
            selectedDay.day,
            selectedHour + 1,
          ),
          status: SlotStatus.booked,
        );
        await widget.repository.updateBooking(
          booking.copyWith(playerName: name.text, slot: updatedSlot),
        );
        _reload();
      } on StateError catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(error.message.toString())));
        }
      }
    }
    name.dispose();
  }

  Future<void> _deleteBooking(Booking booking) async {
    final bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('حذف الحجز'),
        content: Text('حذف حجز ${booking.playerName}؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء'),
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

  Future<void> _registerPlayer(int hour, int freeFields) async {
    final _AdminRegistration? registration =
        await showModalBottomSheet<_AdminRegistration>(
          context: context,
          isScrollControlled: true,
          builder: (_) => _PlayerRegistrationSheet(
            day: widget.day,
            hour: hour,
            freeFields: freeFields,
          ),
        );
    if (registration == null) {
      return;
    }

    final BookingDraft draft = BookingDraft(
      slot: TimeSlot(
        id: 'admin-${widget.day.toIso8601String()}-$hour',
        startTime: DateTime(
          widget.day.year,
          widget.day.month,
          widget.day.day,
          hour,
        ),
        endTime: DateTime(
          widget.day.year,
          widget.day.month,
          widget.day.day,
          hour + 1,
        ),
        status: SlotStatus.available,
      ),
      basePrice: 800,
    );
    try {
      final Booking booking = await widget.repository.createAdminBooking(
        playerName: registration.playerName,
        phoneNumber: registration.phoneNumber,
        draft: draft,
        status: registration.recurrence == _BookingRecurrence.weekly
            ? BookingStatus.recurring
            : registration.status,
      );
      _reload();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'اتسجل ${booking.playerName} في ملعب ${booking.fieldNumber}.',
            ),
          ),
        );
      }
    } on ArgumentError catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message.toString())));
      }
    } on StateError catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message.toString())));
      }
    }
  }
}

class _AdminRegistration {
  const _AdminRegistration({
    required this.playerName,
    required this.phoneNumber,
    required this.status,
    required this.recurrence,
  });

  final String playerName;
  final String phoneNumber;
  final BookingStatus status;
  final _BookingRecurrence recurrence;
}

enum _BookingRecurrence { oneOff, weekly }

class _PlayerRegistrationSheet extends StatefulWidget {
  const _PlayerRegistrationSheet({
    required this.day,
    required this.hour,
    required this.freeFields,
  });

  final DateTime day;
  final int hour;
  final int freeFields;

  @override
  State<_PlayerRegistrationSheet> createState() =>
      _PlayerRegistrationSheetState();
}

class _PlayerRegistrationSheetState extends State<_PlayerRegistrationSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _name = TextEditingController();
  final TextEditingController _phone = TextEditingController();
  BookingStatus _status = BookingStatus.confirmed;
  _BookingRecurrence _recurrence = _BookingRecurrence.oneOff;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: EdgeInsetsDirectional.fromSTEB(
        20,
        12,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'تسجيل لاعب جديد',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 6),
            Text(
              '${_dayLabel(widget.day)} | ${_formatHour(widget.hour)} - ${_formatHour(widget.hour + 1)} | ${widget.freeFields} ملعب فاضي',
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _name,
              autofocus: true,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'اسم اللاعب أو المجموعة',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (String? value) =>
                  value == null || value.trim().isEmpty
                  ? 'اكتب اسم اللاعب أو المجموعة.'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: 'رقم الهاتف',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
              validator: (String? value) =>
                  value == null || value.trim().isEmpty
                  ? 'اكتب رقم هاتف للتواصل.'
                  : null,
            ),
            const SizedBox(height: 20),
            Text('حالة الحجز', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            SegmentedButton<BookingStatus>(
              segments: const [
                ButtonSegment(
                  value: BookingStatus.confirmed,
                  icon: Icon(Icons.check_circle_outline),
                  label: Text('مؤكد'),
                ),
                ButtonSegment(
                  value: BookingStatus.tentative,
                  icon: Icon(Icons.timer_outlined),
                  label: Text('مبدئي'),
                ),
              ],
              selected: <BookingStatus>{_status},
              onSelectionChanged: (Set<BookingStatus> selection) {
                setState(() => _status = selection.single);
              },
            ),
            const SizedBox(height: 20),
            Text('تكرار الحجز', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            SegmentedButton<_BookingRecurrence>(
              segments: const [
                ButtonSegment(
                  value: _BookingRecurrence.oneOff,
                  icon: Icon(Icons.looks_one_outlined),
                  label: Text('لمرة'),
                ),
                ButtonSegment(
                  value: _BookingRecurrence.weekly,
                  icon: Icon(Icons.repeat_outlined),
                  label: Text('ثابت'),
                ),
              ],
              selected: <_BookingRecurrence>{_recurrence},
              onSelectionChanged: (Set<_BookingRecurrence> selection) {
                setState(() => _recurrence = selection.single);
              },
            ),
            const SizedBox(height: 8),
            Text(
              _recurrence == _BookingRecurrence.weekly
                  ? 'الثابت بيتسجل لنفس اليوم والساعة كل أسبوع.'
                  : 'الحجز ده لموعد واحد فقط.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  Navigator.of(context).pop(
                    _AdminRegistration(
                      playerName: _name.text,
                      phoneNumber: _phone.text,
                      status: _status,
                      recurrence: _recurrence,
                    ),
                  );
                }
              },
              icon: const Icon(Icons.save_outlined),
              label: const Text('حفظ الحجز'),
            ),
          ],
        ),
      ),
    ),
  );
}

class AdminBookingToolsScreen extends StatefulWidget {
  const AdminBookingToolsScreen({super.key, required this.repository});
  final BookingRepository repository;
  @override
  State<AdminBookingToolsScreen> createState() =>
      _AdminBookingToolsScreenState();
}

class _AdminBookingToolsScreenState extends State<AdminBookingToolsScreen> {
  final TextEditingController _name = TextEditingController();
  final TextEditingController _phone = TextEditingController();
  late DateTime _day;
  int _hour = 16;
  bool _recurring = false;
  String? _message;
  @override
  void initState() {
    super.initState();
    _day = MockSlotRepository.weekStart;
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppPageAppBar(title: 'حجز سريع أو ثابت'),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          SwitchListTile(
            value: _recurring,
            onChanged: (bool value) => setState(() => _recurring = value),
            title: const Text('حجز أسبوعي ثابت'),
          ),
          TextField(
            controller: _name,
            decoration: const InputDecoration(
              labelText: 'اسم اللاعب أو المجموعة',
            ),
          ),
          TextField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: 'رقم الهاتف'),
          ),
          const SizedBox(height: 16),
          BookingDatePickerField(
            selectedDate: _day,
            firstDate: MockSlotRepository.weekStart,
            lastDate: MockSlotRepository.weekStart.add(const Duration(days: 6)),
            onChanged: (DateTime day) => setState(() => _day = day),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            initialValue: _hour,
            decoration: const InputDecoration(labelText: 'الساعة'),
            items: <int>[16, 17, 18, 19, 20]
                .map(
                  (int hour) => DropdownMenuItem(
                    value: hour,
                    child: Text(
                      '${_formatHour(hour)} - ${_formatHour(hour + 1)}',
                    ),
                  ),
                )
                .toList(),
            onChanged: (int? hour) {
              if (hour != null) setState(() => _hour = hour);
            },
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _create,
            child: Text(
              _recurring ? 'تثبيت الحجز الأسبوعي' : 'تسجيل حجز مبدئي',
            ),
          ),
          if (_message != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(_message!),
            ),
        ],
      ),
    );
  }

  Future<void> _create() async {
    final BookingDraft draft = BookingDraft(
      slot: TimeSlot(
        id: 'admin-${_day.toIso8601String()}-$_hour',
        startTime: DateTime(_day.year, _day.month, _day.day, _hour),
        endTime: DateTime(_day.year, _day.month, _day.day, _hour + 1),
        status: SlotStatus.available,
      ),
      basePrice: 800,
    );
    try {
      final Booking booking = _recurring
          ? await widget.repository.createRecurringBooking(
              playerName: _name.text.isEmpty ? 'مجموعة ثابتة' : _name.text,
              phoneNumber: _phone.text,
              draft: draft,
            )
          : await widget.repository.createTentativeBooking(
              playerName: _name.text.isEmpty ? 'حجز استقبال' : _name.text,
              phoneNumber: _phone.text,
              draft: draft,
            );
      setState(() => _message = 'اتسجل الحجز في ملعب ${booking.fieldNumber}.');
    } on StateError catch (error) {
      setState(() => _message = error.message.toString());
    }
  }
}

int _freeFieldHours(DateTime day, List<Booking> bookings) =>
    15 -
    bookings
        .where((Booking booking) => _sameDay(booking.slot.startTime, day))
        .length;
bool _sameDay(DateTime first, DateTime second) =>
    first.year == second.year &&
    first.month == second.month &&
    first.day == second.day;
String _dayLabel(DateTime day) {
  const List<String> days = <String>[
    'السبت',
    'الأحد',
    'الاثنين',
    'الثلاثاء',
    'الأربعاء',
    'الخميس',
    'الجمعة',
  ];
  return '${days[(day.weekday + 1) % 7]} ${day.day} سبتمبر';
}

String _formatHour(int hour) {
  final int display = hour % 12 == 0 ? 12 : hour % 12;
  return '$display:00 ${hour >= 12 ? 'م' : 'ص'}';
}

String _bookingStatus(BookingStatus status) => switch (status) {
  BookingStatus.confirmed => 'مؤكد',
  BookingStatus.tentative => 'مبدئي',
  BookingStatus.recurring => 'ثابت',
};
