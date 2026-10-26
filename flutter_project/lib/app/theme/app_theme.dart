import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_palette.dart';
import 'app_tokens.dart';
import 'app_typography.dart';

/// `AppTheme` bridges the recovered palette into a Material `ThemeData`.
class AppTheme {
  const AppTheme._();

  static ThemeData light() => _build(AppPalette.light, Brightness.light);
  static ThemeData dark() => _build(AppPalette.dark, Brightness.dark);

  static ThemeData _build(AppPalette p, Brightness brightness) {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: p.primary,
          brightness: brightness,
        ).copyWith(
          primary: p.primary,
          onPrimary: p.onPrimary,
          secondary: p.accent,
          onSecondary: p.primary,
          surface: p.card,
          onSurface: p.text,
          error: AppColors.error,
          outline: p.border,
        );

    final textTheme = AppTypography.textTheme(p.text, p.textSecondary);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: p.background,
      visualDensity: VisualDensity.standard,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      // The custom navigation bar paints its own elevated surface.
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: p.card,
        indicatorColor: p.primary.withValues(alpha: .16),
        elevation: 0,
        height: 74,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: Tokens.fontXs,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w800
                : FontWeight.w600,
            color: states.contains(WidgetState.selected)
                ? p.primary
                : p.textSecondary,
          ),
        ),
      ),
      canvasColor: p.background,
      cardColor: p.card,
      dividerColor: p.border,
      fontFamily: AppTypography.fontFamily,
      textTheme: textTheme,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        systemOverlayStyle: SystemUiOverlayStyle.light,
        backgroundColor: Colors.transparent,
        foregroundColor: p.text,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      iconTheme: IconThemeData(color: p.text, size: Tokens.icon),
      dividerTheme: DividerThemeData(thickness: 1, color: p.border, space: 1),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? p.onPrimary
              : Colors.white,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? p.primaryBright
              : p.surfaceTint,
        ),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? p.primary : p.border,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.surfaceTint,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Tokens.shapeMd),
          borderSide: BorderSide(color: p.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Tokens.shapeMd),
          borderSide: BorderSide(color: p.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Tokens.shapeMd),
          borderSide: BorderSide(color: p.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Tokens.shapeMd),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Tokens.shapeMd),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        labelStyle: TextStyle(color: p.textSecondary, fontSize: 13),
        floatingLabelStyle: TextStyle(color: p.primary, fontSize: 12),
        helperStyle: TextStyle(color: p.textSecondary, fontSize: 11),
        errorStyle: const TextStyle(
          color: AppColors.error,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
        hintStyle: TextStyle(color: p.textSecondary.withValues(alpha: 0.7)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: p.primary,
          foregroundColor: p.onPrimary,
          minimumSize: const Size.fromHeight(54),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Tokens.shapePill),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.1,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: p.primary,
          foregroundColor: p.onPrimary,
          minimumSize: const Size.fromHeight(54),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Tokens.shapePill),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: p.primary,
          minimumSize: const Size.fromHeight(54),
          side: BorderSide(color: p.primary, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Tokens.shapePill),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: p.primary,
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.card,
        modalBackgroundColor: p.card,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(Tokens.shapeXl),
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: p.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Tokens.shapeXl),
        ),
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyMedium,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: p.text,
        contentTextStyle: TextStyle(color: p.card, fontSize: 13),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Tokens.shapeMd),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: p.primary,
        linearTrackColor: p.surfaceTint,
        circularTrackColor: p.surfaceTint.withValues(alpha: .68),
      ),
      listTileTheme: ListTileThemeData(iconColor: p.primary, textColor: p.text),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStatePropertyAll(
          p.primary.withValues(
            alpha: brightness == Brightness.dark ? .48 : .34,
          ),
        ),
        radius: const Radius.circular(Tokens.shapePill),
        thickness: const WidgetStatePropertyAll(4),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: p.surfaceTint,
        side: BorderSide(color: p.border),
        labelStyle: textTheme.labelLarge,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Tokens.shapePill),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: p.text,
          borderRadius: BorderRadius.circular(Tokens.shapeSm),
        ),
        textStyle: TextStyle(color: p.card, fontSize: 12),
      ),
    );
  }
}
