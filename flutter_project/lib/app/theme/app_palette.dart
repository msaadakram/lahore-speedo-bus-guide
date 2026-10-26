import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'theme_controller.dart';

/// One palette instance. Mirrors the original app's `COLORS` / `DARK_COLORS`
/// pair, but rebuilt around the green artwork palette.
class AppPalette {
  const AppPalette({
    required this.primary,
    required this.primaryBright,
    required this.heroStart,
    required this.heroEnd,
    required this.accent,
    required this.accentSoft,
    required this.background,
    required this.backgroundAlt,
    required this.card,
    required this.surfaceTint,
    required this.border,
    required this.text,
    required this.textSecondary,
    required this.white,
    required this.black,
    required this.overlay,
    required this.shadow,
    required this.onPrimary,
  });

  final Color primary;
  final Color primaryBright;

  /// Upper/lower anchors for the hero gradient. They are deliberately darker
  /// than `accent` so white header copy keeps AA contrast in both themes.
  final Color heroStart;
  final Color heroEnd;
  final Color accent;
  final Color accentSoft;
  final Color background;
  final Color backgroundAlt;
  final Color card;
  final Color surfaceTint;
  final Color border;
  final Color text;
  final Color textSecondary;
  final Color white;
  final Color black;
  final Color overlay;
  final Color shadow;
  final Color onPrimary;

  static const light = AppPalette(
    primary: AppColors.forest,
    primaryBright: AppColors.grass,
    heroStart: AppColors.forest,
    heroEnd: AppColors.forestDeep,
    accent: AppColors.lime,
    accentSoft: AppColors.limePale,
    background: AppColors.canvasTop,
    backgroundAlt: AppColors.canvasBottom,
    card: AppColors.card,
    surfaceTint: AppColors.surfaceTint,
    border: AppColors.border,
    text: AppColors.text,
    textSecondary: AppColors.textSecondary,
    white: AppColors.white,
    black: AppColors.black,
    overlay: Color(0x8A101808),
    shadow: Color(0x1F3B7306),
    onPrimary: AppColors.white,
  );

  static const dark = AppPalette(
    primary: AppColors.primaryDark,
    primaryBright: AppColors.grass,
    heroStart: AppColors.moss,
    heroEnd: AppColors.forestDeep,
    accent: AppColors.lime,
    accentSoft: Color(0xFF3E4C1C),
    background: AppColors.canvasTopDark,
    backgroundAlt: AppColors.canvasBottomDark,
    card: AppColors.cardDark,
    surfaceTint: AppColors.surfaceTintDark,
    border: AppColors.borderDark,
    text: AppColors.textDark,
    textSecondary: AppColors.textSecondaryDark,
    white: AppColors.white,
    black: AppColors.black,
    overlay: Color(0xB3000000),
    shadow: Color(0x66000000),
    onPrimary: AppColors.forestDeep,
  );

  /// The signature vertical gradient. Both anchors are deep forest tones so
  /// white header copy keeps AA contrast in light and dark mode.
  LinearGradient get heroGradient => LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [heroStart, heroEnd],
  );

  /// Soft two-stop canvas gradient.
  LinearGradient get canvasGradient => LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [background, backgroundAlt],
  );

  /// The deep, shadowed band used behind dense content.
  LinearGradient get groundGradient => LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [accentSoft, accent, primary],
    stops: const [0.0, 0.45, 1.0],
  );

  /// Soft, diffuse, green-tinted shadow - the hallmark of the reference art.
  List<BoxShadow> get softShadow => [
    BoxShadow(
      color: shadow,
      blurRadius: 22,
      offset: const Offset(0, 8),
      spreadRadius: -4,
    ),
  ];

  List<BoxShadow> get liftedShadow => [
    BoxShadow(
      color: shadow,
      blurRadius: 30,
      offset: const Offset(0, 14),
      spreadRadius: -6,
    ),
    BoxShadow(
      color: shadow.withValues(alpha: 0.45),
      blurRadius: 8,
      offset: const Offset(0, 3),
    ),
  ];

  /// "Rs. 25"
  String fareText(String fare) => 'Rs. $fare';
}

/// Inherited widget exposing the active palette, mirroring the original
/// `ThemeContext` (`{ colors, isDark, toggleTheme, preference, setThemePreference }`).
class AppPaletteScope extends InheritedWidget {
  const AppPaletteScope({
    required this.palette,
    required this.isDark,
    required this.preference,
    required this.setThemePreference,
    required super.child,
    super.key,
  });

  final AppPalette palette;
  final bool isDark;
  final ThemePreference preference;
  final ValueChanged<ThemePreference> setThemePreference;

  static AppPaletteScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppPaletteScope>();
    assert(scope != null, 'AppPaletteScope not found in context');
    return scope!;
  }

  static AppPalette paletteOf(BuildContext context) => of(context).palette;

  @override
  bool updateShouldNotify(AppPaletteScope oldWidget) =>
      palette != oldWidget.palette ||
      isDark != oldWidget.isDark ||
      preference != oldWidget.preference;
}
