import 'package:flutter/material.dart';

import '../../../core/utils/arabic_date.dart';
import '../../../core/utils/booking_input_validators.dart';
import '../../../shared/widgets/app_page_app_bar.dart';

import '../../bookings/domain/booking.dart';
import '../../bookings/domain/booking_draft.dart';
import '../../bookings/domain/booking_repository.dart';
import '../../slots/domain/time_slot.dart';
import '../../slots/data/mock_slot_repository.dart';
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
    this.canManageTeam = false,
  });
  final BookingRepository bookingRepository;
  final StaffRepository staffRepository;
  final NotificationRepository notificationRepository;
  final bool canManageTeam;
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
              'جدول ملاعب يوم ${arabicDateLabel(MockSlotRepository.bookingStart)}',
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
                if (widget.canManageTeam)
                  _NavButton(
                    label: 'فريق الإدارة',
                    icon: Icons.manage_accounts_outlined,
                    page: StaffPermissionsScreen(
                      repository: widget.staffRepository,
                      canManageTeam: true,
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
            maxLength: 80,
            decoration: const InputDecoration(
              labelText: 'اسم اللاعب أو المجموعة',
            ),
          ),
          TextField(
            controller: _phone,
            maxLength: 11,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: 'رقم الهاتف'),
          ),
          const SizedBox(height: 12),
          Text(
            'موعد تجريبي: ${arabicDateLabel(MockSlotRepository.bookingStart)}، ٥:٠٠ م',
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () async {
              final String? nameError = validatePlayerName(_name.text);
              final String? phoneError = validateEgyptianMobile(_phone.text);
              if (nameError != null || phoneError != null) {
                setState(() => _message = nameError ?? phoneError!);
                return;
              }
              final DateTime day = MockSlotRepository.bookingStart;
              final draft = BookingDraft(
                slot: TimeSlot(
                  id: 'admin-1700',
                  startTime: DateTime(day.year, day.month, day.day, 17),
                  endTime: DateTime(day.year, day.month, day.day, 18),
                  status: SlotStatus.available,
                ),
                basePrice: 800,
              );
              try {
                final booking = _recurring
                    ? await widget.repository.createRecurringBooking(
                        playerName: _name.text,
                        phoneNumber: _phone.text,
                        draft: draft,
                      )
                    : await widget.repository.createTentativeBooking(
                        playerName: _name.text,
                        phoneNumber: _phone.text,
                        draft: draft,
                      );
                setState(
                  () => _message =
                      'تم تسجيل ${_recurring ? 'الحجز الثابت' : 'الحجز المبدئي'} في ملعب ${booking.fieldNumber}.',
                );
              } on ArgumentError catch (error) {
                setState(() => _message = error.message.toString());
              } on StateError catch (error) {
                setState(() => _message = error.message.toString());
              }
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
  const StaffPermissionsScreen({
    super.key,
    required this.repository,
    this.canManageTeam = false,
  });
  final StaffRepository repository;
  final bool canManageTeam;
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

  void _reload() {
    setState(() {
      _staff = widget.repository.getStaff();
    });
  }

  Future<void> _openInviteSheet() async {
    if (!widget.canManageTeam) {
      return;
    }
    final StaffMember? invitation = await showModalBottomSheet<StaffMember>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) => const _StaffInviteSheet(),
    );
    if (invitation == null || !mounted) {
      return;
    }
    try {
      await widget.repository.inviteStaff(invitation);
      _reload();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('اتسجلت دعوة ${invitation.email} بصلاحياتها.'),
          ),
        );
      }
    } on ArgumentError catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message.toString())));
      }
    }
  }

  Future<void> _revokeStaff(StaffMember member) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('إلغاء صلاحيات العضو؟'),
        content: Text('هيتوقف وصول ${member.name} للإدارة.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('رجوع'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('إلغاء الصلاحيات'),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }
    await widget.repository.revokeStaff(member.id);
    _reload();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppPageAppBar(
      title: 'فريق الإدارة',
      actions: [
        if (widget.canManageTeam)
          IconButton(
            key: const Key('staff_invite_action'),
            tooltip: 'دعوة عضو',
            onPressed: _openInviteSheet,
            icon: const Icon(Icons.person_add_alt_1_outlined),
          ),
      ],
    ),
    floatingActionButton: widget.canManageTeam
        ? FloatingActionButton.extended(
            onPressed: _openInviteSheet,
            icon: const Icon(Icons.person_add_alt_1_outlined),
            label: const Text('دعوة عضو'),
          )
        : null,
    body: !widget.canManageTeam
        ? const _TeamAccessDenied()
        : FutureBuilder<List<StaffMember>>(
            future: _staff,
            builder:
                (
                  BuildContext context,
                  AsyncSnapshot<List<StaffMember>> snapshot,
                ) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                    children: [
                      const _InvitationGuidanceCard(),
                      const SizedBox(height: 20),
                      Text(
                        'الأعضاء والصلاحيات',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      ...snapshot.data!.map(
                        (StaffMember member) => _StaffPermissionCard(
                          member: member,
                          onPermissionChanged: (StaffMember updated) async {
                            await widget.repository.updateStaff(updated);
                            _reload();
                          },
                          onRevoked: () => _revokeStaff(member),
                        ),
                      ),
                    ],
                  );
                },
          ),
  );
}

