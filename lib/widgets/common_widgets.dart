import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../core/theme.dart';

// ----------------------------------------------------------------------------
//  Reusable widgets
// ----------------------------------------------------------------------------

/// Midnight-navy page background with two very soft blue / cyan glows.
class AppBackground extends StatelessWidget {
  const AppBackground({super.key, required this.child});
  final Widget child;

  Widget _glow(Color color, double size, double opacity) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [a(color, opacity), a(color, 0)]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [C.navy, C.navyDeep],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(top: -170, left: -130, child: _glow(C.blue, 440, 0.26)),
          Positioned(
            bottom: -190,
            right: -150,
            child: _glow(C.cyan, 440, 0.13),
          ),
          child,
        ],
      ),
    );
  }
}

/// Frosted-glass surface: translucent white fill, thin light border, optional
/// background blur. Set [blur] to 0 to skip the (costly) BackdropFilter.
class GlassSurface extends StatelessWidget {
  const GlassSurface({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.radius = R.lg,
    this.blur = 14,
    this.opacity = 0.10,
    this.tint,
    this.shadow = true,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final double blur;
  final double opacity;
  final Color? tint;
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    final br = BorderRadius.circular(radius);
    Widget surface = DecoratedBox(
      decoration: BoxDecoration(color: tint, borderRadius: br),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: br,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              a(Colors.white, opacity + 0.03),
              a(Colors.white, math.max(0.0, opacity - 0.02)),
            ],
          ),
          border: Border.all(color: C.glassBorder),
        ),
        child: Padding(padding: padding, child: child),
      ),
    );
    if (blur > 0) {
      surface = BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: surface,
      );
    }
    surface = ClipRRect(borderRadius: br, child: surface);
    if (shadow) {
      surface = DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: br,
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 24,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: surface,
      );
    }
    return RepaintBoundary(child: surface);
  }
}

/// Standard content panel. Opaque by default (tables, forms, charts); pass
/// [glass] for a frosted surface (use [blur] > 0 only where it really helps).
class Panel extends StatelessWidget {
  const Panel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.color = C.surface,
    this.borderColor = C.border,
    this.radius = R.lg,
    this.shadow = true,
    this.glass = false,
    this.blur = 0,
  });

  final Widget child;
  final EdgeInsets padding;
  final Color color;
  final Color borderColor;
  final double radius;
  final bool shadow;
  final bool glass;
  final double blur;

  @override
  Widget build(BuildContext context) {
    if (glass) {
      return GlassSurface(
        padding: padding,
        radius: radius,
        blur: blur,
        shadow: shadow,
        child: child,
      );
    }
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor),
        boxShadow: shadow
            ? const [
                BoxShadow(
                  color: Color(0x2E000000),
                  blurRadius: 16,
                  offset: Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: child,
    );
  }
}

class Pill extends StatelessWidget {
  const Pill(
    this.text, {
    super.key,
    required this.fg,
    this.bg,
    this.borderColor,
    this.size = 10,
    this.radius = 999,
    this.uppercase = false,
  });

  final String text;
  final Color fg;
  final Color? bg;
  final Color? borderColor;
  final double size;
  final double radius;
  final bool uppercase;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(radius),
        border: borderColor == null ? null : Border.all(color: borderColor!),
      ),
      child: Text(
        uppercase ? text.toUpperCase() : text,
        style: ts(size, fg, w: FontWeight.w600),
      ),
    );
  }
}

/// Rounded square with a tinted background and an outline icon.
class IconBadge extends StatelessWidget {
  const IconBadge({
    super.key,
    required this.icon,
    required this.color,
    this.size = 44,
    this.iconSize = 20,
    this.radius = R.md,
  });

  final IconData icon;
  final Color color;
  final double size;
  final double iconSize;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: a(color, 0.12),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: a(color, 0.28)),
      ),
      child: Icon(icon, color: color, size: iconSize),
    );
  }
}

/// Section heading: title + optional subtitle.
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key, this.subtitle});
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: T.title),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(subtitle!, style: T.subtitle),
        ],
      ],
    );
  }
}

/// Dashboard statistic card (glass surface).
class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.subIcon,
    required this.sub,
    required this.subColor,
    required this.icon,
    required this.iconColor,
  });

  final String label;
  final String value;
  final IconData subIcon;
  final String sub;
  final Color subColor;
  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Panel(
      glass: true,
      blur: 14,
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: T.label),
                const SizedBox(height: 6),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ts(24, C.text, w: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(subIcon, size: 12, color: subColor),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        sub,
                        overflow: TextOverflow.ellipsis,
                        style: ts(11, subColor, w: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconBadge(icon: icon, color: iconColor),
        ],
      ),
    );
  }
}

/// Usage bar. Normal usage uses [color]; >= 70% turns amber, >= 90% red.
class ProgressBar extends StatelessWidget {
  const ProgressBar({
    super.key,
    required this.value,
    required this.color,
    this.stateAware = true,
  });
  final int value;
  final Color color;
  final bool stateAware;

  Color get _fill => !stateAware
      ? color
      : value >= 90
      ? C.red
      : value >= 70
      ? C.amber
      : color;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: Container(
        height: 6,
        color: a(Colors.white, 0.08),
        alignment: Alignment.centerLeft,
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(end: (value / 100).clamp(0.0, 1.0).toDouble()),
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
          builder: (context, v, _) => FractionallySizedBox(
            widthFactor: v,
            child: Container(color: _fill),
          ),
        ),
      ),
    );
  }
}

