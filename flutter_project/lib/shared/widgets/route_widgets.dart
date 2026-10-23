import 'package:flutter/material.dart';

import '../../app/theme/app_palette.dart';
import '../../app/theme/app_tokens.dart';
import '../../data/models/route.dart';
import 'app_icons.dart';
import 'app_widgets.dart';

/// `renderBusIcon(category)` — maps a route category to its artwork.
/// Assets are the originals extracted from the APK.
class BusIcon extends StatelessWidget {
  const BusIcon({
    required this.category,
    this.size = 30,
    this.color,
    super.key,
  });

  final String category;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final asset = switch (category) {
      'speedo' => 'assets/images/speedo.jpg',
      'metro' => 'assets/images/metro.jpg',
      'orangeLine' => 'assets/images/orangeline.jpg',
      'electric' => 'assets/images/electric.jpg',
      _ => 'assets/images/bus.jpg',
    };
    return Image.asset(
      asset,
      width: size,
      height: size,
      fit: BoxFit.contain,
      color: color,
      errorBuilder: (_, _, _) => Icon(AppIcons.bus, size: size, color: color),
    );
  }
}

/// Category pill used on the Home header.
class TagChip extends StatelessWidget {
  const TagChip({
    required this.label,
    this.icon,
    this.asset,
    this.last = false,
    super.key,
  });

  final String label;
  final IconData? icon;
  final String? asset;
  final bool last;

  @override
  Widget build(BuildContext context) {
    const fg = Color(0xE6FFFFFF);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null)
          Padding(
            padding: const EdgeInsets.only(right: 5),
            child: Icon(icon, size: 14, color: fg),
          )
        else if (asset != null)
          Padding(
            padding: const EdgeInsets.only(right: 5),
            child: Image.asset(
              asset!,
              width: 13,
              height: 13,
              fit: BoxFit.contain,
            ),
          ),
        Text(
          label,
          style: const TextStyle(
            color: fg,
            fontSize: Tokens.fontSm,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (!last)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: Tokens.spaceXs),
            child: Text('·', style: TextStyle(color: Color(0x99FFFFFF))),
          ),
      ],
    );
  }
}

/// Route line chip — a colour dot plus the route name.
class RouteChip extends StatelessWidget {
  const RouteChip({required this.route, super.key});

  final BusRoute route;

  @override
  Widget build(BuildContext context) {
    final palette = AppPaletteScope.paletteOf(context);
    final color = _parseColor(route.color);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Tokens.spaceSm,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(Tokens.shapePill),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: Tokens.spaceXs),
          Text(
            route.name,
            style: TextStyle(
              fontSize: Tokens.fontSm,
              fontWeight: FontWeight.w700,
              color: palette.text,
            ),
          ),
        ],
      ),
    );
  }
}

Color _parseColor(String hex) {
  var h = hex.replaceAll('#', '');
  if (h.length == 6) h = 'FF$h';
  return Color(int.tryParse(h, radix: 16) ?? 0xFF000000);
}

/// Public helper so screens can tint text/decoration with route colours.
Color parseRouteColor(String hex) => _parseColor(hex);

/// Route row used by the Schedule and Search screens.
class RouteRow extends StatelessWidget {
  const RouteRow({
    required this.route,
    required this.onTap,
    this.accentColor,
    super.key,
  });

  final BusRoute route;
  final VoidCallback onTap;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final palette = AppPaletteScope.paletteOf(context);
    final color = accentColor ?? _parseColor(route.color);
    return AppPressable(
      onPressed: onTap,
      rippleColor: palette.primary,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: Tokens.spaceMd),
        decoration: BoxDecoration(
          color: palette.card,
          borderRadius: BorderRadius.circular(Tokens.shapeXl),
          border: Border.all(color: palette.border),
          boxShadow: palette.softShadow,
        ),
        child: Row(
          children: [
            const SizedBox(width: Tokens.spaceMd),
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.20),
                borderRadius: BorderRadius.circular(Tokens.radiusLg),
                border: Border.all(color: color.withValues(alpha: 0.30)),
              ),
              child: Center(
                child: BusIcon(
                  category: route.category,
                  size: 30,
                  color: color,
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(
                  left: Tokens.spaceMd,
                  right: Tokens.spaceMd,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      route.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: Tokens.fontMd,
                        fontWeight: FontWeight.w700,
                        color: palette.text,
                      ),
                    ),
                    if (route.frequency != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        route.frequency!,
                        style: TextStyle(
                          fontSize: Tokens.fontSm,
                          color: palette.textSecondary,
                        ),
                      ),
                    ],
                    const SizedBox(height: 3),
                    Text(
                      route.stationAddress,
                      style: TextStyle(
                        fontSize: Tokens.fontMd,
                        color: palette.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: Tokens.spaceMd),
              child: Icon(AppIcons.chevronRight, size: 20, color: palette.text),
            ),
          ],
        ),
      ),
    );
  }
}

/// Horizontal category selector used by the Schedule tab.
class CategoryTab extends StatelessWidget {
  const CategoryTab({
    this.expanded = true,
    required this.label,
    required this.iconAsset,
    required this.color,
    required this.isActive,
    required this.onTap,
    super.key,
  });

  final String label;
  final String iconAsset;
  final Color color;
  final bool isActive;
  final VoidCallback onTap;

  /// When true the tab expands to fill its parent row; pass false inside a
  /// horizontally scrollable strip so the pill hugs its content.
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final palette = AppPaletteScope.paletteOf(context);
  return AppPressable(
    onPressed: onTap,
      rippleColor: Colors.white,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Tokens.spaceXs,
          vertical: Tokens.spaceSm,
        ),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : const Color(0x26FFFFFF),
          borderRadius: BorderRadius.circular(Tokens.shapeLg),
          boxShadow: isActive ? palette.softShadow : null,
        ),
        child: Column(
          children: [
            Image.asset(
              iconAsset,
              width: 28,
              height: 28,
              fit: BoxFit.contain,
              color: isActive ? color : Colors.white,
              errorBuilder: (_, _, _) => Icon(
                AppIcons.bus,
                size: 24,
                color: isActive ? color : Colors.white,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: Tokens.fontSm,
                fontWeight: FontWeight.w700,
                color: isActive ? color : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
