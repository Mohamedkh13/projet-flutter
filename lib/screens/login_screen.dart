import 'package:material_ui/material_ui.dart';

import '../core/theme.dart';
import '../widgets/common_widgets.dart';

// ----------------------------------------------------------------------------
//  Login screen
// ----------------------------------------------------------------------------
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.onGoogleSignIn});
  final Future<void> Function() onGoogleSignIn;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isSigningIn = false;

  Future<void> _signInWithGoogle() async {
    if (_isSigningIn) return;
    setState(() => _isSigningIn = true);
    try {
      await widget.onGoogleSignIn();
    } finally {
      if (mounted) setState(() => _isSigningIn = false);
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
                          'Fast sign-in with your Google account',
                          style: ts(11, C.textMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _isSigningIn ? null : _signInWithGoogle,
                icon: _isSigningIn
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: C.blue,
                        ),
                      )
                    : const Text(
                        'G',
                        style: TextStyle(
                          color: Color(0xFF4285F4),
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                label: Text(
                  _isSigningIn ? 'Connecting...' : 'Continue with Google',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF202124),
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(R.md),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Your Google account is securely verified with Firebase.',
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