class _InvitationGuidanceCard extends StatelessWidget {
  const _InvitationGuidanceCard();

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Card(
      color: colors.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.admin_panel_settings_outlined,
              color: colors.onPrimaryContainer,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ادعُ فريقك عبر Google',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: colors.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'سجّل بريد وموبايل العضو وحدد صلاحياته. الدخول متاح فقط بحساب Google المدعو، ومش ممكن تعيين Super Admin من هنا.',
                    style: TextStyle(color: colors.onPrimaryContainer),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TeamAccessDenied extends StatelessWidget {
  const _TeamAccessDenied();

  @override
  Widget build(BuildContext context) => const Center(
    child: Padding(
      padding: EdgeInsets.all(24),
      child: Text(
        'إدارة أعضاء الفريق وصلاحياتهم متاحة لحساب السوبر أدمن فقط.',
        textAlign: TextAlign.center,
      ),
    ),
  );
}

class _StaffPermissionCard extends StatelessWidget {
  const _StaffPermissionCard({
    required this.member,
    required this.onPermissionChanged,
    required this.onRevoked,
  });

  final StaffMember member;
  final ValueChanged<StaffMember> onPermissionChanged;
  final VoidCallback onRevoked;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final bool pending =
        member.invitationStatus == StaffInvitationStatus.pending;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: pending
              ? colors.secondaryContainer
              : colors.primaryContainer,
          foregroundColor: pending
              ? colors.onSecondaryContainer
              : colors.onPrimaryContainer,
          child: Icon(
            pending ? Icons.schedule_outlined : Icons.verified_user_outlined,
          ),
        ),
        title: Text(member.name),
        subtitle: Text(
          '${member.email}\n${member.phoneNumber}\n${member.role.label}',
        ),
        trailing: _InvitationStatusChip(status: member.invitationStatus),
        children: [
          const Divider(height: 1),
          _PermissionSwitch(
            member: member,
            label: 'إضافة حجز',
            value: member.canCreateBookings,
            update: (bool value) => member.copyWith(canCreateBookings: value),
            onChanged: onPermissionChanged,
          ),
          _PermissionSwitch(
            member: member,
            label: 'تعديل أو إلغاء الحجز',
            value: member.canEditBookings,
            update: (bool value) => member.copyWith(canEditBookings: value),
            onChanged: onPermissionChanged,
          ),
          _PermissionSwitch(
            member: member,
            label: 'عرض التحليل المالي',
            value: member.canViewFinancialReports,
            update: (bool value) =>
                member.copyWith(canViewFinancialReports: value),
            onChanged: onPermissionChanged,
          ),
          if (member.invitationStatus != StaffInvitationStatus.revoked)
            Padding(
              padding: const EdgeInsets.all(12),
              child: OutlinedButton.icon(
                key: Key('staff_revoke_${member.id}'),
                onPressed: onRevoked,
                icon: const Icon(Icons.person_off_outlined),
                label: const Text('إلغاء الصلاحيات'),
              ),
            ),
        ],
      ),
    );
  }
}

class _InvitationStatusChip extends StatelessWidget {
  const _InvitationStatusChip({required this.status});

  final StaffInvitationStatus status;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final (Color background, Color foreground, IconData icon) appearance =
        switch (status) {
          StaffInvitationStatus.pending => (
            colors.secondaryContainer,
            colors.onSecondaryContainer,
            Icons.schedule_outlined,
          ),
          StaffInvitationStatus.active => (
            colors.primaryContainer,
            colors.onPrimaryContainer,
            Icons.check_circle_outline,
          ),
          StaffInvitationStatus.revoked => (
            colors.errorContainer,
            colors.onErrorContainer,
            Icons.person_off_outlined,
          ),
        };
    return Chip(
      avatar: Icon(appearance.$3, size: 18),
      label: Text(status.label),
      backgroundColor: appearance.$1,
      side: BorderSide.none,
      labelStyle: TextStyle(color: appearance.$2),
    );
  }
}

