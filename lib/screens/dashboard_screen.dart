import 'package:material_ui/material_ui.dart';

import '../core/theme.dart';
import '../models/app_models.dart';
import '../state/app_controller.dart';
import '../widgets/common_widgets.dart';
import 'overview_tab.dart';
import 'resilience_tab.dart';
import 'security_tab.dart';
import 'sidebar.dart';

// ----------------------------------------------------------------------------
//  Dashboard shell
// ----------------------------------------------------------------------------
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, required this.controller});
  final AppController controller;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  AppController get c => widget.controller;

  String get _title {
    switch (c.activeTab) {
      case DashTab.overview:
        return 'Device overview';
      case DashTab.resilience:
        return 'Network resilience';
      case DashTab.security:
        return 'Security context';
    }
  }

  Widget _body() {
    switch (c.activeTab) {
      case DashTab.overview:
        return OverviewTab(controller: c);
      case DashTab.resilience:
        return ResilienceTab(controller: c);
      case DashTab.security:
        return SecurityTab(controller: c);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 768;
        final compact = constraints.maxWidth < 640;
        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: C.navy,
          drawer: wide
              ? null
              : Drawer(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  shape: const RoundedRectangleBorder(),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: GlassSurface(
                      radius: R.lg,
                      blur: 20,
                      tint: a(C.navyDeep, 0.80),
                      child: Sidebar(controller: c, closeOnSelect: true),
                    ),
                  ),
                ),
          body: AppBackground(
            child: SafeArea(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (wide)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 12, 0, 12),
                      child: SizedBox(
                        width: 256,
                        child: GlassSurface(
                          radius: R.lg,
                          blur: 18,
                          tint: a(C.navyDeep, 0.45),
                          child: Sidebar(controller: c),
                        ),
                      ),
                    ),
                  Expanded(
                    child: Column(
                      children: [
                        _header(wide, compact),
                        Expanded(
                          child: SingleChildScrollView(
                            padding: EdgeInsets.all(compact ? 16 : 24),
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 260),
                              switchInCurve: Curves.easeOut,
                              switchOutCurve: Curves.easeIn,
                              child: KeyedSubtree(
                                key: ValueKey<DashTab>(c.activeTab),
                                child: _body(),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _header(bool wide, bool compact) {
    return Padding(
      padding: EdgeInsets.fromLTRB(compact ? 12 : 24, 12, compact ? 12 : 24, 0),
      child: GlassSurface(
        radius: R.lg,
        blur: 16,
        tint: a(C.navyDeep, 0.35),
        padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 16),
        child: SizedBox(
          height: 60,
          child: Row(
            children: [
              if (!wide)
                IconButton(
                  onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                  icon: const Icon(Icons.menu, color: C.textMuted),
                ),
              Expanded(
                child: Text(
                  _title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ts(16, C.text, w: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: a(C.navyDeep, 0.55),
                  borderRadius: BorderRadius.circular(R.md),
                  border: Border.all(color: a(Colors.white, 0.10)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!compact) ...[
                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Text(
                          'Network Status:',
                          style: ts(12, C.textMuted, w: FontWeight.w500),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    _networkStatusIndicator(compact),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Tooltip(
                message: 'Refresh Telemetry',
                child: Material(
                  color: a(Colors.white, 0.06),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(R.md),
                    side: BorderSide(color: a(Colors.white, 0.10)),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(R.md),
                    hoverColor: a(Colors.white, 0.08),
                    onTap: c.triggerRefresh,
                    child: const Padding(
                      padding: EdgeInsets.all(8),
                      child: Icon(Icons.refresh, size: 20, color: C.text),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _networkStatusIndicator(bool compact) {
    final label = !c.isConnectivityKnown
        ? 'Checking'
        : !c.isOnline
        ? 'Offline'
        : !c.hasProbedNetwork
        ? '${c.connectionType} · checking'
        : c.internetReachable
        ? c.connectionType
        : '${c.connectionType} · no internet';
    final color = !c.isConnectivityKnown
        ? C.textMuted
        : c.isOnline && !c.hasProbedNetwork
        ? C.blueLight
        : c.isOnline && c.internetReachable
        ? C.greenSoft
        : C.amberSoft;
    final base = !c.isConnectivityKnown
        ? C.textMuted
        : c.isOnline && !c.hasProbedNetwork
        ? C.blue
        : c.isOnline && c.internetReachable
        ? C.green
        : C.amber;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: a(base, 0.16),
        borderRadius: BorderRadius.circular(R.sm),
        border: Border.all(color: a(base, 0.40)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: base, shape: BoxShape.circle),
          ),
          if (!compact) ...[
            const SizedBox(width: 6),
            Text(label, style: ts(12, color, w: FontWeight.w600)),
          ] else ...[
            const SizedBox(width: 6),
            Text(
              !c.isConnectivityKnown
                  ? '…'
                  : c.isOnline
                  ? 'Online'
                  : 'Offline',
              style: ts(12, color, w: FontWeight.w600),
            ),
          ],
        ],
      ),
    );
  }
}
