import 'package:flutter/material.dart';

import '../../../core/utils/arabic_date.dart';
import '../../../core/utils/booking_input_validators.dart';
import '../../../shared/widgets/app_page_app_bar.dart';
import '../domain/booking.dart';
import '../domain/booking_repository.dart';
import '../domain/match_result.dart';
import 'player_bottom_navigation.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({
    super.key,
    required this.playerId,
    required this.repository,
  });

  final String playerId;
  final BookingRepository repository;

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  late Future<List<Booking>> _bookings;

  @override
  void initState() {
    super.initState();
    _bookings = widget.repository.getBookingsForPlayer(widget.playerId);
  }

  void _reload() => setState(
    () => _bookings = widget.repository.getBookingsForPlayer(widget.playerId),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: const AppPageAppBar(title: 'حجوزاتي'),
    body: FutureBuilder<List<Booking>>(
      future: _bookings,
      builder: (BuildContext context, AsyncSnapshot<List<Booking>> snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: FilledButton.tonal(
              onPressed: _reload,
              child: const Text('حاول تاني'),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final DateTime completedThreshold = DateTime.now().subtract(
          const Duration(hours: 1),
        );
        final List<Booking> upcoming = snapshot.data!
            .where(
              (Booking booking) =>
                  booking.slot.endTime.isAfter(completedThreshold),
            )
            .toList();
        final List<Booking> past = snapshot.data!
            .where(
              (Booking booking) =>
                  !booking.slot.endTime.isAfter(completedThreshold),
            )
            .toList();
        return DefaultTabController(
          length: 2,
          child: Column(
            children: [
              const TabBar(
                tabs: [
                  Tab(text: 'القادمة'),
                  Tab(text: 'المباريات السابقة'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _BookingsList(
                      bookings: upcoming,
                      isPast: false,
                      repository: widget.repository,
                      onSaved: _reload,
                    ),
                    _BookingsList(
                      bookings: past,
                      isPast: true,
                      repository: widget.repository,
                      onSaved: _reload,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    ),
    bottomNavigationBar: PlayerBottomNavigation(
      selectedIndex: 1,
      playerId: widget.playerId,
    ),
  );
}

class _BookingsList extends StatelessWidget {
  const _BookingsList({
    required this.bookings,
    required this.isPast,
    required this.repository,
    required this.onSaved,
  });
  final List<Booking> bookings;
  final bool isPast;
  final BookingRepository repository;
  final VoidCallback onSaved;

  @override
  Widget build(BuildContext context) {
    if (bookings.isEmpty) {
      return Center(
        child: Text(
          isPast ? 'مفيش مباريات سابقة لسه.' : 'مفيش حجوزات جاية لسه.',
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: bookings.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (BuildContext context, int index) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ملعب ${bookings[index].fieldNumber} | ${bookings[index].reference}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(_bookingTime(bookings[index])),
              if (isPast) ...[
                const Divider(height: 24),
                _ResultEditor(
                  booking: bookings[index],
                  repository: repository,
                  onSaved: onSaved,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultEditor extends StatefulWidget {
  const _ResultEditor({
    required this.booking,
    required this.repository,
    required this.onSaved,
  });
  final Booking booking;
  final BookingRepository repository;
  final VoidCallback onSaved;
  @override
  State<_ResultEditor> createState() => _ResultEditorState();
}

class _ResultEditorState extends State<_ResultEditor> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _team = TextEditingController(
    text: widget.booking.matchResult?.winningTeam,
  );
  late final TextEditingController _player = TextEditingController(
    text: widget.booking.matchResult?.manOfTheMatch,
  );
  late final TextEditingController _playerDescription = TextEditingController(
    text: widget.booking.matchResult?.manOfTheMatchDescription,
  );
  late final TextEditingController _bestGoal = TextEditingController(
    text: widget.booking.matchResult?.bestGoal,
  );
  late final TextEditingController _bestGoalDescription = TextEditingController(
    text: widget.booking.matchResult?.bestGoalDescription,
  );
  bool _saving = false;
  String? _errorMessage;
  @override
  void dispose() {
    _team.dispose();
    _player.dispose();
    _playerDescription.dispose();
    _bestGoal.dispose();
    _bestGoalDescription.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Form(
        key: _formKey,
        child: Column(
          children: [
            const Text('نتيجة المباراة'),
            TextFormField(
              controller: _team,
              maxLength: 80,
              validator: (String? value) =>
                  validateShortText(value ?? '', 'الفريق الفائز'),
              decoration: const InputDecoration(labelText: 'الفريق الفائز'),
            ),
            TextFormField(
              controller: _player,
              maxLength: 80,
              validator: (String? value) =>
                  validateShortText(value ?? '', 'رجل المباراة'),
              decoration: const InputDecoration(labelText: 'رجل المباراة'),
            ),
            TextFormField(
              controller: _playerDescription,
              maxLines: 2,
              maxLength: 250,
              validator: (String? value) =>
                  validateDescription(value ?? '', 'وصف رجل المباراة'),
              decoration: const InputDecoration(labelText: 'وصف رجل المباراة'),
            ),
            TextFormField(
              controller: _bestGoal,
              maxLength: 80,
              validator: (String? value) =>
                  validateShortText(value ?? '', 'أفضل هدف', required: false),
              decoration: const InputDecoration(labelText: 'أفضل هدف'),
            ),
            TextFormField(
              controller: _bestGoalDescription,
              maxLines: 2,
              maxLength: 250,
              validator: (String? value) =>
                  validateDescription(value ?? '', 'وصف أفضل هدف'),
              decoration: const InputDecoration(labelText: 'وصف أفضل هدف'),
            ),
          ],
        ),
      ),
      if (_errorMessage != null)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            _errorMessage!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      const SizedBox(height: 8),
      TextButton(
        onPressed: _saving
            ? null
            : () async {
                if (!(_formKey.currentState?.validate() ?? false)) {
                  return;
                }
                setState(() => _saving = true);
                try {
                  await widget.repository.saveMatchResult(
                    bookingReference: widget.booking.reference,
                    result: MatchResult(
                      winningTeam: _team.text,
                      manOfTheMatch: _player.text,
                      manOfTheMatchDescription: _playerDescription.text,
                      bestGoal: _bestGoal.text,
                      bestGoalDescription: _bestGoalDescription.text,
                    ),
                  );
                  if (!mounted) {
                    return;
                  }
                  setState(() => _saving = false);
                  widget.onSaved();
                } on ArgumentError catch (error) {
                  if (mounted) {
                    setState(() {
                      _saving = false;
                      _errorMessage = error.message.toString();
                    });
                  }
                }
              },
        child: Text(_saving ? 'بيتحفظ...' : 'حفظ بيانات المباراة'),
      ),
    ],
  );
}

String _bookingTime(Booking booking) =>
    '${arabicDateLabel(booking.slot.startTime)} | ${booking.slot.startTime.hour}:00 - ${booking.slot.endTime.hour}:00';
