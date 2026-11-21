import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models/app_models.dart';
import '../state/app_controller.dart';
import '../widgets/common_widgets.dart';

// ----------------------------------------------------------------------------
//  Security tab
// ----------------------------------------------------------------------------
class SecurityTab extends StatelessWidget {
  const SecurityTab({super.key, required this.controller});
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FadeSlideIn(
          child: Panel(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    const SectionTitle(
                      'Security Vulnerability Audit',
                      subtitle: 'Workshop 04 · Flutter static analysis & secure storage migration',
                    ),
                    GradientButton(
                      label: 'Run Deep Vulnerability Scan',
                      leadingIcon: Icons.manage_search_outlined,
                      expand: false,
                      fontSize: 12,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      onPressed: controller.runSecurityAudit,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                for (final v in controller.vulnerabilities) ...[
                  _vulnTile(v),
                  const SizedBox(height: 12),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        ResponsiveGrid(
          spacing: 24,
          columnsFor: (w) => w >= 1024 ? 2 : 1,
          children: [_storageCard(), _jwtCard()],
        ),
      ],
    );
  }

  Widget _vulnTile(Vulnerability v) {
    final base = v.fixed ? C.green : C.red;
    final fg = v.fixed ? C.greenSoft : C.redSoft;
    final high = v.severity == 'High';

    final info = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconBadge(
          icon: v.fixed
              ? Icons.verified_user_outlined
              : Icons.warning_amber_rounded,
          color: fg,
          size: 40,
          iconSize: 22,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(v.title, style: ts(14, C.text, w: FontWeight.w600)),
                  Pill(
                    v.severity,
                    fg: high ? C.redSoft : C.amberSoft,
                    bg: a(high ? C.red : C.amber, 0.16),
                    radius: 4,
                    uppercase: true,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(v.description, style: ts(12, C.textMuted, height: 1.5)),
            ],
          ),
        ),
      ],
    );

    final action = v.fixed
        ? Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: a(C.green, 0.16),
              borderRadius: BorderRadius.circular(R.md),
              border: Border.all(color: a(C.green, 0.40)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check, size: 14, color: C.greenSoft),
                const SizedBox(width: 6),
                Text('Secured', style: ts(12, C.greenSoft, w: FontWeight.w600)),
              ],
            ),
          )
        : ElevatedButton(
            onPressed: () => controller.fixVulnerability(v.id),
            style: appButtonStyle(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            child: const Text(
              'Apply Patch',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          );

    return LayoutBuilder(
      builder: (context, constraints) {
        final row = constraints.maxWidth >= 560;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: a(base, 0.06),
            borderRadius: BorderRadius.circular(R.md),
            border: Border.all(color: a(base, 0.30)),
          ),
          child: row
              ? Row(
                  children: [
                    Expanded(child: info),
                    const SizedBox(width: 16),
                    action,
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [info, const SizedBox(height: 16), action],
                ),
        );
      },
    );
  }

  Widget _kv(
    String k,
    String v,
    Color vColor, {
    bool mono = true,
    bool bold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Flexible(child: Text(k, style: ts(12, C.textMuted))),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            v,
            textAlign: TextAlign.right,
            style: ts(
              12,
              vColor,
              mono: mono,
              w: bold ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }

  Widget _storageCard() {
    return Panel(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Flutter Secure Storage Migration', style: T.title),
          const SizedBox(height: 8),
          Text(
            'Migrate insecure SharedPreferences tokens into encrypted keystore / Keychain.',
            style: T.subtitle,
          ),
          const SizedBox(height: 16),
          Panel(
            color: C.navy,
            radius: R.md,
            shadow: false,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _kv(
                  'Target Driver:',
                  'flutter_secure_storage v9.0',
                  C.greenSoft,
                ),
                const SizedBox(height: 12),
                _kv(
                  'Android EncryptedSharedPreferences:',
                  'Enabled (AES-256)',
                  C.text,
                  mono: false,
                  bold: true,
                ),
                const SizedBox(height: 12),
                _kv(
                  'iOS Keychain Accessibility:',
                  'afterFirstUnlock',
                  C.text,
                  mono: false,
                  bold: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _solidButton(
            'Force KeyStore Encryption Audit',
            C.blue,
            controller.migrateStorage,
          ),
        ],
      ),
    );
  }

  Widget _jwtCard() {
    return Panel(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('JWT Token Refresh Interceptor', style: T.title),
          const SizedBox(height: 8),
          Text(
            'Simulate handling expired tokens with automatic background refresh retry.',
            style: T.subtitle,
          ),
          const SizedBox(height: 16),
          Panel(
            color: C.navy,
            radius: R.md,
            shadow: false,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Access Token:', style: ts(12, C.textFaint, mono: true)),
                const SizedBox(height: 4),
                Text(
                  controller.jwtState.token,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ts(12, C.cyan, mono: true),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.only(top: 8),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: a(Colors.white, 0.08)),
                    ),
                  ),
                  child: _kv(
                    'Status:',
                    controller.jwtState.status,
                    C.greenSoft,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _solidButton(
            'Trigger JWT Expiry & Refresh Retry',
            C.cyan,
            controller.simulateJwtRefresh,
            tonal: true,
          ),
        ],
      ),
    );
  }

  Widget _solidButton(
    String label,
    Color color,
    VoidCallback onPressed, {
    bool tonal = false,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: appButtonStyle(
        color: color,
        tonal: tonal,
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}
