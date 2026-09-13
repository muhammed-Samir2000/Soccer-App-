import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/router.dart';
import '../../../core/utils/arabic_date.dart';
import '../../../shared/widgets/app_page_app_bar.dart';
import '../domain/booking.dart';
import '../domain/booking_match.dart';
import '../domain/match_participant.dart';
import '../domain/match_repository.dart';

class MatchHubScreen extends StatefulWidget {
  const MatchHubScreen({
    super.key,
    required this.booking,
    required this.repository,
  });

  final Booking booking;
  final MatchRepository repository;

  @override
  State<MatchHubScreen> createState() => _MatchHubScreenState();
}

class _MatchHubScreenState extends State<MatchHubScreen> {
  late Future<BookingMatch> _match;

  @override
  void initState() {
    super.initState();
    _match = widget.repository.getOrCreateForBooking(widget.booking);
  }

  Future<void> _copyInviteLink(BookingMatch match) async {
    final String link = _inviteLink(match.inviteToken);
    await Clipboard.setData(ClipboardData(text: link));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اتنسخ رابط الدعوة. ابعته لفريقك.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: const AppPageAppBar(title: 'فريق الماتش'),
    body: FutureBuilder<BookingMatch>(
      future: _match,
      builder: (BuildContext context, AsyncSnapshot<BookingMatch> snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final BookingMatch match = snapshot.data!;
        final double progress = match.goingCount / match.capacity;
        return ListView(
          padding: const EdgeInsets.all(20),
          children: <Widget>[
            Text(
              'لمّة الفريق',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              '${arabicDateLabel(widget.booking.slot.startTime)} | ملعب ${widget.booking.fieldNumber}',
            ),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        const Icon(Icons.groups_rounded),
                        const SizedBox(width: 10),
                        Text(
                          '${match.goingCount} من ${match.capacity} جايين',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    LinearProgressIndicator(value: progress.clamp(0, 1)),
                    const SizedBox(height: 10),
                    Text(
                      match.isFull
                          ? 'الفريق اكتمل. أي حد جديد هيدخل قائمة انتظار لاحقاً.'
                          : 'فاضل ${match.remainingSpots} أماكن. الحجز بتاعك مؤكد حتى لو العدد ما اكتملش.',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              key: const Key('copy_match_invite_button'),
              onPressed: () => _copyInviteLink(match),
              icon: const Icon(Icons.link_rounded),
              label: const Text('انسخ رابط الدعوة'),
            ),
            const SizedBox(height: 8),
            Text(
              'اللينك بيطلب من صاحبك يدخل بحسابه قبل ما يختار جاي أو مش جاي. أرقام الموبايل مش بتظهر للفريق.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 24),
            Text('ردود الفريق', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...match.participants.map(
              (MatchParticipant participant) => ListTile(
                leading: CircleAvatar(
                  child: Icon(_statusIcon(participant.status)),
                ),
                title: Text(participant.displayName),
                subtitle: Text(
                  participant.isOrganizer
                      ? 'منظّم الماتش'
                      : _statusLabel(participant.status),
                ),
                trailing: Text(_statusLabel(participant.status)),
              ),
            ),
          ],
        );
      },
    ),
  );
}

String matchInviteLink(String inviteToken) => _inviteLink(inviteToken);

String _inviteLink(String inviteToken) {
  final Uri base = Uri.base;
  return '${base.scheme}://${base.authority}/#${AppRouter.matchInviteRoute}?token=${Uri.encodeQueryComponent(inviteToken)}';
}

IconData _statusIcon(MatchParticipationStatus status) => switch (status) {
  MatchParticipationStatus.invited => Icons.schedule_outlined,
  MatchParticipationStatus.going => Icons.check_circle_outline,
  MatchParticipationStatus.notGoing => Icons.cancel_outlined,
};

String _statusLabel(MatchParticipationStatus status) => switch (status) {
  MatchParticipationStatus.invited => 'لسه ما ردش',
  MatchParticipationStatus.going => 'جاي',
  MatchParticipationStatus.notGoing => 'مش جاي',
};