/// Primary button (blue). Keeps the original API; [onPressed] may be null to
/// show the disabled state.
class GradientButton extends StatefulWidget {
  const GradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.colors = const [C.blue, C.blueDeep],
    this.leadingIcon,
    this.trailingIcon,
    this.padding = const EdgeInsets.symmetric(vertical: 14),
    this.fontSize = 14,
    this.radius = R.md,
    this.expand = true,
  });

  final String label;
  final List<Color> colors;
  final VoidCallback? onPressed;
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final EdgeInsets padding;
  final double fontSize;
  final double radius;
  final bool expand;

  @override
  State<GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<GradientButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final fg = enabled ? Colors.white : a(Colors.white, 0.4);
    final fills = enabled
        ? widget.colors
        : [a(Colors.white, 0.08), a(Colors.white, 0.08)];

    final content = Row(
      mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.leadingIcon != null) ...[
          Icon(widget.leadingIcon, size: widget.fontSize + 4, color: fg),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Text(
            widget.label,
            overflow: TextOverflow.ellipsis,
            style: ts(widget.fontSize, fg, w: FontWeight.w600),
          ),
        ),
        if (widget.trailingIcon != null) ...[
          const SizedBox(width: 8),
          Icon(widget.trailingIcon, size: widget.fontSize + 4, color: fg),
        ],
      ],
    );

    final br = BorderRadius.circular(widget.radius);
    return AnimatedScale(
      scale: (_down && enabled) ? 0.985 : 1.0,
      duration: const Duration(milliseconds: 110),
      curve: Curves.easeOut,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: fills),
          borderRadius: br,
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: a(C.blueDeep, 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: br,
            onTap: widget.onPressed,
            onHighlightChanged: (v) => setState(() => _down = v),
            hoverColor: a(Colors.white, 0.08),
            focusColor: a(Colors.white, 0.12),
            splashColor: a(Colors.white, 0.14),
            highlightColor: a(Colors.white, 0.06),
            child: Padding(padding: widget.padding, child: content),
          ),
        ),
      ),
    );
  }
}

/// One-shot fade + gentle upward slide, used for card appearance.
class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 420),
    this.offset = 12,
  });

  final Widget child;
  final Duration delay;
  final Duration duration;
  final double offset;

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    final total = widget.delay + widget.duration;
    _ctrl = AnimationController(vsync: this, duration: total);
    final start = total.inMilliseconds == 0
        ? 0.0
        : widget.delay.inMilliseconds / total.inMilliseconds;
    _anim = CurvedAnimation(
      parent: _ctrl,
      curve: Interval(start, 1.0, curve: Curves.easeOutCubic),
    );
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: AnimatedBuilder(
        animation: _anim,
        child: widget.child,
        builder: (context, child) => Transform.translate(
          offset: Offset(0, (1 - _anim.value) * widget.offset),
          child: child,
        ),
      ),
    );
  }
}

/// Responsive grid: equal-width columns, equal-height rows.
class ResponsiveGrid extends StatelessWidget {
  const ResponsiveGrid({
    super.key,
    required this.children,
    required this.columnsFor,
    this.spacing = 16,
  });

  final List<Widget> children;
  final int Function(double width) columnsFor;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = math.max(1, columnsFor(constraints.maxWidth));
        final rows = <Widget>[];
        for (var i = 0; i < children.length; i += cols) {
          final rowChildren = <Widget>[];
          for (var j = 0; j < cols; j++) {
            if (j > 0) rowChildren.add(SizedBox(width: spacing));
            final idx = i + j;
            rowChildren.add(
              Expanded(
                child: idx < children.length
                    ? FadeSlideIn(
                        delay: Duration(milliseconds: math.min(idx, 8) * 60),
                        child: children[idx],
                      )
                    : const SizedBox.shrink(),
              ),
            );
          }
          if (rows.isNotEmpty) rows.add(SizedBox(height: spacing));
          rows.add(
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: rowChildren,
              ),
            ),
          );
        }
        return Column(children: rows);
      },
    );
  }
}

class ScreenBackground extends StatelessWidget {
  const ScreenBackground({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 448),
              child: FadeSlideIn(child: child),
            ),
          ),
        ),
      ),
    );
  }
}

/// Glass card used by the authentication screens.
class AuthCard extends StatelessWidget {
  const AuthCard({super.key, required this.barColors, required this.child});
  final List<Color> barColors;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      radius: R.lg,
      blur: 18,
      opacity: 0.09,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 3,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: barColors),
            ),
          ),
          Padding(padding: const EdgeInsets.all(32), child: child),
        ],
      ),
    );
  }
}

InputDecoration fieldDecoration(String hint, IconData icon) {
  OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(R.md),
    borderSide: BorderSide(color: c, width: w),
  );
  return InputDecoration(
    hintText: hint,
    hintStyle: ts(14, C.textFaint),
    prefixIcon: Icon(icon, size: 18, color: C.textMuted),
    filled: true,
    fillColor: C.navyDeep,
    hoverColor: a(Colors.white, 0.03),
    contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
    enabledBorder: border(C.border),
    disabledBorder: border(a(C.border, 0.5)),
    focusedBorder: border(C.blue, 1.5),
    errorBorder: border(C.red),
    focusedErrorBorder: border(C.red, 1.5),
    errorStyle: ts(11, C.redSoft),
  );
}
