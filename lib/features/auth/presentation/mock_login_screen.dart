import 'package:flutter/material.dart';

import '../../../app/router.dart';
import '../domain/app_user.dart';
import '../domain/auth_repository.dart';

class MockLoginScreen extends StatefulWidget {
  const MockLoginScreen({super.key, required this.repository});

  final AuthRepository repository;

  @override
  State<MockLoginScreen> createState() => _MockLoginScreenState();
}

class _MockLoginScreenState extends State<MockLoginScreen> {
  UserRole _selectedRole = UserRole.player;
  String? _errorMessage;

  Future<void> _continue() async {
    setState(() => _errorMessage = null);
    try {
      final AppUser user = await widget.repository.signInAs(_selectedRole);
      if (!mounted) {
        return;
      }

      if (user.role == UserRole.player) {
        Navigator.of(context).pushNamed(AppRouter.slotsRoute, arguments: user);
        return;
      }

      Navigator.of(context).pushNamed(AppRouter.adminBookingsRoute);
    } catch (_) {
      if (mounted) {
        setState(() => _errorMessage = 'مش قادرين ندخّلك دلوقتي. جرّب تاني.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(
                  Icons.sports_soccer,
                  color: Theme.of(context).colorScheme.onPrimary,
                  size: 40,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'احجز ملعبك',
                style: Theme.of(context).textTheme.displaySmall,
              ),
              const SizedBox(height: 12),
              Text(
                'اختار هتدخل لاعب ولا أدمن، وابدأ تحجز معانا.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 32),
              SegmentedButton<UserRole>(
                segments: const [
                  ButtonSegment<UserRole>(
                    value: UserRole.player,
                    icon: Icon(Icons.sports_soccer_outlined),
                    label: Text('لاعب'),
                  ),
                  ButtonSegment<UserRole>(
                    value: UserRole.admin,
                    icon: Icon(Icons.manage_accounts_outlined),
                    label: Text('أدمن'),
                  ),
                ],
                selected: {_selectedRole},
                onSelectionChanged: (Set<UserRole> selection) {
                  setState(() => _selectedRole = selection.single);
                },
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const Spacer(),
              FilledButton(
                key: const Key('continue_button'),
                onPressed: _continue,
                child: Text(
                  _selectedRole == UserRole.player
                      ? 'شوف المواعيد الفاضية'
                      : 'ادخل معاينة الأدمن',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
