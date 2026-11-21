import 'package:flutter/material.dart';

import '../core/theme.dart';

// ----------------------------------------------------------------------------
//  Custom line chart (replaces Chart.js)
// ----------------------------------------------------------------------------
class ChartSeries {
  const ChartSeries(this.label, this.data, this.color, this.fillOpacity);
  final String label;
  final List<double> data;
  final Color color;
  final double fillOpacity;
}

class LineChartPainter extends CustomPainter {
  LineChartPainter({
    required this.labels,
    required this.series,
    this.warnAt = 70,
    this.criticalAt = 90,
  });
  final List<String> labels;
  final List<ChartSeries> series;

  /// Visual reference lines separating normal / warning / critical ranges.
  final double warnAt;
  final double criticalAt;

  static const double _left = 34;
  static const double _right = 8;
  static const double _top = 8;
  static const double _bottom = 24;

  void _text(
    Canvas canvas,
    String text,
    Offset anchor, {
    bool alignRight = false,
    bool center = false,
  }) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: ts(10, C.textMuted)),
      textDirection: TextDirection.ltr,
    )..layout();
    Offset o;
    if (alignRight) {
      o = Offset(anchor.dx - tp.width, anchor.dy - tp.height / 2);
    } else if (center) {
      o = Offset(anchor.dx - tp.width / 2, anchor.dy);
    } else {
      o = anchor;
    }
    tp.paint(canvas, o);
  }

  void _dashedLine(Canvas canvas, Offset p1, Offset p2, Paint paint) {
    const dash = 5.0;
    const gap = 4.0;
    var x = p1.dx;
    while (x < p2.dx) {
      final end = (x + dash) > p2.dx ? p2.dx : x + dash;
      canvas.drawLine(Offset(x, p1.dy), Offset(end, p2.dy), paint);
      x += dash + gap;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final chart = Rect.fromLTRB(
      _left,
      _top,
      size.width - _right,
      size.height - _bottom,
    );
    if (chart.width <= 0 || chart.height <= 0) return;

    // Grid + Y labels
    final gridPaint = Paint()
      ..color = a(Colors.white, 0.07)
      ..strokeWidth = 1;
    for (var v = 0; v <= 100; v += 25) {
      final y = chart.bottom - chart.height * v / 100;
      canvas.drawLine(Offset(chart.left, y), Offset(chart.right, y), gridPaint);
      _text(canvas, '$v', Offset(chart.left - 6, y), alignRight: true);
    }

    // Warning / critical reference lines
    final warnY = chart.bottom - chart.height * warnAt / 100;
    final critY = chart.bottom - chart.height * criticalAt / 100;
    _dashedLine(
      canvas,
      Offset(chart.left, warnY),
      Offset(chart.right, warnY),
      Paint()
        ..color = a(C.amber, 0.55)
        ..strokeWidth = 1,
    );
    _dashedLine(
      canvas,
      Offset(chart.left, critY),
      Offset(chart.right, critY),
      Paint()
        ..color = a(C.red, 0.55)
        ..strokeWidth = 1,
    );

    final n = labels.length;
    if (n < 2) return;
    final dx = chart.width / (n - 1);

    // X labels
    for (var i = 0; i < n; i++) {
      _text(
        canvas,
        labels[i],
        Offset(chart.left + dx * i, chart.bottom + 6),
        center: true,
      );
    }

    // Series
    for (final s in series) {
      final pts = <Offset>[
        for (var i = 0; i < s.data.length; i++)
          Offset(
            chart.left + dx * i,
            chart.bottom - chart.height * (s.data[i].clamp(0, 100)) / 100,
          ),
      ];
      if (pts.length < 2) continue;

      final line = Path()..moveTo(pts.first.dx, pts.first.dy);
      for (var i = 1; i < pts.length; i++) {
        final p0 = pts[i - 1];
        final p1 = pts[i];
        final mid = (p0.dx + p1.dx) / 2;
        line.cubicTo(mid, p0.dy, mid, p1.dy, p1.dx, p1.dy);
      }

      final fill = Path.from(line)
        ..lineTo(pts.last.dx, chart.bottom)
        ..lineTo(pts.first.dx, chart.bottom)
        ..close();
      final topAlpha = (s.fillOpacity * 3).clamp(0.0, 1.0).toDouble();
      canvas.drawPath(
        fill,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [a(s.color, topAlpha), a(s.color, 0)],
          ).createShader(chart),
      );
      canvas.drawPath(
        line,
        Paint()
          ..color = s.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round,
      );
      for (final p in pts) {
        canvas.drawCircle(p, 3.5, Paint()..color = C.surface);
        canvas.drawCircle(
          p,
          3.5,
          Paint()
            ..color = s.color
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant LineChartPainter old) =>
      old.series != series ||
      old.labels != labels ||
      old.warnAt != warnAt ||
      old.criticalAt != criticalAt;
}
