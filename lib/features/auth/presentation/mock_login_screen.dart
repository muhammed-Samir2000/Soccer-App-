import 'package:flutter/material.dart';

import '../../../app/router.dart';
import '../../../shared/widgets/google_sign_in_button.dart';
import '../../../shared/widgets/sports_illustration.dart';
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
    this.initialUser,
  });

  final AuthRepository repository;
  final AppSession session;
  final LoginAudience audience;
  final AppUser? initialUser;

  @override
  State<MockLoginScreen> createState() => _MockLoginScreenState();
}

class _MockLoginScreenState extends State<MockLoginScreen> {
  bool _isSubmitting = false;
  String? _errorMessage;
  late AppUser? _restoredUser;

  bool get _isAdminLogin => widget.audience == LoginAudience.admin;

  @override
  void initState() {
    super.initState();
    _restoredUser = widget.initialUser;
  }

  Future<void> _continueSavedSession() async {
    final AppUser? user = _restoredUser;
    if (user == null) {
      return;
    }
    if (_isAdminLogin && !user.canAccessAdmin) {
      await _signOutSavedSession(
        errorMessage: 'الحساب ده مش مدعو لفريق الإدارة.',
      );
      return;
    }
    if (!mounted) {
      return;
    }
    widget.session.signIn(user);
    Navigator.of(context).pushReplacementNamed(
      user.canAccessAdmin ? AppRouter.adminBookingsRoute : AppRouter.slotsRoute,
      arguments: user.role == UserRole.player ? user : null,
    );
  }

  Future<void> _signOutSavedSession({String? errorMessage}) async {
    setState(() => _isSubmitting = true);
    try {
      await widget.repository.signOut();
      widget.session.signOut();
      if (mounted) {
        setState(() {
          _restoredUser = null;
          _isSubmitting = false;
          _errorMessage = errorMessage;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _errorMessage = 'حصلت مشكلة وإحنا بنسجل خروجك. جرّب تاني.';
        });
      }
    }
  }

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
      user.canAccessAdmin ? AppRouter.adminBookingsRoute : AppRouter.slotsRoute,
      arguments: user.role == UserRole.player ? user : null,
    );
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    try {
      final AppUser? user = await widget.repository.signInWithGoogle();
      if (user == null) {
        if (mounted) {
          setState(() => _isSubmitting = false);
        }
        return;
      }
      if (_isAdminLogin && !user.canAccessAdmin) {
        await widget.repository.signOut();
        if (mounted) {
          setState(() {
            _isSubmitting = false;
            _errorMessage = 'الحساب ده مش مدعو لفريق الإدارة.';
          });
        }
        return;
      }
      if (!mounted) return;
      widget.session.signIn(user);
      Navigator.of(context).pushReplacementNamed(
        user.canAccessAdmin
            ? AppRouter.adminBookingsRoute
            : AppRouter.slotsRoute,
        arguments: user.role == UserRole.player ? user : null,
      );
    } catch (_) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _errorMessage = 'حصلت مشكلة في تسجيل Google. جرّب تاني.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final bool compactHeight = MediaQuery.sizeOf(context).height < 700;
    final String title = _isAdminLogin
        ? 'دخول فريق الإدارة'
        : 'احجز ملعبك بسهولة';
    final String subtitle = widget.repository.usesLiveAuthentication
        ? _isAdminLogin
              ? 'ادخل بحساب Google المدعو لفريق إدارة الملعب.'
              : 'ادخل بحساب Google عشان تحفظ حجوزاتك وفريق ماتشك.'
        : _isAdminLogin
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
                  SportsIllustration(
                    height: compactHeight ? 96 : (_isAdminLogin ? 132 : 156),
                    compact: _isAdminLogin,
                    label: _isAdminLogin
                        ? 'رسم توضيحي لإدارة ملعب كرة قدم'
                        : 'رسم توضيحي لحجز ملعب كرة قدم',
                  ),
                  SizedBox(height: compactHeight ? 16 : 24),
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
                  SizedBox(height: compactHeight ? 12 : 18),
                  if (!_isAdminLogin && !compactHeight)
                    const Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _EntryFeature(
                          icon: Icons.calendar_month_outlined,
                          label: 'احجز بسرعة',
                        ),
                        _EntryFeature(
                          icon: Icons.groups_2_outlined,
                          label: 'لمّ فريقك',
                        ),
                        _EntryFeature(
                          icon: Icons.shield_outlined,
                          label: 'دخول آمن',
                        ),
                      ],
                    ),
                  SizedBox(height: compactHeight ? 16 : 26),
                  if (_restoredUser == null) ...[
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
                              widget.repository.usesLiveAuthentication
                                  ? 'تسجيل Google بيتم في صفحة Google المؤمّنة، والحجوزات والأسعار بتتحفظ في قاعدة البيانات المشتركة.'
                                  : 'نسخة تجريبية: الدخول ده لا ينشئ حساباً ولا يحفظ أي بيانات.',
                              style: TextStyle(
                                color: colors.onSecondaryContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  if (_restoredUser != null) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colors.surface,
                        border: Border.all(color: colors.outlineVariant),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.account_circle_outlined,
                            color: colors.primary,
                            size: 34,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'أنت مسجل بالفعل باسم ${_restoredUser!.name}',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 12),
                          FilledButton.icon(
                            key: const Key('continue_saved_session_button'),
                            onPressed: _isSubmitting
                                ? null
                                : _continueSavedSession,
                            icon: const Icon(Icons.arrow_forward),
                            label: const Text('كمل للتطبيق'),
                          ),
                          TextButton.icon(
                            key: const Key('sign_out_saved_session_button'),
                            onPressed: _isSubmitting
                                ? null
                                : _signOutSavedSession,
                            icon: const Icon(Icons.logout_outlined),
                            label: const Text(
                              'تسجيل الخروج واستخدام حساب مختلف',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'أو سجل بحساب Google تاني',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (widget.repository.usesLiveAuthentication)
                    GoogleSignInButton(
                      key: const Key('google_sign_in_button'),
                      onPressed: _isSubmitting ? null : _signInWithGoogle,
                      isLoading: _isSubmitting,
                      label: _isAdminLogin
                          ? 'دخول الإدارة بحساب Google'
                          : _restoredUser == null
                          ? 'المتابعة بحساب Google'
                          : 'تسجيل Google بحساب مختلف',
                    )
                  else
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
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: colors.error),
                    ),
                  ],
                  const SizedBox(height: 18),
                  Text(
                    _isAdminLogin
                        ? 'دخول الإدارة متاح للحسابات المدعوة والمصرح لها فقط.'
                        : widget.repository.usesLiveAuthentication
                        ? 'هتتنقل لصفحة Google الرسمية، وإحنا لا بنشوف ولا بنخزن كلمة مرورك.'
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

class _EntryFeature extends StatelessWidget {
  const _EntryFeature({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(10, 7, 12, 7),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: colors.primary),
          const SizedBox(width: 6),
          Text(label, style: Theme.of(context).textTheme.labelMedium),
        ],
      ),
    );
  }
}
