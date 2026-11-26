import 'package:material_ui/material_ui.dart';

import '../core/theme.dart';
import '../models/app_models.dart';
import '../state/app_controller.dart';
import '../widgets/common_widgets.dart';
import '../widgets/line_chart.dart';

class OverviewTab extends StatelessWidget {
  const OverviewTab({super.key, required this.controller});
  final AppController controller;

  String _percent(double? value) =>
      value == null ? 'Unavailable' : '${value.toStringAsFixed(1)}%';

  String _memory(double? value) =>
      value == null ? 'Unavailable' : '${value.toStringAsFixed(1)} MiB';

  @override
  Widget build(BuildContext context) {
    final ramSamples = controller.deviceSamples
        .where((sample) => sample.memoryUsedPercent != null)
        .toList();
    final online = controller.isOnline;
    final endpointCount = controller.endpointProbes.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ResponsiveGrid(
          columnsFor: (width) => width >= 1024 ? 4 : (width >= 640 ? 2 : 1),
          children: [
            StatCard(
              label: 'DEVICE',
              value: controller.deviceName,
              subIcon: Icons.phone_android_outlined,
              sub: controller.deviceOs,
              subColor: C.blueLight,
              icon: Icons.devices_outlined,
              iconColor: C.blueLight,
            ),
            StatCard(
              label: 'APP CPU',
              value: _percent(controller.appCpuPercent),
              subIcon: Icons.memory_outlined,
              sub: controller.supportsNativeDeviceMetrics
                  ? 'Measured process load'
                  : 'Not exposed by this platform',
              subColor: C.cyan,
              icon: Icons.speed_outlined,
              iconColor: C.cyan,
            ),
            StatCard(
              label: 'DEVICE RAM',
              value: _percent(controller.memoryUsedPercent),
              subIcon: Icons.storage_outlined,
              sub: controller.totalMemoryMb == null
                  ? 'System memory usage'
                  : '${(controller.totalMemoryMb! / 1024).toStringAsFixed(1)} GB total',
              subColor: C.blueLight,
              icon: Icons.memory_outlined,
              iconColor: C.blueLight,
            ),
            StatCard(
              label: 'BATTERY',
              value: controller.batteryLevel == null
                  ? 'Unavailable'
                  : '${controller.batteryLevel}%',
              subIcon: Icons.battery_std_outlined,
              sub: controller.batteryState,
              subColor: C.greenSoft,
              icon: Icons.battery_charging_full_outlined,
              iconColor: C.greenSoft,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Panel(
          padding: const EdgeInsets.all(18),
          child: Wrap(
            spacing: 24,
            runSpacing: 12,
            children: [
              _detail('Network', online ? controller.connectionType : 'None'),
              _detail(
                'Internet',
                !controller.isConnectivityKnown
                    ? 'Checking'
                    : !online
                    ? 'Unavailable'
                    : !controller.hasProbedNetwork
                    ? 'Probing endpoints'
                    : controller.internetReachable
                    ? 'Reachable'
                    : 'No response',
              ),
              _detail('Local IP', controller.localIpAddress),
              _detail(
                'Mean endpoint RTT',
                controller.networkLatencyMs == null
                    ? 'Unavailable'
                    : '${controller.networkLatencyMs} ms',
              ),
              _detail('App memory', _memory(controller.appMemoryMb)),
              _detail(
                'Last sample',
                controller.lastUpdatedAt == null
                    ? 'Waiting for first sample'
                    : TimeOfDay.fromDateTime(
                        controller.lastUpdatedAt!.toLocal(),
                      ).format(context),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        LayoutBuilder(
          builder: (context, constraints) {
            final telemetry = _telemetryPanel(ramSamples);
            final alerts = _alertsPanel();
            if (constraints.maxWidth >= 1024) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 2, child: telemetry),
                  const SizedBox(width: 24),
                  Expanded(child: alerts),
                ],
              );
            }
            return Column(
              children: [telemetry, const SizedBox(height: 24), alerts],
            );
          },
        ),
        const SizedBox(height: 24),
        _endpointPanel(endpointCount),
      ],
    );
  }

  Widget _detail(String label, String value) {
    return SizedBox(
      width: 180,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: T.label),
          const SizedBox(height: 4),
          Text(value, style: ts(13, C.text, w: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _telemetryPanel(List<DeviceSample> samples) {
    final series = samples
        .map((sample) => sample.memoryUsedPercent)
        .whereType<double>()
        .toList();
    final labels = samples
        .where((sample) => sample.memoryUsedPercent != null)
        .map((sample) {
          final time = sample.time.toLocal();
          return '${time.hour.toString().padLeft(2, '0')}:'
              '${time.minute.toString().padLeft(2, '0')}:'
              '${time.second.toString().padLeft(2, '0')}';
        })
        .toList();

    return Panel(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(
            'Device memory history',
            subtitle: 'System RAM usage sampled from this Android device',
          ),
          const SizedBox(height: 12),
          if (!controller.supportsNativeDeviceMetrics)
            Text(
              'System CPU and memory load are not exposed by this platform.',
              style: ts(12, C.textMuted),
            )
          else if (series.length < 2)
            Text('Collecting live device samples…', style: ts(12, C.textMuted))
          else
            SizedBox(
              height: 240,
              width: double.infinity,
              child: CustomPaint(
                painter: LineChartPainter(
                  labels: labels,
                  series: [ChartSeries('Device RAM (%)', series, C.cyan, 0.06)],
                ),
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
              const Expanded(child: SectionTitle('Device alerts')),
              Pill(
                '${controller.alerts.length}',
                fg: C.textMuted,
                bg: a(Colors.white, 0.06),
                borderColor: C.border,
                size: 12,
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (controller.alerts.isEmpty)
            Text(
              'No connectivity changes have been detected.',
              style: ts(12, C.textMuted),
            ),
          for (final alert in controller.alerts) ...[
            _alertTile(alert),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }

  Widget _alertTile(AlertItem alert) {
    final base = alert.type == AlertType.critical
        ? C.red
        : alert.type == AlertType.warning
        ? C.amber
        : C.blue;
    final foreground = alert.type == AlertType.critical
        ? C.redSoft
        : alert.type == AlertType.warning
        ? C.amberSoft
        : C.blueLight;

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
                alert.type.name.toUpperCase(),
                style: ts(10, foreground, w: FontWeight.w700, ls: 1),
              ),
              Text(alert.time, style: ts(10, C.textFaint)),
            ],
          ),
          const SizedBox(height: 4),
          Text(alert.message, style: ts(12, C.text, height: 1.5)),
        ],
      ),
    );
  }

  Widget _endpointPanel(int endpointCount) {
    return Panel(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle(
            'Live network endpoint checks',
            subtitle:
                'Actual HTTP response times from this device ($endpointCount targets)',
          ),
          const SizedBox(height: 16),
          ResponsiveGrid(
            columnsFor: (width) => width >= 1024 ? 3 : (width >= 640 ? 2 : 1),
            children: [
              for (final probe in controller.endpointProbes)
                _endpointCard(probe),
            ],
          ),
        ],
      ),
    );
  }

  Widget _endpointCard(EndpointProbe probe) {
    final color = switch (probe.status) {
      ServerStatus.optimal => C.greenSoft,
      ServerStatus.warning => C.amberSoft,
      ServerStatus.offline => C.redSoft,
      ServerStatus.unknown => C.textMuted,
    };

    return Panel(
      color: C.navy,
      radius: R.md,
      shadow: false,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(probe.name, style: ts(14, C.text, w: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(
            Uri.parse(probe.url).host,
            style: ts(11, C.textMuted, mono: true),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Pill(
                probe.status.name,
                fg: color,
                bg: a(color, 0.12),
                borderColor: a(color, 0.30),
                uppercase: true,
              ),
              Text(
                probe.latencyMs == null ? '—' : '${probe.latencyMs} ms',
                style: ts(12, C.text, w: FontWeight.w600, mono: true),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
