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
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 28),
              Center(
                child: _PitchLogo(color: Theme.of(context).colorScheme.primary),
              ),
              const SizedBox(height: 24),
              Text(
                'احجز ملعبك',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.displaySmall,
              ),
              const SizedBox(height: 12),
              Text(
                'اختار نوع دخولك وابدأ في ثواني.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 32),
              _RoleCard(
                selected: _selectedRole == UserRole.player,
                icon: Icons.sports_soccer_outlined,
                title: 'لاعب',
                subtitle: 'شوف المواعيد واحجز ماتشك.',
                onTap: () => setState(() => _selectedRole = UserRole.player),
              ),
              const SizedBox(height: 12),
              _RoleCard(
                selected: _selectedRole == UserRole.admin,
                icon: Icons.admin_panel_settings_outlined,
                title: 'أدمن',
                subtitle: 'تابع الحجوزات والملاعب.',
                onTap: () => setState(() => _selectedRole = UserRole.admin),
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
                      ? 'ابدأ الحجز كلاعب'
                      : 'افتح لوحة الأدمن',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PitchLogo extends StatelessWidget {
  const _PitchLogo({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: 108,
    height: 108,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(32),
    ),
    child: Stack(
      alignment: Alignment.center,
      children: [
        Icon(
          Icons.crop_square,
          color: Colors.white.withValues(alpha: 0.65),
          size: 68,
        ),
        const Icon(Icons.sports_soccer, color: Colors.white, size: 42),
      ],
    ),
  );
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.selected,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final bool selected;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Semantics(
      label: 'اختيار دور $title',
      button: true,
      selected: selected,
      child: Material(
        color: selected ? colors.primaryContainer : Colors.white,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected ? colors.primary : colors.outlineVariant,
                width: selected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: colors.primary, size: 30),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 2),
                      Text(subtitle),
                    ],
                  ),
                ),
                Icon(
                  selected ? Icons.check_circle : Icons.circle_outlined,
                  color: selected ? colors.primary : colors.outline,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
