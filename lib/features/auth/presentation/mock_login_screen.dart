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
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _phone = TextEditingController();
  String? _errorMessage;

  bool get _isAdminLogin => widget.audience == LoginAudience.admin;

  Future<void> _continue() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _errorMessage = null);
    try {
      final AppUser user = await widget.repository.signInAs(
        _isAdminLogin ? UserRole.admin : UserRole.player,
      );
      if (!mounted) {
        return;
      }
      widget.session.signIn(user);

      if (user.role == UserRole.player) {
        Navigator.of(
          context,
        ).pushReplacementNamed(AppRouter.slotsRoute, arguments: user);
        return;
      }

      Navigator.of(context).pushReplacementNamed(AppRouter.adminBookingsRoute);
    } catch (_) {
      if (mounted) {
        setState(() => _errorMessage = 'مش قادرين ندخّلك دلوقتي. جرّب تاني.');
      }
    }
  }

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  const SizedBox(height: 28),
                  Center(
                    child: _PitchLogo(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _isAdminLogin ? 'دخول فريق الإدارة' : 'تسجيل دخول اللاعب',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _isAdminLogin
                        ? 'الدخول ده مخصص لمدير الملعب والفريق المصرح له.'
                        : 'اكتب رقم موبايلك علشان تكمل الحجز.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 28),
                  TextFormField(
                    key: const Key('phone_number_field'),
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.telephoneNumber],
                    decoration: const InputDecoration(
                      labelText: 'رقم الموبايل',
                      hintText: '01xxxxxxxxx',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                    validator: (String? value) {
                      final String digits = (value ?? '').replaceAll(
                        RegExp(r'[^0-9]'),
                        '',
                      );
                      return RegExp(r'^01[0-9]{9}$').hasMatch(digits)
                          ? null
                          : 'اكتب رقم موبايل مصري صحيح.';
                    },
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  FilledButton(
                    key: const Key('continue_button'),
                    onPressed: _continue,
                    child: Text(
                      _isAdminLogin ? 'دخول لوحة الإدارة' : 'دخول ومتابعة',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _isAdminLogin
                        ? 'نسخة تجريبية: صلاحيات الأدمن الحقيقية هتتأكد من السيرفر.'
                        : 'نسخة تجريبية: هتدخل كلاعب بدون اختيار صلاحية إدارية.',
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
