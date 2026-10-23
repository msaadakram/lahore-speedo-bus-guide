import 'package:flutter/material.dart';

import 'app_tokens.dart';

/// Typography rebuilt for the reference artwork's poster-like feel: chunky,
/// tightly-tracked headlines over a friendly, readable body.
abstract final class AppTypography {
  const AppTypography._();

  static const String fontFamily = 'Roboto';

  // Sizes, aliased from the recovered tokens.
  static const double fontXs = Tokens.fontXs;
  static const double fontSm = Tokens.fontSm;
  static const double fontMd = Tokens.fontMd;
  static const double fontBase = Tokens.fontBase;
  static const double fontLg = Tokens.fontLg;
  static const double fontXl = Tokens.fontXl;
  static const double fontXxl = Tokens.fontXxl;
  static const double fontXxxl = Tokens.fontXxxl;

  static const FontWeight w400 = FontWeight.w400;
  static const FontWeight w500 = FontWeight.w500;
  static const FontWeight w600 = FontWeight.w600;
  static const FontWeight w700 = FontWeight.w700;
  static const FontWeight w800 = FontWeight.w800;
  static const FontWeight w900 = FontWeight.w900;

  /// Negative tracking on the big headings gives the chunky poster look.
  static const double tightTracking = -0.6;
  static const double wideTracking = 0.8;

  static TextTheme textTheme(Color text, Color textSecondary) {
    return TextTheme(
      displaySmall: TextStyle(
        fontSize: fontXxl,
        fontWeight: w800,
        letterSpacing: tightTracking,
        height: 1.15,
        color: text,
      ),
      headlineMedium: TextStyle(
        fontSize: fontXl,
        fontWeight: w800,
        letterSpacing: tightTracking,
        height: 1.2,
        color: text,
      ),
      headlineSmall: TextStyle(
        fontSize: fontLg,
        fontWeight: w800,
        letterSpacing: -0.2,
        height: 1.25,
        color: text,
      ),
      titleLarge: TextStyle(
        fontSize: fontXl,
        fontWeight: w800,
        letterSpacing: tightTracking,
        color: text,
      ),
      titleMedium: TextStyle(
        fontSize: fontBase,
        fontWeight: w700,
        letterSpacing: -0.1,
        color: text,
      ),
      titleSmall: TextStyle(fontSize: fontMd, fontWeight: w600, color: text),
      bodyLarge: TextStyle(
        fontSize: fontBase,
        fontWeight: w500,
        height: 1.4,
        color: text,
      ),
      bodyMedium: TextStyle(
        fontSize: fontMd,
        fontWeight: w400,
        height: 1.45,
        color: text,
      ),
      bodySmall: TextStyle(
        fontSize: fontSm,
        fontWeight: w400,
        height: 1.4,
        color: textSecondary,
      ),
      labelLarge: TextStyle(
        fontSize: fontBase,
        fontWeight: w700,
        letterSpacing: 0.1,
        color: text,
      ),
      labelMedium: TextStyle(
        fontSize: fontSm,
        fontWeight: w700,
        letterSpacing: wideTracking,
        color: textSecondary,
      ),
      labelSmall: TextStyle(
        fontSize: fontXs,
        fontWeight: w600,
        color: textSecondary,
      ),
    );
  }
}
