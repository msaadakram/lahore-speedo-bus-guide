/// Recovered layout metrics from the original React Native screens.
///
/// Every value is taken from the `StyleSheet` objects recovered in
/// `reverse_engineering/specs/*.md`.
abstract final class AppSpacing {
  const AppSpacing._();

  /// Screen horizontal padding (`paddingHorizontal: 16`).
  static const double screen = 16;

  /// A slightly wider screen gutter seen on detail screens (20).
  static const double screenWide = 20;

  /// Card inner padding (14–16).
  static const double card = 14;

  /// Card corner radius (12–16, 14 dominant).
  static const double cardRadius = 14;

  /// Pill / chip radius (20).
  static const double pill = 20;

  /// Button radius (10–12).
  static const double buttonRadius = 12;

  /// Input radius (12).
  static const double inputRadius = 12;

  /// Button height (40–48).
  static const double buttonHeight = 48;

  /// Input height (46–50).
  static const double inputHeight = 50;

  /// List item vertical padding (12–14).
  static const double listItem = 12;

  /// Gap between cards in a vertical list (8–12).
  static const double cardGap = 10;

  /// Section header bottom margin.
  static const double sectionGap = 8;

  /// Divider thickness.
  static const double divider = 1;

  /// Default icon size used by the tab bar (24).
  static const double icon = 24;

  /// Inline/adornment icon size (16).
  static const double iconSmall = 16;

  /// Large icon size (20).
  static const double iconMedium = 20;

  /// Header row height used by the in-page app bars.
  static const double appBarHeight = 56;
}
