import 'package:flutter/material.dart';

import '../../../app/router.dart';
import '../domain/app_session.dart';
import '../domain/app_user.dart';
import '../domain/auth_repository.dart';

enum LoginAudience { player, admin }

class MockLoginScreen extends StatefulWidget {
  const MockLoginScreen({
    super.key,
    required this.repository,
    required this.session,
    this.audience = LoginAudience.player,
  });

  final AuthRepository repository;
  final AppSession session;
  final LoginAudience audience;

  @override
  State<MockLoginScreen> createState() => _MockLoginScreenState();
}

class _MockLoginScreenState extends State<MockLoginScreen> {
  bool _isSubmitting = false;

  bool get _isAdminLogin => widget.audience == LoginAudience.admin;

  Future<void> _enterDemo() async {
    setState(() => _isSubmitting = true);
    final AppUser user = _isAdminLogin
        ? await widget.repository.signInAsDemoAdmin()
        : await widget.repository.signInAsDemoPlayer();
    if (!mounted) {
      return;
    }
    widget.session.signIn(user);
    Navigator.of(context).pushReplacementNamed(
      user.role == UserRole.admin
          ? AppRouter.adminBookingsRoute
          : AppRouter.slotsRoute,
      arguments: user.role == UserRole.player ? user : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final String title = _isAdminLogin
        ? 'دخول فريق الإدارة'
        : 'احجز ملعبك بسهولة';
    final String subtitle = _isAdminLogin
        ? 'جرّب إدارة الملاعب دلوقتي من غير بريد أو كلمة مرور.'
        : 'جرّب الحجز وشوف المواعيد الفاضية من غير تسجيل بيانات.';

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [colors.primaryContainer, colors.surface],
            begin: AlignmentDirectional.topCenter,
            end: AlignmentDirectional.center,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: ListView(
                padding: const EdgeInsetsDirectional.fromSTEB(24, 28, 24, 32),
                children: [
                  if (!_isAdminLogin)
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: TextButton.icon(
                        key: const Key('admin_login_link'),
                        onPressed: () => Navigator.of(
                          context,
                        ).pushNamed(AppRouter.adminLoginRoute),
                        icon: const Icon(Icons.admin_panel_settings_outlined),
                        label: const Text('دخول فريق الإدارة'),
                      ),
                    ),
                  Center(
                    child: _PitchLogo(
                      color: _isAdminLogin ? colors.secondary : colors.primary,
                      foregroundColor: _isAdminLogin
                          ? colors.onSecondary
                          : colors.onPrimary,
                      icon: _isAdminLogin
                          ? Icons.admin_panel_settings_outlined
                          : Icons.sports_soccer,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 28),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colors.secondaryContainer,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.science_outlined,
                          color: colors.onSecondaryContainer,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'نسخة تجريبية: الدخول ده لا ينشئ حساباً ولا يحفظ أي بيانات.',
                            style: TextStyle(
                              color: colors.onSecondaryContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    key: const Key('demo_entry_button'),
                    onPressed: _isSubmitting ? null : _enterDemo,
                    icon: Icon(
                      _isAdminLogin
                          ? Icons.dashboard_outlined
                          : Icons.sports_soccer_outlined,
                    ),
                    label: Text(
                      _isSubmitting
                          ? 'ثانية واحدة...'
                          : _isAdminLogin
                          ? 'ادخل وجرب لوحة الإدارة'
                          : 'ادخل وجرب الحجز',
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    _isAdminLogin
                        ? 'في النسخة الفعلية، دخول الإدارة هيكون بدعوة وصلاحية موثقة.'
                        : 'في النسخة الفعلية، هتختار طريقة دخول آمنة مناسبة ليك.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PitchLogo extends StatelessWidget {
  const _PitchLogo({
    required this.color,
    required this.foregroundColor,
    required this.icon,
  });

  final Color color;
  final Color foregroundColor;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
    width: 104,
    height: 104,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(30),
      boxShadow: [
        BoxShadow(color: color.withValues(alpha: 0.25), blurRadius: 28),
      ],
    ),
    child: Icon(icon, color: foregroundColor, size: 48),
  );
}
