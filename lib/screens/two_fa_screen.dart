import 'package:material_ui/material_ui.dart';
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
    (_) => TextEditingController(),
  );
  final List<FocusNode> _nodes = List.generate(4, (_) => FocusNode());
  String _firstPin = '';
  String? _inputError;
  bool _isConfirmingPin = false;
  bool _isSubmitting = false;

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
    if (value.isNotEmpty) {
      widget.controller.clearPinEntryError();
      if (_inputError != null) setState(() => _inputError = null);
    }
    if (value.isNotEmpty && index < 3) {
      _nodes[index + 1].requestFocus();
    }
  }

  void _clearInputs() {
    for (final controller in _ctrls) {
      controller.clear();
    }
    _nodes.first.requestFocus();
  }

  Future<void> _submitPin() async {
    if (_isSubmitting) return;
    final enteredPin = _ctrls.map((controller) => controller.text).join();
    if (enteredPin.length != 4) {
      setState(() => _inputError = 'Enter all 4 digits.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _inputError = null;
    });
    try {
      if (widget.controller.pinIsConfigured) {
        await widget.controller.verify2FA(enteredPin);
        if (mounted) _clearInputs();
      } else if (!_isConfirmingPin) {
        _firstPin = enteredPin;
        setState(() => _isConfirmingPin = true);
        _clearInputs();
      } else if (enteredPin != _firstPin) {
        setState(
          () => _inputError = 'The PINs do not match. Confirm your PIN again.',
        );
        _clearInputs();
      } else {
        await widget.controller.configurePin(_firstPin, enteredPin);
        if (mounted) _clearInputs();
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  KeyEventResult _onKey(KeyEvent event, int index) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _ctrls[index].text.isEmpty &&
        index > 0) {
      _ctrls[index - 1].clear();
      _nodes[index - 1].requestFocus();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final isSetup = !controller.pinIsConfigured;
    final title = isSetup
        ? (_isConfirmingPin ? 'Confirm your PIN' : 'Create your PIN')
        : 'Unlock dashboard';
    final description = isSetup
        ? (_isConfirmingPin
              ? 'Enter the same 4-digit PIN again.'
              : 'Choose a personal 4-digit PIN for this account.')
        : 'Enter your personal PIN to continue.';
    final errorMessage = _inputError ?? controller.pinEntryError;

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
                title,
                textAlign: TextAlign.center,
                style: ts(20, C.text, w: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                textAlign: TextAlign.center,
                style: ts(12, C.textMuted),
              ),
              if (controller.pinGateLoading) ...[
                const SizedBox(height: 24),
                const Center(child: CircularProgressIndicator()),
              ] else if (controller.pinGateError != null) ...[
                const SizedBox(height: 16),
                Text(
                  controller.pinGateError!,
                  textAlign: TextAlign.center,
                  style: ts(12, C.red),
                ),
                const SizedBox(height: 16),
                GradientButton(
                  label: 'Retry secure storage',
                  leadingIcon: Icons.refresh,
                  onPressed: controller.retryPinGateCheck,
                ),
              ] else if (controller.pinIsLocked) ...[
                const SizedBox(height: 18),
                Text(
                  'PIN access is locked after too many attempts. Sign in with Google again to retry.',
                  textAlign: TextAlign.center,
                  style: ts(12, C.red),
                ),
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: controller.backToLogin,
                  icon: const Icon(Icons.login, size: 14, color: C.cyan),
                  label: Text(
                    'Sign in with Google again',
                    style: ts(12, C.cyan, w: FontWeight.w600),
                  ),
                ),
              ] else ...[
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
                if (errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    errorMessage,
                    textAlign: TextAlign.center,
                    style: ts(12, C.red),
                  ),
                ],
                const SizedBox(height: 24),
                GradientButton(
                  label: _isSubmitting
                      ? 'Please wait...'
                      : isSetup
                      ? (_isConfirmingPin ? 'Save personal PIN' : 'Continue')
                      : 'Unlock dashboard',
                  leadingIcon: _isSubmitting
                      ? Icons.hourglass_top
                      : Icons.verified_user_outlined,
                  onPressed: _isSubmitting ? null : _submitPin,
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
            ],
          ),
        ),
      ),
    );
  }
}
