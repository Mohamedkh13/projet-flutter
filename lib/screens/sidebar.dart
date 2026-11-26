import 'package:material_ui/material_ui.dart';

import '../core/theme.dart';
import '../models/app_models.dart';
import '../state/app_controller.dart';

// ----------------------------------------------------------------------------
//  Sidebar
// ----------------------------------------------------------------------------
class Sidebar extends StatelessWidget {
  const Sidebar({
    super.key,
    required this.controller,
    this.closeOnSelect = false,
  });
  final AppController controller;
  final bool closeOnSelect;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: a(Colors.white, 0.10))),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: C.blue,
                    borderRadius: BorderRadius.circular(R.sm),
                  ),
                  child: const Icon(
                    Icons.flutter_dash,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Device Monitor',
                        overflow: TextOverflow.ellipsis,
                        style: ts(14, C.text, w: FontWeight.w700, ls: 0.3),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: C.green,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Live local telemetry',
                            style: ts(10, C.greenSoft, mono: true),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                  child: Text(
                    'DEVICE MONITORING',
                    style: ts(10, C.textFaint, w: FontWeight.w600, ls: 1),
                  ),
                ),
                _navItem(
                  context,
                  'Device overview',
                  Icons.show_chart,
                  DashTab.overview,
                ),
                const SizedBox(height: 4),
                _navItem(
                  context,
                  'Network resilience',
                  Icons.wifi_outlined,
                  DashTab.resilience,
                ),
                const SizedBox(height: 4),
                _navItem(
                  context,
                  'Security context',
                  Icons.security_outlined,
                  DashTab.security,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: a(Colors.white, 0.10))),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(colors: [C.blue, C.cyan]),
                      ),
                      child: Text(
                        'AD',
                        style: ts(12, Colors.white, w: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Signed-in account',
                            overflow: TextOverflow.ellipsis,
                            style: ts(12, C.text, w: FontWeight.w600),
                          ),
                          Text(
                            controller.username,
                            overflow: TextOverflow.ellipsis,
                            style: ts(10, C.textMuted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: Material(
                    color: a(C.red, 0.10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(R.md),
                      side: BorderSide(color: a(C.red, 0.30)),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(R.md),
                      hoverColor: a(C.red, 0.10),
                      onTap: () {
                        if (closeOnSelect) Navigator.of(context).pop();
                        controller.logout();
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.logout,
                              size: 14,
                              color: C.redSoft,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Terminate Session',
                              style: ts(12, C.redSoft, w: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _navItem(
    BuildContext context,
    String label,
    IconData icon,
    DashTab tab,
  ) {
    final active = controller.activeTab == tab;
    return Material(
      color: active ? a(C.blue, 0.22) : Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(R.md),
        side: BorderSide(color: active ? a(C.blue, 0.55) : Colors.transparent),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(R.md),
        hoverColor: a(Colors.white, 0.05),
        onTap: () {
          if (closeOnSelect) Navigator.of(context).pop();
          controller.setTab(tab);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          child: Row(
            children: [
              Icon(icon, size: 18, color: active ? C.cyan : C.textMuted),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: ts(
                    14,
                    active ? C.text : C.textMuted,
                    w: active ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
