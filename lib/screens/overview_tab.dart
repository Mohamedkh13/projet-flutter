import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models/app_models.dart';
import '../state/app_controller.dart';
import '../widgets/common_widgets.dart';
import '../widgets/line_chart.dart';

// ----------------------------------------------------------------------------
//  Overview tab
// ----------------------------------------------------------------------------
class OverviewTab extends StatelessWidget {
  const OverviewTab({super.key, required this.controller});
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final servers = controller.servers;
    final optimal = servers
        .where((s) => s.status == ServerStatus.optimal)
        .length;
    final warning = servers
        .where((s) => s.status == ServerStatus.warning)
        .length;
    final offline = servers
        .where((s) => s.status == ServerStatus.offline)
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ResponsiveGrid(
          columnsFor: (w) => w >= 1024 ? 4 : (w >= 640 ? 2 : 1),
          children: [
            StatCard(
              label: 'ACTIVE SERVERS',
              value: '${servers.length} Nodes',
              subIcon: Icons.arrow_upward,
              sub: '$optimal Optimal Status',
              subColor: C.greenSoft,
              icon: Icons.dns_outlined,
              iconColor: C.blueLight,
            ),
            StatCard(
              label: 'ACTIVE WARNINGS',
              value: '$warning Node(s)',
              subIcon: Icons.warning_amber_rounded,
              sub: 'High Memory Load',
              subColor: C.amberSoft,
              icon: Icons.notifications_outlined,
              iconColor: C.amberSoft,
            ),
            StatCard(
              label: 'OFFLINE CLUSTERS',
              value: '$offline Node(s)',
              subIcon: Icons.cancel_outlined,
              sub: 'Fallback Triggered',
              subColor: C.redSoft,
              icon: Icons.warning_amber_rounded,
              iconColor: C.redSoft,
            ),
            StatCard(
              label: 'NETWORK LATENCY',
              value: '24.5 ms',
              subIcon: Icons.bolt_outlined,
              sub: 'Fiber Backbone',
              subColor: C.greenSoft,
              icon: Icons.speed_outlined,
              iconColor: C.cyan,
            ),
          ],
        ),
        const SizedBox(height: 24),
        LayoutBuilder(
          builder: (context, constraints) {
            final chart = _chartPanel();
            final alerts = _alertsPanel();
            if (constraints.maxWidth >= 1024) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 2, child: chart),
                  const SizedBox(width: 24),
                  Expanded(child: alerts),
                ],
              );
            }
            return Column(
              children: [chart, const SizedBox(height: 24), alerts],
            );
          },
        ),
        const SizedBox(height: 24),
        _serversPanel(servers),
      ],
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: T.caption),
      ],
    );
  }

  Widget _legendDash(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 14, height: 2, color: a(color, 0.7)),
        const SizedBox(width: 6),
        Text(label, style: T.caption),
      ],
    );
  }

  Widget _chartPanel() {
    final series = <ChartSeries>[
      ChartSeries('CPU Load (%)', const [35, 48, 42, 65, 58, 62], C.blue, 0.10),
      ChartSeries(
        'RAM Usage (%)',
        const [60, 62, 68, 75, 71, 74],
        C.cyan,
        0.05,
      ),
    ];
    const labels = ['12:40', '12:41', '12:42', '12:43', '12:44', '12:45'];

    return Panel(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: SectionTitle(
                  'CPU & RAM Cluster Telemetry',
                  subtitle: 'Simulated live metrics updated via WebSocket / Dio Interceptor',
                ),
              ),
              const SizedBox(width: 8),
              Pill(
                'Live Stream',
                fg: C.cyan,
                bg: a(C.cyan, 0.12),
                borderColor: a(C.cyan, 0.30),
                size: 12,
                radius: 8,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 6,
            children: [
              for (final s in series) _legendDot(s.color, s.label),
              _legendDash(C.amber, 'Warning'),
              _legendDash(C.red, 'Critical'),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 260,
            width: double.infinity,
            child: CustomPaint(
              painter: LineChartPainter(labels: labels, series: series),
            ),
          ),
        ],
      ),
    );
  }

  Widget _alertsPanel() {
    return Panel(
      glass: true,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(child: SectionTitle('Active System Alerts')),
              Pill(
                '${controller.alerts.length}',
                fg: C.redSoft,
                bg: a(C.red, 0.16),
                borderColor: a(C.red, 0.30),
                size: 12,
              ),
            ],
          ),
          const SizedBox(height: 16),
          for (final al in controller.alerts) ...[
            _alertTile(al),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }

  Widget _alertTile(AlertItem al) {
    final base = al.type == AlertType.critical
        ? C.red
        : al.type == AlertType.warning
        ? C.amber
        : C.blue;
    final col = al.type == AlertType.critical
        ? C.redSoft
        : al.type == AlertType.warning
        ? C.amberSoft
        : C.blueLight;
    final name = al.type.name;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: a(base, 0.08),
        borderRadius: BorderRadius.circular(R.md),
        border: Border.all(color: a(base, 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                name.toUpperCase(),
                style: ts(10, col, w: FontWeight.w700, ls: 1),
              ),
              Text(al.time, style: ts(10, C.textFaint)),
            ],
          ),
          const SizedBox(height: 4),
          Text(al.message, style: ts(12, C.text, height: 1.5)),
        ],
      ),
    );
  }

  Widget _serversPanel(List<ServerNode> servers) {
    return Panel(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(
            'Managed Virtual Servers',
            subtitle: 'Pixel-perfect responsive cards & status matrix',
          ),
          const SizedBox(height: 16),
          ResponsiveGrid(
            columnsFor: (w) => w >= 1024 ? 4 : (w >= 640 ? 2 : 1),
            children: [for (final s in servers) _serverCard(s)],
          ),
        ],
      ),
    );
  }

  Widget _serverCard(ServerNode srv) {
    late final Color col;
    late final Color base;
    switch (srv.status) {
      case ServerStatus.optimal:
        col = C.greenSoft;
        base = C.green;
        break;
      case ServerStatus.warning:
        col = C.amberSoft;
        base = C.amber;
        break;
      case ServerStatus.offline:
        col = C.redSoft;
        base = C.red;
        break;
    }
    return Panel(
      color: C.navy,
      radius: R.md,
      shadow: false,
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(srv.id, style: ts(12, C.textMuted, mono: true)),
                  Pill(
                    srv.status.name,
                    fg: col,
                    bg: a(base, 0.12),
                    borderColor: a(base, 0.30),
                    uppercase: true,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(srv.name, style: ts(14, C.text, w: FontWeight.w600)),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.lan_outlined, size: 12, color: C.textMuted),
                  const SizedBox(width: 4),
                  Text(srv.ip, style: ts(12, C.textMuted, mono: true)),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
          Container(
            padding: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: a(Colors.white, 0.08))),
            ),
            child: Column(
              children: [
                _usageRow('CPU Usage', srv.cpu, C.blue),
                const SizedBox(height: 12),
                _usageRow('RAM Allocation', srv.ram, C.cyan),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _usageRow(String label, int value, Color color) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: ts(12, C.textMuted)),
            Text('$value%', style: ts(12, C.text, w: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 4),
        ProgressBar(value: value, color: color),
      ],
    );
  }
}
