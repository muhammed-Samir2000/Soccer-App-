import 'package:flutter/material.dart';

import '../../../shared/widgets/app_page_app_bar.dart';

import '../../bookings/domain/booking.dart';
import '../../bookings/domain/booking_draft.dart';
import '../../bookings/domain/booking_repository.dart';
import '../../slots/domain/time_slot.dart';
import '../domain/notification_repository.dart';
import '../domain/notification_setting.dart';
import '../domain/staff_member.dart';
import '../domain/staff_repository.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({
    super.key,
    required this.bookingRepository,
    required this.staffRepository,
    required this.notificationRepository,
  });
  final BookingRepository bookingRepository;
  final StaffRepository staffRepository;
  final NotificationRepository notificationRepository;
  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  late Future<List<Booking>> _bookings;
  @override
  void initState() {
    super.initState();
    _bookings = widget.bookingRepository.getBookings();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: const AppPageAppBar(title: 'إدارة الملاعب'),
    body: FutureBuilder<List<Booking>>(
      future: _bookings,
      builder: (BuildContext context, AsyncSnapshot<List<Booking>> snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'جدول ملاعب يوم ٧ سبتمبر',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            _FieldGrid(bookings: snapshot.data!),
            const SizedBox(height: 20),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _NavButton(
                  label: 'حجز سريع أو ثابت',
                  icon: Icons.add_circle_outline,
                  page: AdminBookingToolsScreen(
                    repository: widget.bookingRepository,
                  ),
                ),
                _NavButton(
                  label: 'صلاحيات الموظفين',
                  icon: Icons.manage_accounts_outlined,
                  page: StaffPermissionsScreen(
                    repository: widget.staffRepository,
                  ),
                ),
                _NavButton(
                  label: 'التنبيهات',
                  icon: Icons.notifications_outlined,
                  page: NotificationSettingsScreen(
                    repository: widget.notificationRepository,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    ),
  );
}

class _FieldGrid extends StatelessWidget {
  const _FieldGrid({required this.bookings});
  final List<Booking> bookings;
  @override
  Widget build(BuildContext context) => Table(
    border: TableBorder.all(
      color: Theme.of(context).colorScheme.outlineVariant,
    ),
    children: [
      const TableRow(
        children: [
          _GridCell('الساعة'),
          _GridCell('ملعب ١'),
          _GridCell('ملعب ٢'),
          _GridCell('ملعب ٣'),
        ],
      ),
      ...[16, 17, 18, 19, 20].map(
        (int hour) => TableRow(
          children: [
            _GridCell('$hour:00'),
            ...[1, 2, 3].map((int field) => _GridCell(_cellLabel(hour, field))),
          ],
        ),
      ),
    ],
  );
  String _cellLabel(int hour, int field) {
    final Booking? booking = bookings.cast<Booking?>().firstWhere(
      (Booking? item) =>
          item?.fieldNumber == field && item?.slot.startTime.hour == hour,
      orElse: () => null,
    );
    if (booking == null) return '+ فاضي';
    return '${booking.playerName}\n${_status(booking.status)}';
  }

  String _status(BookingStatus status) => switch (status) {
    BookingStatus.confirmed => 'مؤكد',
    BookingStatus.tentative => 'مبدئي',
    BookingStatus.recurring => 'ثابت',
  };
}

class _GridCell extends StatelessWidget {
  const _GridCell(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(8),
    child: Text(text, textAlign: TextAlign.center),
  );
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.label,
    required this.icon,
    required this.page,
  });
  final String label;
  final IconData icon;
  final Widget page;
  @override
  Widget build(BuildContext context) => FilledButton.tonalIcon(
    onPressed: () => Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => page)),
    icon: Icon(icon),
    label: Text(label),
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
  bool _recurring = false;
  String _message = '';
  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: const AppPageAppBar(title: 'حجز سريع أو ثابت'),
    body: Padding(
      padding: const EdgeInsets.all(20),
      child: ListView(
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
            decoration: const InputDecoration(labelText: 'رقم الهاتف'),
          ),
          const SizedBox(height: 12),
          const Text('موعد تجريبي: الاثنين ٧ سبتمبر، ٥:٠٠ م'),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () async {
              final draft = BookingDraft(
                slot: TimeSlot(
                  id: 'admin-1700',
                  startTime: DateTime(2026, 9, 7, 17),
                  endTime: DateTime(2026, 9, 7, 18),
                  status: SlotStatus.available,
                ),
                basePrice: 800,
              );
              final booking = _recurring
                  ? await widget.repository.createRecurringBooking(
                      playerName: _name.text.isEmpty
                          ? 'مجموعة ثابتة'
                          : _name.text,
                      phoneNumber: _phone.text,
                      draft: draft,
                    )
                  : await widget.repository.createTentativeBooking(
                      playerName: _name.text.isEmpty
                          ? 'حجز استقبال'
                          : _name.text,
                      phoneNumber: _phone.text,
                      draft: draft,
                    );
              setState(
                () => _message =
                    'تم تسجيل ${_recurring ? 'الحجز الثابت' : 'الحجز المبدئي'} في ملعب ${booking.fieldNumber}.',
              );
            },
            child: Text(
              _recurring ? 'تثبيت الحجز الأسبوعي' : 'تسجيل حجز مبدئي',
            ),
          ),
          if (_message.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(_message),
            ),
        ],
      ),
    ),
  );
}

