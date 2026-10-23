/// Design tokens recovered verbatim from the original app
/// (`theme/tokens.ts`, Metro module 570) and extended with the shape and
/// elevation language of the reference artwork.
abstract final class Tokens {
  const Tokens._();

  // ------------------------------------------------------------ SPACING (verbatim)
  static const double spaceXs = 4;
  static const double spaceSm = 8;
  static const double spaceMd = 16;
  static const double spaceLg = 24;
  static const double spaceXl = 32;
  static const double spaceXxl = 48;

  // -------------------------------------------------------- FONT_SIZE (verbatim)
  static const double fontXs = 10;
  static const double fontSm = 12;
  static const double fontMd = 14;
  static const double fontBase = 16;
  static const double fontLg = 18;
  static const double fontXl = 22;
  static const double fontXxl = 28;
  static const double fontXxxl = 36;

  // -------------------------------------------------- BORDER_RADIUS (verbatim)
  static const double radiusSm = 6;
  static const double radiusMd = 10;
  static const double radiusLg = 16;
  static const double radiusXl = 24;
  static const double radiusFull = 999;

  // --------------------------------------------------------------- shape language
  // The reference artwork uses very soft, chunky, organic forms. These are the
  // rounded values that reproduce that feel.
  static const double shapeSm = 12;
  static const double shapeMd = 18;
  static const double shapeLg = 24;
  static const double shapeXl = 32;
  static const double shapePill = 999;

  // --------------------------------------------------------------- icon sizes
  static const double iconSmall = 16;
  static const double iconMedium = 20;
  static const double icon = 24;
  static const double iconLarge = 32;
}
