import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../core/theme.dart';
import '../models/app_models.dart';
import '../state/app_controller.dart';
import '../widgets/common_widgets.dart';

// ----------------------------------------------------------------------------
//  Resilience tab
// ----------------------------------------------------------------------------
class ResilienceTab extends StatelessWidget {
  const ResilienceTab({super.key, required this.controller});
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  runSpacing: 12,
                  spacing: 12,
                  children: [
                    const SectionTitle(
                      'Live requests & response cache',
                      subtitle:
                          'Measures real HTTP responses and keeps the latest response in memory.',
                    ),
                    ElevatedButton.icon(
                      onPressed: controller.performNetworkRequest,
                      style: appButtonStyle(),
                      icon: const Icon(Icons.cloud_download_outlined, size: 16),
                      label: const Text(
                        'Send real request',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text('RESPONSES CACHED THIS SESSION', style: T.label),
                const SizedBox(height: 16),
                _cacheTable(),
                if (controller.cachedApiResponse case final response?) ...[
                  const SizedBox(height: 16),
                  Text('LAST CACHED RESPONSE', style: T.label),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: C.navy,
                      borderRadius: BorderRadius.circular(R.md),
                      border: Border.all(color: C.border),
                    ),
                    child: SelectableText(
                      response,
                      style: ts(12, C.cyan, mono: true),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        FadeSlideIn(
          delay: const Duration(milliseconds: 80),
          child: _logPanel(),
        ),
      ],
    );
  }

  Widget _cacheTable() {
    Widget head(String t) => Padding(
      padding: const EdgeInsets.all(16),
      child: Text(t, style: ts(12, C.textMuted, w: FontWeight.w600)),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(R.md),
      child: Container(
        decoration: BoxDecoration(
          color: C.navy,
          border: Border.all(color: C.border),
          borderRadius: BorderRadius.circular(R.md),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = math.max(constraints.maxWidth, 640.0);
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: width,
                child: Table(
                  columnWidths: const {
                    0: FlexColumnWidth(3),
                    1: FlexColumnWidth(2),
                    2: FlexColumnWidth(1.6),
                    3: FlexColumnWidth(2.6),
                  },
                  defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                  border: const TableBorder(
                    horizontalInside: BorderSide(color: C.border),
                  ),
                  children: [
                    TableRow(
                      decoration: BoxDecoration(color: a(Colors.white, 0.04)),
                      children: [
                        head('Endpoint'),
                        head('Captured at'),
                        head('Response size'),
                        head('Cache status'),
                      ],
                    ),
                    if (controller.cacheData.isEmpty)
                      TableRow(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              'No real response cached yet',
                              style: ts(12, C.textMuted),
                            ),
                          ),
                          for (var i = 0; i < 3; i++) const SizedBox.shrink(),
                        ],
                      ),
                    for (final cEntry in controller.cacheData)
                      TableRow(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              cEntry.endpoint,
                              style: ts(
                                12,
                                C.cyan,
                                w: FontWeight.w600,
                                mono: true,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(cEntry.cachedAt, style: ts(12, C.text)),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              cEntry.size,
                              style: ts(12, C.textMuted),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Pill(
                                cEntry.status,
                                fg: C.greenSoft,
                                bg: a(C.green, 0.12),
                                borderColor: a(C.green, 0.30),
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _logPanel() {
    return Panel(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: SectionTitle(
                  'Network request history',
                  subtitle: 'Requests explicitly sent from this screen.',
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: controller.clearLogs,
                style: TextButton.styleFrom(
                  backgroundColor: a(Colors.white, 0.06),
                  foregroundColor: C.text,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    side: BorderSide(color: a(Colors.white, 0.10)),
                    borderRadius: BorderRadius.circular(R.sm),
                  ),
                ),
                child: Text(
                  'Clear Logs',
                  style: ts(12, C.text, w: FontWeight.w500),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            constraints: const BoxConstraints(maxHeight: 240),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: C.navy,
              borderRadius: BorderRadius.circular(R.md),
              border: Border.all(color: C.border),
            ),
            child: controller.interceptorLogs.isEmpty
                ? Text('No logs.', style: ts(12, C.textFaint, mono: true))
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: controller.interceptorLogs.length,
                    itemBuilder: (context, i) =>
                        _logRow(controller.interceptorLogs[i]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _logRow(LogEntry l) {
    final isGet = l.method == 'GET';
    final methodColor = isGet ? C.blueLight : C.cyan;
    final methodBg = isGet ? a(C.blue, 0.22) : a(C.cyan, 0.18);
    final statusColor = l.status == 200
        ? C.greenSoft
        : l.status == 401
        ? C.amberSoft
        : C.redSoft;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: a(Colors.white, 0.06))),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 4,
        children: [
          Wrap(
            spacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(l.time, style: ts(12, C.textFaint, mono: true)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: methodBg,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  l.method,
                  style: ts(10, methodColor, w: FontWeight.w700, mono: true),
                ),
              ),
              Text(l.url, style: ts(12, C.text, mono: true)),
            ],
          ),
          Wrap(
            spacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('HTTP ${l.status}', style: ts(12, statusColor, mono: true)),
              Text('(${l.source})', style: ts(10, C.textMuted, mono: true)),
            ],
          ),
        ],
      ),
    );
  }
}