class StaffPermissionsScreen extends StatefulWidget {
  const StaffPermissionsScreen({super.key, required this.repository});
  final StaffRepository repository;
  @override
  State<StaffPermissionsScreen> createState() => _StaffPermissionsScreenState();
}

class _StaffPermissionsScreenState extends State<StaffPermissionsScreen> {
  late Future<List<StaffMember>> _staff;
  @override
  void initState() {
    super.initState();
    _staff = widget.repository.getStaff();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: const AppPageAppBar(title: 'صلاحيات الموظفين'),
    body: FutureBuilder<List<StaffMember>>(
      future: _staff,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        return ListView(
          children: snapshot.data!
              .map(
                (StaffMember member) => ExpansionTile(
                  title: Text(member.name),
                  children: [
                    _permission(
                      member,
                      'إضافة حجز',
                      member.canCreateBookings,
                      (value) => member.copyWith(canCreateBookings: value),
                    ),
                    _permission(
                      member,
                      'تعديل أو إلغاء',
                      member.canEditBookings,
                      (value) => member.copyWith(canEditBookings: value),
                    ),
                    _permission(
                      member,
                      'التقارير المالية',
                      member.canViewFinancialReports,
                      (value) =>
                          member.copyWith(canViewFinancialReports: value),
                    ),
                  ],
                ),
              )
              .toList(),
        );
      },
    ),
  );
  Widget _permission(
    StaffMember member,
    String label,
    bool value,
    StaffMember Function(bool) update,
  ) => SwitchListTile(
    title: Text(label),
    value: value,
    onChanged: (bool enabled) async {
      await widget.repository.updateStaff(update(enabled));
      setState(() => _staff = widget.repository.getStaff());
    },
  );
}

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key, required this.repository});
  final NotificationRepository repository;
  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  late Future<List<NotificationSetting>> _settings;
  @override
  void initState() {
    super.initState();
    _settings = widget.repository.getSettings();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: const AppPageAppBar(title: 'إعدادات التنبيهات'),
    body: FutureBuilder<List<NotificationSetting>>(
      future: _settings,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        return ListView(
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'الإعدادات دي تجريبية ولن تبعت رسائل أو إشعارات فعلية.',
              ),
            ),
            ...snapshot.data!.map(
              (NotificationSetting setting) => SwitchListTile(
                title: Text(setting.title),
                subtitle: Text(setting.description),
                value: setting.enabled,
                onChanged: (bool enabled) async {
                  await widget.repository.updateSetting(
                    setting.copyWith(enabled: enabled),
                  );
                  setState(() => _settings = widget.repository.getSettings());
                },
              ),
            ),
          ],
        );
      },
    ),
  );
}
