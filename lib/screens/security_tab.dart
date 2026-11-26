import 'package:material_ui/material_ui.dart';

import '../core/theme.dart';
import '../state/app_controller.dart';
import '../widgets/common_widgets.dart';

class SecurityTab extends StatelessWidget {
  const SecurityTab({super.key, required this.controller});
  final AppController controller;

  String _dateTime(DateTime? value) {
    if (value == null) return 'Unavailable';
    final time = value.toLocal();
    String twoDigits(int number) => number.toString().padLeft(2, '0');
    return '${time.year}-${twoDigits(time.month)}-${twoDigits(time.day)} '
        '${twoDigits(time.hour)}:${twoDigits(time.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final physicalDevice = controller.isPhysicalDevice == null
        ? 'Not reported by platform'
        : controller.isPhysicalDevice!
        ? 'Physical device'
        : 'Emulator / simulator';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Panel(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                runSpacing: 12,
                children: [
                  const SectionTitle(
                    'Live device security context',
                    subtitle:
                        'Current runtime and Firebase session details; this app does not scan other apps or modify device security.',
                  ),
                  ElevatedButton.icon(
                    onPressed: controller.refreshSecurityStatus,
                    style: appButtonStyle(),
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Refresh device checks'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _row('Device', controller.deviceName),
              const Divider(height: 24),
              _row('Operating system', controller.deviceOs),
              const Divider(height: 24),
              _row('Device type', physicalDevice),
              const Divider(height: 24),
              _row(
                'App build',
                controller.isReleaseBuild ? 'Release' : 'Debug',
              ),
              const Divider(height: 24),
              _row('Firebase sign-in provider', controller.authProvider),
              const Divider(height: 24),
              _row(
                'Firebase ID token expiry',
                _dateTime(controller.tokenExpiresAt),
              ),
              const Divider(height: 24),
              _row(
                'HTTPS certificate validation',
                'Enabled (platform default; no custom certificate bypass)',
              ),
              const Divider(height: 24),
              _row(
                'Runtime permissions',
                'No dangerous permissions requested for these metrics',
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Panel(
          glass: true,
          padding: const EdgeInsets.all(20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline, color: C.cyan, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Network access uses Android install-time permissions. '
                  'Battery, app memory, and device identity do not require '
                  'location or storage access, so the app does not prompt for '
                  'unnecessary sensitive permissions.',
                  style: ts(12, C.textMuted, height: 1.5),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _row(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Text(label, style: ts(12, C.textMuted))),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: ts(12, C.text, w: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
