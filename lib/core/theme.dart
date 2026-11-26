import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:material_ui/material_ui.dart';

// ----------------------------------------------------------------------------
//  Design system - Dark Minimalist + Subtle Glassmorphism
//  Every colour, radius, spacing value and text style used by the UI lives
//  here so the whole application stays visually consistent.
// ----------------------------------------------------------------------------

/// Colour palette.
class C {
  C._();

  // Brand palette
  static const navy = Color(0xFF101B2D); // Midnight Navy - app background
  static const navyDeep = Color(0xFF0A1322); // darker navy for insets / depth
  static const blue = Color(0xFF2563EB); // Electric Blue - primary
  static const blueDeep = Color(0xFF1D4ED8); // pressed / gradient end
  static const blueLight = Color(0xFF60A5FA); // blue for text/icons on dark
  static const cyan = Color(0xFF22C5D9); // Cyan - secondary highlight
  static const text = Color(0xFFF1F5F9); // Soft White - primary text

  // Semantic colours
  static const green = Color(0xFF10B981); // success / healthy
  static const amber = Color(0xFFF59E0B); // warning
  static const red = Color(0xFFEF4444); // critical / error
  static const greenSoft = Color(0xFF34D399); // readable on dark surfaces
  static const amberSoft = Color(0xFFFBBF24);
  static const redSoft = Color(0xFFF87171);

  // Neutrals
  static const surface = Color(0xFF16233A); // opaque card / table surface
  static const surfaceHigh = Color(0xFF1C2B47);
  static const border = Color(0xFF2A3A55); // border on opaque surfaces
  static const glassBorder = Color(0x2EFFFFFF); // ~18% white
  static const textMuted = Color(0xFF94A3B8);
  static const textFaint = Color(0xFF7C8BA1);
}

/// Corner radii.
class R {
  R._();
  static const double sm = 10;
  static const double md = 12;
  static const double lg = 16;
}

/// Spacing scale.
class S {
  S._();
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
}

/// Colour with opacity (works on every Flutter version).
Color a(Color c, double opacity) => c.withAlpha((opacity * 255).round());

const String kFontSans = 'Inter';
const List<String> kFontFallback = ['Roboto', 'Segoe UI', 'Helvetica Neue'];

TextStyle ts(
  double size,
  Color color, {
  FontWeight w = FontWeight.w400,
  double? ls,
  bool mono = false,
  double? height,
}) => TextStyle(
  fontSize: size,
  color: color,
  fontWeight: w,
  letterSpacing: ls,
  height: height,
  fontFamily: mono ? 'monospace' : kFontSans,
  fontFamilyFallback: mono ? null : kFontFallback,
);

/// Typography hierarchy.
class T {
  T._();
  static TextStyle get title => ts(16, C.text, w: FontWeight.w600);
  static TextStyle get subtitle => ts(12, C.textMuted, height: 1.4);
  static TextStyle get label =>
      ts(11, C.textMuted, w: FontWeight.w600, ls: 0.8);
  static TextStyle get body => ts(13, C.text, height: 1.5);
  static TextStyle get caption => ts(11, C.textMuted);
}

/// Shared button style (blue primary, or a tonal variant for secondary actions).
ButtonStyle appButtonStyle({
  Color color = C.blue,
  bool tonal = false,
  EdgeInsetsGeometry padding = const EdgeInsets.symmetric(
    horizontal: 16,
    vertical: 14,
  ),
  double radius = R.md,
}) {
  return ElevatedButton.styleFrom(
    backgroundColor: tonal ? a(color, 0.16) : color,
    foregroundColor: tonal ? color : Colors.white,
    disabledBackgroundColor: a(Colors.white, 0.06),
    disabledForegroundColor: a(Colors.white, 0.35),
    elevation: 0,
    shadowColor: Colors.transparent,
    surfaceTintColor: Colors.transparent,
    padding: padding,
    side: tonal ? BorderSide(color: a(color, 0.4)) : null,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
  );
}

class AppTheme {
  AppTheme._();

  static ThemeData dark() {
    return ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      fontFamily: kFontSans,
      fontFamilyFallback: kFontFallback,
      scaffoldBackgroundColor: C.navy,
      canvasColor: C.navy,
      colorScheme: const ColorScheme.dark(
        primary: C.blue,
        onPrimary: Colors.white,
        secondary: C.cyan,
        onSecondary: C.navy,
        surface: C.surface,
        onSurface: C.text,
        error: C.red,
      ),
      dividerTheme: const DividerThemeData(
        color: C.border,
        thickness: 1,
        space: 1,
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: C.cyan,
        selectionColor: a(C.blue, 0.35),
        selectionHandleColor: C.cyan,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(style: appButtonStyle()),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: C.textMuted,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(R.sm),
          ),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: C.surfaceHigh,
          borderRadius: BorderRadius.circular(R.sm),
          border: Border.all(color: C.glassBorder),
        ),
        textStyle: ts(12, C.text),
        waitDuration: const Duration(milliseconds: 400),
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrimColor: Color(0x99060D1A),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
    );
  }
}
