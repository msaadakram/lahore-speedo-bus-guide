import 'package:flutter/material.dart';

/// Design tokens extracted from the reference artwork
/// (`downloads/bz4sqCqW.jpg`).
///
/// The source is a soft, organic 3D render: a grass-green vertical gradient
/// backdrop, chunky rounded forms, deep forest shadows and warm khaki accents.
/// Every colour below was sampled directly from that image.
abstract final class AppColors {
  const AppColors._();

  // ------------------------------------------------------------ signature green
  /// The dominant grass green of the backdrop - `#83A034` (6.7 % of the image).
  static const Color grass = Color(0xFF83A034);

  /// Slightly warmer sibling green - `#86A337`.
  static const Color grassWarm = Color(0xFF86A337);

  /// The bright leaf / lime highlight - `#9BB224`.
  static const Color lime = Color(0xFF9BB224);

  /// The pale lime at the very bottom of the gradient - `#BCD174`.
  static const Color limePale = Color(0xFFBCD174);

  // ------------------------------------------------------------- forest greens
  /// Deep grass shadow - `#133800`.
  static const Color forestDeep = Color(0xFF133800);

  /// Mid forest - `#3B7306`.
  static const Color forest = Color(0xFF3B7306);

  /// Olive foliage - `#6C8C07`.
  static const Color olive = Color(0xFF6C8C07);

  /// Shadowed foliage - `#224A04`.
  static const Color moss = Color(0xFF224A04);

  // ------------------------------------------------------- warm / neutral accents
  /// The khaki of the trousers - `#939747`.
  static const Color khaki = Color(0xFF939747);

  /// The warm brown of the hair and skin - `#957253`.
  static const Color clay = Color(0xFF957253);

  /// A pale warm sand for highlights - `#D9CBA8`.
  static const Color sand = Color(0xFFD9CBA8);

  // ------------------------------------------------------------------- surfaces
  /// Background top - a barely-green off-white.
  static const Color canvasTop = Color(0xFFF3F8E4);

  /// Background bottom - warm near-white.
  static const Color canvasBottom = Color(0xFFFBFDF4);

  /// Card surface.
  static const Color card = Color(0xFFFFFFFF);

  /// Hairline border, a very pale green.
  static const Color border = Color(0xFFDFEBC8);

  /// A tinted surface for chips and inset blocks.
  static const Color surfaceTint = Color(0xFFEDF3DC);

  /// Primary text - near-black with a green cast (`#1E2A10`).
  static const Color text = Color(0xFF1E2A10);

  /// Secondary text - muted olive (`#5F7346`).
  static const Color textSecondary = Color(0xFF5F7346);

  // -------------------------------------------------------------- dark surfaces
  static const Color canvasTopDark = Color(0xFF101808);
  static const Color canvasBottomDark = Color(0xFF1A2610);
  static const Color cardDark = Color(0xFF1E2A14);
  static const Color borderDark = Color(0xFF33421F);
  static const Color surfaceTintDark = Color(0xFF24311A);
  static const Color textDark = Color(0xFFEAF2DC);
  static const Color textSecondaryDark = Color(0xFFA9BA8C);
  static const Color primaryDark = Color(0xFF8FBB2A);

  // ------------------------------------------------------ category colours
  // The four transit categories keep distinct hues, tinted to sit inside the
  // artwork's green world.
  static const Color speedoColor = Color(0xFFC2410C);
  static const Color metroColor = Color(0xFF3F7FB5);
  static const Color orangeLineColor = Color(0xFFD98A0B);
  static const Color electricColor = Color(0xFF4C8B1B);

  // ------------------------------------------------------------------- accents
  static const Color success = Color(0xFF4C8B1B);
  static const Color error = Color(0xFFB3452B);
  static const Color warning = Color(0xFFC2871B);
  static const Color info = Color(0xFF3F7FB5);
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
}
