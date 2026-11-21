import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../state/app_controller.dart';
import '../widgets/common_widgets.dart';

// ----------------------------------------------------------------------------
//  Login screen
// ----------------------------------------------------------------------------
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.controller});
  final AppController controller;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _userCtrl = TextEditingController(
    text: widget.controller.username,
  );
  final TextEditingController _passCtrl = TextEditingController(
    text: 'admin1234',
  );

  @override
  void dispose() {
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      widget.controller.login(_userCtrl.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ScreenBackground(
        child: AuthCard(
          barColors: const [C.blue, C.cyan],
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const IconBadge(
                    icon: Icons.shield_outlined,
                    color: C.blueLight,
                    size: 48,
                    iconSize: 26,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Flutter Admin Portal',
                          style: ts(20, C.text, w: FontWeight.w700),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Workshop 02 · Navigator & Provider Auth Tunnel',
                          style: ts(11, C.textMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'ADMIN IDENTIFIER',
                      style: ts(11, C.textMuted, w: FontWeight.w600, ls: 1.2),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _userCtrl,
                      keyboardType: TextInputType.emailAddress,
                      style: ts(14, C.text),
                      decoration: fieldDecoration(
                        'admin@flutter-ops.io',
                        Icons.person_outline,
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Identifier is required'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'MASTER PASSWORD',
                      style: ts(11, C.textMuted, w: FontWeight.w600, ls: 1.2),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _passCtrl,
                      obscureText: true,
                      style: ts(14, C.text),
                      decoration: fieldDecoration(
                        'Password',
                        Icons.lock_outline,
                      ),
                      validator: (v) => (v == null || v.isEmpty)
                          ? 'Password is required'
                          : null,
                      onFieldSubmitted: (_) => _submit(),
                    ),
                    const SizedBox(height: 20),
                    GradientButton(
                      label: 'Proceed to 2FA Challenge',
                      trailingIcon: Icons.arrow_forward,
                      onPressed: _submit,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Secure Enclave Authentication Active · ChangeNotifier State Stream',
                textAlign: TextAlign.center,
                style: ts(11, C.textFaint),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
