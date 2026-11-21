import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme.dart';
import '../state/app_controller.dart';
import '../widgets/common_widgets.dart';

// ----------------------------------------------------------------------------
//  2FA screen
// ----------------------------------------------------------------------------
class TwoFaScreen extends StatefulWidget {
  const TwoFaScreen({super.key, required this.controller});
  final AppController controller;

  @override
  State<TwoFaScreen> createState() => _TwoFaScreenState();
}

class _TwoFaScreenState extends State<TwoFaScreen> {
  late final List<TextEditingController> _ctrls = List.generate(
    4,
    (i) => TextEditingController(text: widget.controller.pin[i]),
  );
  final List<FocusNode> _nodes = List.generate(4, (_) => FocusNode());

  @override
  void dispose() {
    for (final c in _ctrls) {
      c.dispose();
    }
    for (final n in _nodes) {
      n.dispose();
    }
    super.dispose();
  }

  void _onChanged(String value, int index) {
    widget.controller.setPinDigit(index, value);
    if (value.isNotEmpty && index < 3) {
      _nodes[index + 1].requestFocus();
    }
  }

  KeyEventResult _onKey(KeyEvent event, int index) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _ctrls[index].text.isEmpty &&
        index > 0) {
      _ctrls[index - 1].clear();
      widget.controller.setPinDigit(index - 1, '');
      _nodes[index - 1].requestFocus();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ScreenBackground(
        child: AuthCard(
          barColors: const [C.cyan, C.blue],
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Center(
                child: IconBadge(
                  icon: Icons.vpn_key_outlined,
                  color: C.cyan,
                  size: 56,
                  iconSize: 26,
                  radius: R.lg,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Two-Factor Authentication',
                textAlign: TextAlign.center,
                style: ts(20, C.text, w: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                'Enter the 4-digit security PIN sent to your authenticator app',
                textAlign: TextAlign.center,
                style: ts(12, C.textMuted),
              ),
              const SizedBox(height: 8),
              Center(
                child: Pill(
                  'Demo PIN: 1 2 3 4',
                  fg: C.cyan,
                  bg: a(C.cyan, 0.10),
                  borderColor: a(C.cyan, 0.30),
                  size: 12,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (i) {
                  return Padding(
                    padding: EdgeInsets.only(left: i == 0 ? 0 : 14),
                    child: SizedBox(
                      width: 56,
                      height: 64,
                      child: Focus(
                        onKeyEvent: (node, event) => _onKey(event, i),
                        child: TextField(
                          controller: _ctrls[i],
                          focusNode: _nodes[i],
                          maxLength: 1,
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          style: ts(24, C.text, w: FontWeight.w700),
                          onChanged: (v) => _onChanged(v, i),
                          decoration: InputDecoration(
                            counterText: '',
                            filled: true,
                            fillColor: C.navyDeep,
                            hoverColor: a(Colors.white, 0.03),
                            contentPadding: EdgeInsets.zero,
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(R.md),
                              borderSide: const BorderSide(color: C.border),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(R.md),
                              borderSide: const BorderSide(
                                color: C.blue,
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 24),
              GradientButton(
                label: 'Verify & Launch Dashboard',
                leadingIcon: Icons.verified_user_outlined,
                onPressed: () => widget.controller.verify2FA(),
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: widget.controller.backToLogin,
                icon: const Icon(
                  Icons.arrow_back,
                  size: 14,
                  color: C.textMuted,
                ),
                label: Text(
                  'Back to Login',
                  style: ts(12, C.textMuted, w: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