class _PermissionSwitch extends StatelessWidget {
  const _PermissionSwitch({
    required this.member,
    required this.label,
    required this.value,
    required this.update,
    required this.onChanged,
  });

  final StaffMember member;
  final String label;
  final bool value;
  final StaffMember Function(bool) update;
  final ValueChanged<StaffMember> onChanged;

  @override
  Widget build(BuildContext context) => SwitchListTile(
    title: Text(label),
    value: value,
    onChanged: member.invitationStatus == StaffInvitationStatus.revoked
        ? null
        : (bool enabled) => onChanged(update(enabled)),
  );
}

class _StaffInviteSheet extends StatefulWidget {
  const _StaffInviteSheet();

  @override
  State<_StaffInviteSheet> createState() => _StaffInviteSheetState();
}

class _StaffInviteSheetState extends State<_StaffInviteSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _name = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _phone = TextEditingController();
  StaffRole _role = StaffRole.reception;
  bool _canCreateBookings = true;
  bool _canEditBookings = true;
  bool _canViewFinancialReports = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    super.dispose();
  }

  void _setRole(StaffRole role) {
    setState(() {
      _role = role;
      if (role == StaffRole.manager) {
        _canCreateBookings = true;
        _canEditBookings = true;
        _canViewFinancialReports = true;
      }
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final String email = _email.text.trim().toLowerCase();
    final String name = _name.text.trim();
    Navigator.of(context).pop(
      StaffMember(
        id: '',
        name: name.isEmpty ? email.split('@').first : name,
        email: email,
        phoneNumber: _phone.text.trim(),
        role: _role,
        invitationStatus: StaffInvitationStatus.pending,
        canCreateBookings: _canCreateBookings,
        canEditBookings: _canEditBookings,
        canViewFinancialReports: _canViewFinancialReports,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final EdgeInsets viewInsets = MediaQuery.viewInsetsOf(context);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 12, 20, viewInsets.bottom + 24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'دعوة عضو لفريق الإدارة',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 6),
                const Text(
                  'حدد البريد والصلاحيات قبل ما يدخل العضو بحسابه على Google.',
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _email,
                  key: const Key('staff_invite_email'),
                  autocorrect: false,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'البريد الإلكتروني',
                    hintText: 'name@gmail.com',
                    prefixIcon: Icon(Icons.alternate_email_outlined),
                  ),
                  validator: validateEmailAddress,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _name,
                  key: const Key('staff_invite_name'),
                  maxLength: 80,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    labelText: 'اسم للعرض (اختياري)',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (String? value) =>
                      validateShortText(value ?? '', 'الاسم', required: false),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _phone,
                  key: const Key('staff_invite_phone'),
                  maxLength: 11,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'رقم الموبايل',
                    hintText: '01012345678',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                  validator: (String? value) =>
                      validateEgyptianMobile(value ?? ''),
                ),
                const SizedBox(height: 8),
                Text('الدور', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                SegmentedButton<StaffRole>(
                  segments: const [
                    ButtonSegment<StaffRole>(
                      value: StaffRole.reception,
                      icon: Icon(Icons.support_agent_outlined),
                      label: Text('استقبال'),
                    ),
                    ButtonSegment<StaffRole>(
                      value: StaffRole.manager,
                      icon: Icon(Icons.manage_accounts_outlined),
                      label: Text('مدير'),
                    ),
                  ],
                  selected: <StaffRole>{_role},
                  onSelectionChanged: (Set<StaffRole> value) =>
                      _setRole(value.first),
                ),
                const SizedBox(height: 16),
                Text(
                  'الصلاحيات',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('إضافة حجز'),
                  value: _canCreateBookings,
                  onChanged: (bool? value) =>
                      setState(() => _canCreateBookings = value ?? false),
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('تعديل أو إلغاء الحجز'),
                  value: _canEditBookings,
                  onChanged: (bool? value) =>
                      setState(() => _canEditBookings = value ?? false),
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('عرض التحليل المالي'),
                  value: _canViewFinancialReports,
                  onChanged: (bool? value) =>
                      setState(() => _canViewFinancialReports = value ?? false),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  key: const Key('staff_invite_submit'),
                  onPressed: _submit,
                  icon: const Icon(Icons.send_outlined),
                  label: const Text('حفظ الدعوة والصلاحيات'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
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
