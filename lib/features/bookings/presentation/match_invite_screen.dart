import 'package:flutter/material.dart';

import '../../../shared/widgets/app_page_app_bar.dart';
import '../../auth/domain/app_session.dart';
import '../../auth/domain/auth_repository.dart';
import '../../auth/domain/app_user.dart';
import '../domain/booking_match.dart';
import '../domain/match_participant.dart';
import '../domain/match_repository.dart';

class MatchInviteScreen extends StatefulWidget {
  const MatchInviteScreen({
    super.key,
    required this.inviteToken,
    required this.matchRepository,
    required this.authRepository,
    required this.session,
  });

  final String inviteToken;
  final MatchRepository matchRepository;
  final AuthRepository authRepository;
  final AppSession session;

  @override
  State<MatchInviteScreen> createState() => _MatchInviteScreenState();
}

class _MatchInviteScreenState extends State<MatchInviteScreen> {
  late Future<BookingMatch?> _match;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _match = widget.matchRepository.getByInviteToken(widget.inviteToken);
  }

  Future<void> _respond(MatchParticipationStatus status) async {
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final AppUser player;
      final AppUser? currentUser = widget.session.currentUser;
      if (currentUser case final AppUser user
          when user.role == UserRole.player) {
        player = user;
      } else {
        player = await widget.authRepository.signInWithGoogle();
        widget.session.signIn(player);
      }
      final BookingMatch updated = await widget.matchRepository.respondToInvite(
        inviteToken: widget.inviteToken,
        playerId: player.id,
        playerName: player.name,
        status: status,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _submitting = false;
        _match = Future<BookingMatch?>.value(updated);
      });
    } on StateError catch (error) {
      if (mounted) {
        setState(() {
          _submitting = false;
          _error = error.message.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: const AppPageAppBar(title: 'دعوة للماتش'),
    body: FutureBuilder<BookingMatch?>(
      future: _match,
      builder: (BuildContext context, AsyncSnapshot<BookingMatch?> snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final BookingMatch? match = snapshot.data;
        if (match == null) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text('رابط الدعوة غير صالح أو انتهت صلاحيته.'),
            ),
          );
        }
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Icon(Icons.sports_soccer_rounded, size: 64),
                  const SizedBox(height: 16),
                  Text(
                    'مطلوب لاعب للماتش',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text('${match.goingCount} من ${match.capacity} أكدوا حضورهم'),
                  const SizedBox(height: 24),
                  const Text(
                    'هتدخل بجوجل الأول عشان ردك يتسجل باسمك. في النسخة التجريبية الدخول مباشر، وبعد الربط هيكون Google OAuth حقيقي.',
                    textAlign: TextAlign.center,
                  ),
                  if (_error != null) ...<Widget>[
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    key: const Key('match_invite_going_button'),
                    onPressed: _submitting || match.isFull
                        ? null
                        : () => _respond(MatchParticipationStatus.going),
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('أنا جاي'),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    key: const Key('match_invite_not_going_button'),
                    onPressed: _submitting
                        ? null
                        : () => _respond(MatchParticipationStatus.notGoing),
                    icon: const Icon(Icons.cancel_outlined),
                    label: const Text('مش جاي'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}
