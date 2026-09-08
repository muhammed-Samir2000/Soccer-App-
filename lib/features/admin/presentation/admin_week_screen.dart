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
import '../domain/venue_settings.dart';
import '../domain/venue_settings_repository.dart';
import 'admin_dashboard_screen.dart'
    show NotificationSettingsScreen, StaffPermissionsScreen;

class AdminWeekScreen extends StatefulWidget {
  const AdminWeekScreen({
    super.key,
    required this.bookingRepository,
    required this.staffRepository,
    required this.notificationRepository,
    required this.venueSettingsRepository,
  });

  final BookingRepository bookingRepository;
  final StaffRepository staffRepository;
  final NotificationRepository notificationRepository;
  final VenueSettingsRepository venueSettingsRepository;

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
              final Widget page = switch (value) {
                'venue' => VenueSettingsScreen(
                  settingsRepository: widget.venueSettingsRepository,
                  bookingRepository: widget.bookingRepository,
                ),
                'staff' => StaffPermissionsScreen(
                  repository: widget.staffRepository,
                ),
                _ => NotificationSettingsScreen(
                  repository: widget.notificationRepository,
                ),
              };
              Navigator.of(
                context,
              ).push(MaterialPageRoute<void>(builder: (_) => page));
            },
            itemBuilder: (BuildContext context) => const [
              PopupMenuItem(value: 'venue', child: Text('إعدادات الملعب')),
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
              builder: (_) => AdminBookingToolsScreen(
                repository: widget.bookingRepository,
                venueSettingsRepository: widget.venueSettingsRepository,
              ),
            ),
          );
          _reload();
        },
        icon: const Icon(Icons.add),
        label: const Text('حجز سريع أو ثابت'),
      ),
    ),
    body: StreamBuilder<VenueSettings>(
      stream: widget.venueSettingsRepository.watchSettings(),
      builder: (BuildContext context, AsyncSnapshot<VenueSettings> settings) {
        if (!settings.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        return FutureBuilder<List<Booking>>(
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
                  'لوحة التحكم',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 6),
                Text(
                  '${settings.data!.fieldCount} ملاعب | ${_formatHour(settings.data!.openingHour)} - ${_formatHour(settings.data!.closingHour)}',
                ),
                const SizedBox(height: 16),
                _OccupancySummary(
                  bookings: snapshot.data!,
                  week: week,
                  settings: settings.data!,
                ),
                const SizedBox(height: 24),
                Text(
                  'الأسبوع يبدأ السبت',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 6),
                const Text(
                  'اختار يوم علشان تشوف الساعات المتاحة وتدير حجوزاته.',
                ),
                const SizedBox(height: 16),
                ...week.map(
                  (DateTime day) => _DaySummaryCard(
                    day: day,
                    freeFieldHours: _freeFieldHours(
                      day,
                      snapshot.data!,
                      settings.data!,
                    ),
                    totalFieldHours: settings.data!.dailyFieldHours,
                    onTap: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => AdminDayScreen(
                            day: day,
                            repository: widget.bookingRepository,
                            venueSettingsRepository:
                                widget.venueSettingsRepository,
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
        );
      },
    ),
  );
}

class _DaySummaryCard extends StatelessWidget {
  const _DaySummaryCard({
    required this.day,
    required this.freeFieldHours,
    required this.totalFieldHours,
    required this.onTap,
  });
  final DateTime day;
  final int freeFieldHours;
  final int totalFieldHours;
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
              value: freeFieldHours / totalFieldHours,
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
    required this.venueSettingsRepository,
  });
  final DateTime day;
  final BookingRepository repository;
  final VenueSettingsRepository venueSettingsRepository;
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
    body: StreamBuilder<VenueSettings>(
      stream: widget.venueSettingsRepository.watchSettings(),
      builder: (BuildContext context, AsyncSnapshot<VenueSettings> settings) {
        if (!settings.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        return FutureBuilder<List<Booking>>(
          future: _bookings,
          builder: (BuildContext context, AsyncSnapshot<List<Booking>> snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final List<Booking> dayBookings = snapshot.data!
                .where(
                  (Booking booking) =>
                      _sameDay(booking.slot.startTime, widget.day),
                )
                .toList();
            final List<int> availableHours =
                List<int>.generate(
                      settings.data!.operatingHours,
                      (int index) => settings.data!.openingHour + index,
                    )
                    .where(
                      (int hour) =>
                          dayBookings
                              .where(
                                (Booking booking) =>
                                    booking.slot.startTime.hour == hour,
                              )
                              .length <
                          settings.data!.fieldCount,
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
                      settings.data!.fieldCount -
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
  const AdminBookingToolsScreen({
    super.key,
    required this.repository,
    required this.venueSettingsRepository,
  });
  final BookingRepository repository;
  final VenueSettingsRepository venueSettingsRepository;
  @override
  State<AdminBookingToolsScreen> createState() =>
      _AdminBookingToolsScreenState();
}

class _AdminBookingToolsScreenState extends State<AdminBookingToolsScreen> {
  final TextEditingController _name = TextEditingController();
  final TextEditingController _phone = TextEditingController();
  late DateTime _day;
  late int _hour;
  VenueSettings? _settings;
  bool _recurring = false;
  String? _message;
  @override
  void initState() {
    super.initState();
    _day = MockSlotRepository.weekStart;
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final VenueSettings settings = await widget.venueSettingsRepository
        .getSettings();
    if (mounted) {
      setState(() {
        _settings = settings;
        _hour = settings.openingHour;
      });
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final VenueSettings? settings = _settings;
    if (settings == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
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
            items:
                List<int>.generate(
                      settings.operatingHours,
                      (int index) => settings.openingHour + index,
                    )
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

class VenueSettingsScreen extends StatefulWidget {
  const VenueSettingsScreen({
    super.key,
    required this.settingsRepository,
    required this.bookingRepository,
  });

  final VenueSettingsRepository settingsRepository;
  final BookingRepository bookingRepository;

  @override
  State<VenueSettingsScreen> createState() => _VenueSettingsScreenState();
}

class _VenueSettingsScreenState extends State<VenueSettingsScreen> {
  VenueSettings? _settings;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final VenueSettings settings = await widget.settingsRepository
        .getSettings();
    if (mounted) {
      setState(() => _settings = settings);
    }
  }

  Future<void> _pickHour({required bool opening}) async {
    final VenueSettings settings = _settings!;
    final TimeOfDay? selected = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: opening ? settings.openingHour : settings.closingHour,
        minute: 0,
      ),
      helpText: opening ? 'اختار ساعة الفتح' : 'اختار ساعة القفل',
      cancelText: 'إلغاء',
      confirmText: 'اختيار',
      builder: (BuildContext context, Widget? child) => Directionality(
        textDirection: TextDirection.rtl,
        child: child ?? const SizedBox.shrink(),
      ),
    );
    if (selected == null) {
      return;
    }
    if (selected.minute != 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('اختار ساعة كاملة من غير دقائق.')),
        );
      }
      return;
    }
    setState(() {
      _settings = opening
          ? settings.copyWith(openingHour: selected.hour)
          : settings.copyWith(closingHour: selected.hour);
    });
  }

  Future<void> _save() async {
    final VenueSettings settings = _settings!;
    if (settings.openingHour >= settings.closingHour) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('وقت الفتح لازم يسبق وقت القفل.')),
      );
      return;
    }
    setState(() => _isSaving = true);
    try {
      await widget.bookingRepository.updateFieldCount(settings.fieldCount);
      await widget.settingsRepository.updateSettings(settings);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } on ArgumentError catch (error) {
      _showError(error.message.toString());
    } on StateError catch (error) {
      _showError(error.message.toString());
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final VenueSettings? settings = _settings;
    if (settings == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: const AppPageAppBar(title: 'إعدادات الملعب'),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'تشغيل الملاعب',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 6),
          const Text(
            'التغييرات دي بتظهر فوراً في لوحة التحكم والحجوزات الجديدة.',
          ),
          const SizedBox(height: 20),
          DropdownButtonFormField<int>(
            initialValue: settings.fieldCount,
            decoration: const InputDecoration(
              labelText: 'عدد الملاعب',
              prefixIcon: Icon(Icons.sports_soccer_outlined),
            ),
            items: List<int>.generate(12, (int index) => index + 1)
                .map(
                  (int count) => DropdownMenuItem(
                    value: count,
                    child: Text('$count ملاعب'),
                  ),
                )
                .toList(),
            onChanged: _isSaving
                ? null
                : (int? value) {
                    if (value != null) {
                      setState(
                        () => _settings = settings.copyWith(fieldCount: value),
                      );
                    }
                  },
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.wb_sunny_outlined),
                  title: const Text('موعد فتح الملعب'),
                  subtitle: Text(_formatHour(settings.openingHour)),
                  trailing: const Icon(Icons.edit_outlined),
                  onTap: _isSaving ? null : () => _pickHour(opening: true),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.nightlight_outlined),
                  title: const Text('موعد قفل الملعب'),
                  subtitle: Text(_formatHour(settings.closingHour)),
                  trailing: const Icon(Icons.edit_outlined),
                  onTap: _isSaving ? null : () => _pickHour(opening: false),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('قواعد الحجز الحالية'),
              subtitle: Text(
                'مدة الحجز ساعة واحدة | السعة اليومية ${settings.dailyFieldHours} ساعة ملعب.',
              ),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _isSaving ? null : _save,
            icon: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined),
            label: const Text('حفظ الإعدادات'),
          ),
        ],
      ),
    );
  }
}

