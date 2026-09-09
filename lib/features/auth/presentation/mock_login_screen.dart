import 'package:flutter/material.dart';

import '../../../app/router.dart';
import '../domain/app_session.dart';
import '../domain/app_user.dart';
import '../domain/auth_repository.dart';

enum LoginAudience { player, admin }

enum _PlayerAuthMode { signIn, createAccount }

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
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  _PlayerAuthMode _playerAuthMode = _PlayerAuthMode.signIn;
  bool _obscurePassword = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  bool get _isAdminLogin => widget.audience == LoginAudience.admin;
  UserRole get _intendedRole =>
      _isAdminLogin ? UserRole.admin : UserRole.player;

  Future<void> _submitCredentials() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    await _completeSignIn(
      widget.repository.signInWithEmailPassword(
        email: _email.text.trim(),
        password: _password.text,
      ),
    );
  }

  Future<void> _continueWithGoogle() =>
      _completeSignIn(widget.repository.signInWithGoogle());

  Future<void> _completeSignIn(Future<AppUser> signIn) async {
    setState(() {
      _errorMessage = null;
      _isSubmitting = true;
    });

    try {
      final AppUser user = await signIn;
      if (!mounted) {
        return;
      }
      if (user.role != _intendedRole) {
        setState(() => _errorMessage = 'الحساب ده مش مصرح له بالدخول هنا.');
        return;
      }

      widget.session.signIn(user);
      final String route = user.role == UserRole.admin
          ? AppRouter.adminBookingsRoute
          : AppRouter.slotsRoute;
      Navigator.of(context).pushReplacementNamed(
        route,
        arguments: user.role == UserRole.player ? user : null,
      );
    } catch (_) {
      if (mounted) {
        setState(() => _errorMessage = 'بيانات الدخول غير صحيحة. جرّب تاني.');
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _requestPasswordReset() async {
    final String email = _email.text.trim();
    if (!_isValidEmail(email)) {
      setState(() => _errorMessage = 'اكتب بريدك الإلكتروني الأول.');
      return;
    }

    await widget.repository.requestPasswordReset(email: email);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لو البريد مسجل، هتوصلك رسالة استرجاع كلمة المرور.'),
        ),
      );
    }
  }

  void _togglePlayerMode() {
    setState(() {
      _playerAuthMode = _playerAuthMode == _PlayerAuthMode.signIn
          ? _PlayerAuthMode.createAccount
          : _PlayerAuthMode.signIn;
      _errorMessage = null;
    });
  }

  bool _isValidEmail(String value) =>
      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value);

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final bool isRegistration =
        _playerAuthMode == _PlayerAuthMode.createAccount && !_isAdminLogin;
    final String title = _isAdminLogin
        ? 'دخول فريق الإدارة'
        : isRegistration
        ? 'اعمل حسابك'
        : 'احجز ملعبك بسهولة';
    final String subtitle = _isAdminLogin
        ? 'الحسابات دي بتتفعّل بدعوة من مالك الملعب.'
        : isRegistration
        ? 'اعمل حساب مرة واحدة علشان تتابع حجوزاتك بسهولة.'
        : 'ادخل بسرعة وشوف المواعيد الفاضية واحجز ماتشك.';

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
                  Center(
                    child: _PitchLogo(
                      color: _isAdminLogin ? colors.secondary : colors.primary,
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
                  if (_isAdminLogin) ...[
                    const SizedBox(height: 20),
                    _AdminInvitationNotice(colors: colors),
                  ],
                  const SizedBox(height: 28),
                  OutlinedButton.icon(
                    key: const Key('google_sign_in_button'),
                    onPressed: _isSubmitting ? null : _continueWithGoogle,
                    icon: const _GoogleMark(),
                    label: const Text('المتابعة بحساب Google'),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'أو',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          key: const Key('email_field'),
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.email],
                          decoration: const InputDecoration(
                            labelText: 'البريد الإلكتروني',
                            hintText: 'name@example.com',
                            prefixIcon: Icon(Icons.alternate_email_outlined),
                          ),
                          validator: (String? value) =>
                              _isValidEmail((value ?? '').trim())
                              ? null
                              : 'اكتب بريد إلكتروني صحيح.',
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          key: const Key('password_field'),
                          controller: _password,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.done,
                          autofillHints: const [AutofillHints.password],
                          decoration: InputDecoration(
                            labelText: 'كلمة المرور',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              tooltip: _obscurePassword
                                  ? 'إظهار كلمة المرور'
                                  : 'إخفاء كلمة المرور',
                              onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                            ),
                          ),
                          validator: (String? value) =>
                              (value ?? '').length >= 8
                              ? null
                              : 'كلمة المرور لازم تكون 8 حروف أو أكتر.',
                        ),
                        if (!isRegistration) ...[
                          Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: TextButton(
                              onPressed: _isSubmitting
                                  ? null
                                  : _requestPasswordReset,
                              child: const Text('نسيت كلمة المرور؟'),
                            ),
                          ),
                        ],
                        if (_errorMessage != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            _errorMessage!,
                            style: TextStyle(color: colors.error),
                          ),
                        ],
                        const SizedBox(height: 16),
                        FilledButton(
                          key: const Key('credential_continue_button'),
                          onPressed: _isSubmitting ? null : _submitCredentials,
                          child: Text(
                            _isSubmitting
                                ? 'ثانية واحدة...'
                                : _isAdminLogin
                                ? 'دخول لوحة الإدارة'
                                : isRegistration
                                ? 'إنشاء الحساب والمتابعة'
                                : 'تسجيل الدخول',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_isAdminLogin)
                    Text(
                      'لا تملك دعوة؟ تواصل مع مالك الملعب لتفعيل حسابك.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    )
                  else
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          isRegistration ? 'عندك حساب بالفعل؟' : 'معندكش حساب؟',
                        ),
                        TextButton(
                          onPressed: _togglePlayerMode,
                          child: Text(
                            isRegistration ? 'تسجيل الدخول' : 'إنشاء حساب جديد',
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 12),
                  Text(
                    'نسخة تجريبية: بيانات الدخول لا تُحفظ ولا تُرسل حالياً.',
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
  const _PitchLogo({required this.color, required this.icon});

  final Color color;
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
    child: Icon(icon, color: Colors.white, size: 48),
  );
}

class _GoogleMark extends StatelessWidget {
  const _GoogleMark();

  @override
  Widget build(BuildContext context) => Container(
    width: 24,
    height: 24,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      shape: BoxShape.circle,
    ),
    child: const Text(
      'G',
      textDirection: TextDirection.ltr,
      style: TextStyle(fontWeight: FontWeight.w800),
    ),
  );
}

class _AdminInvitationNotice extends StatelessWidget {
  const _AdminInvitationNotice({required this.colors});

  final ColorScheme colors;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: colors.secondaryContainer,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      children: [
        Icon(Icons.verified_user_outlined, color: colors.onSecondaryContainer),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'لن تستطيع إنشاء صلاحية إدارية من هنا.',
            style: TextStyle(color: colors.onSecondaryContainer),
          ),
        ),
      ],
    ),
  );
}
