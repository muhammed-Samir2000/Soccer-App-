import 'package:flutter/material.dart';

import '../../../shared/widgets/app_page_app_bar.dart';
import '../../../core/utils/arabic_date.dart';
import '../../../core/utils/booking_input_validators.dart';
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
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  late Future<BookingMatch?> _match;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _match = widget.matchRepository.getByInviteToken(widget.inviteToken);
  }

  Future<void> _respond(MatchParticipationStatus status) async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
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
        final AppUser? signedIn = await widget.authRepository
            .signInWithGoogle();
        if (signedIn == null) {
          throw StateError('كمّل تسجيل Google ثم افتح رابط الدعوة تاني.');
        }
        player = signedIn;
        widget.session.signIn(player);
      }
      final BookingMatch updated = await widget.matchRepository.respondToInvite(
        inviteToken: widget.inviteToken,
        playerId: player.id,
        playerName: _nameController.text.trim(),
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
        if (snapshot.connectionState != ConnectionState.done) {
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
            child: SingleChildScrollView(
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
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text('منظّم الماتش: ${match.organizerName}'),
                          const SizedBox(height: 6),
                          Text(
                            '${arabicDateLabel(match.startsAt)} | ${_time(match.startsAt)} - ${_time(match.endsAt)}',
                          ),
                          const SizedBox(height: 6),
                          Text('ملعب ${match.fieldNumber}'),
                        ],
                      ),
                    ),
                  ),
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
                  const SizedBox(height: 16),
                  Form(
                    key: _formKey,
                    child: TextFormField(
                      controller: _nameController,
                      maxLength: 80,
                      validator: (String? value) =>
                          validatePlayerName(value ?? ''),
                      decoration: const InputDecoration(
                        labelText: 'اكتب اسمك عشان الكابتن يعرف مين جاي',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
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

String _time(DateTime value) {
  final int hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
  return '$hour:00 ${value.hour >= 12 ? 'م' : 'ص'}';
}