class _OccupancySummary extends StatelessWidget {
  const _OccupancySummary({
    required this.bookings,
    required this.week,
    required this.settings,
  });

  final List<Booking> bookings;
  final List<DateTime> week;
  final VenueSettings settings;

  @override
  Widget build(BuildContext context) {
    final List<Booking> weekBookings = bookings
        .where(_isInSelectedWeek)
        .where(
          (Booking booking) =>
              booking.fieldNumber <= settings.fieldCount &&
              booking.slot.startTime.hour >= settings.openingHour &&
              booking.slot.startTime.hour < settings.closingHour,
        )
        .toList();
    final int total = settings.dailyFieldHours * week.length;
    final int occupied = weekBookings.length;
    final double progress = total == 0 ? 0 : occupied / total;
    final int percentage = (progress * 100).round();
    final int perFieldCapacity = settings.operatingHours * week.length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.insights_outlined),
                const SizedBox(width: 8),
                Text(
                  'نسبة إشغال الملاعب',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                Text('$percentage%'),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(value: progress, minHeight: 10),
            ),
            const SizedBox(height: 8),
            Text('$occupied من $total ساعة ملعب محجوزة الأسبوع ده.'),
            const SizedBox(height: 18),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: List<Widget>.generate(settings.fieldCount, (int index) {
                final int field = index + 1;
                final int fieldBookings = weekBookings
                    .where((Booking booking) => booking.fieldNumber == field)
                    .length;
                final int fieldPercentage =
                    (fieldBookings / perFieldCapacity * 100).round();
                return SizedBox(
                  width: 142,
                  child: _FieldOccupancyCard(
                    fieldNumber: field,
                    percentage: fieldPercentage,
                    occupiedHours: fieldBookings,
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  bool _isInSelectedWeek(Booking booking) =>
      !booking.slot.startTime.isBefore(week.first) &&
      booking.slot.startTime.isBefore(week.last.add(const Duration(days: 1)));
}

class _FieldOccupancyCard extends StatelessWidget {
  const _FieldOccupancyCard({
    required this.fieldNumber,
    required this.percentage,
    required this.occupiedHours,
  });

  final int fieldNumber;
  final int percentage;
  final int occupiedHours;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('ملعب $fieldNumber'),
        const SizedBox(height: 4),
        Text('$percentage% إشغال'),
        Text('$occupiedHours ساعة محجوزة'),
      ],
    ),
  );
}

int _freeFieldHours(
  DateTime day,
  List<Booking> bookings,
  VenueSettings settings,
) {
  final int occupied = bookings
      .where(
        (Booking booking) =>
            _sameDay(booking.slot.startTime, day) &&
            booking.fieldNumber <= settings.fieldCount &&
            booking.slot.startTime.hour >= settings.openingHour &&
            booking.slot.startTime.hour < settings.closingHour,
      )
      .length;
  final int free = settings.dailyFieldHours - occupied;
  return free < 0 ? 0 : free;
}

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
