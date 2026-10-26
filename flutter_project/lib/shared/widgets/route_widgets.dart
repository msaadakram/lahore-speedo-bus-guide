import 'package:flutter/material.dart';

import '../../app/theme/app_palette.dart';
import '../../app/theme/app_tokens.dart';
import '../../data/models/route.dart';
import 'app_icons.dart';
import 'app_widgets.dart';

/// `renderBusIcon(category)` — maps a route category to its artwork.
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

/// Small translucent chip used in the Home hero.
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
    const fg = Color(0xF2FFFFFF);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Tokens.spaceSm,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .16),
        borderRadius: BorderRadius.circular(Tokens.shapePill),
        border: Border.all(color: Colors.white.withValues(alpha: .18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Icon(icon, size: 13, color: fg),
            )
          else if (asset != null)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Image.asset(
                asset!,
                width: 13,
                height: 13,
                fit: BoxFit.contain,
              ),
            ),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: fg,
                fontSize: Tokens.fontSm,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
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
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(Tokens.shapePill),
        border: Border.all(color: color.withValues(alpha: .28)),
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
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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
      borderRadius: BorderRadius.circular(Tokens.shapeXl),
      child: Container(
        padding: const EdgeInsets.all(Tokens.spaceMd),
        decoration: BoxDecoration(
          color: palette.card,
          borderRadius: BorderRadius.circular(Tokens.shapeXl),
          border: Border.all(color: palette.border),
          boxShadow: palette.softShadow,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: color.withValues(alpha: .14),
                borderRadius: BorderRadius.circular(Tokens.shapeMd),
                border: Border.all(color: color.withValues(alpha: .30)),
              ),
              child: Center(
                child: BusIcon(
                  category: route.category,
                  size: 30,
                  color: color,
                ),
              ),
            ),
            const SizedBox(width: Tokens.spaceMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    route.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: Tokens.fontMd,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.1,
                      color: palette.text,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    route.stationAddress,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: Tokens.fontSm,
                      height: 1.35,
                      color: palette.textSecondary,
                    ),
                  ),
                  const SizedBox(height: Tokens.spaceSm),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      _RouteMetaChip(
                        icon: AppIcons.stop,
                        label: '${route.stops.length} stops',
                      ),
                      if (route.frequency != null)
                        _RouteMetaChip(
                          icon: AppIcons.clock,
                          label: route.frequency!,
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: Tokens.spaceSm),
            Icon(AppIcons.chevronRight, size: 20, color: palette.textSecondary),
          ],
        ),
      ),
    );
  }
}

class _RouteMetaChip extends StatelessWidget {
  const _RouteMetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = AppPaletteScope.paletteOf(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: palette.surfaceTint,
        borderRadius: BorderRadius.circular(Tokens.shapePill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: palette.textSecondary),
          const SizedBox(width: 3),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: Tokens.fontXs,
                fontWeight: FontWeight.w700,
                color: palette.textSecondary,
              ),
            ),
          ),
        ],
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
      borderRadius: BorderRadius.circular(Tokens.shapePill),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        width: expanded ? double.infinity : null,
        padding: const EdgeInsets.symmetric(
          horizontal: Tokens.spaceMd,
          vertical: Tokens.spaceSm,
        ),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.white.withValues(alpha: .14),
          borderRadius: BorderRadius.circular(Tokens.shapePill),
          border: Border.all(
            color: isActive
                ? Colors.white.withValues(alpha: .78)
                : Colors.white.withValues(alpha: .18),
          ),
          boxShadow: isActive ? palette.softShadow : null,
        ),
        child: Row(
          mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
          children: [
            Image.asset(
              iconAsset,
              width: 22,
              height: 22,
              fit: BoxFit.contain,
              color: isActive ? color : Colors.white,
              errorBuilder: (_, _, _) => Icon(
                AppIcons.bus,
                size: 20,
                color: isActive ? color : Colors.white,
              ),
            ),
            const SizedBox(width: Tokens.spaceSm),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: Tokens.fontSm,
                  fontWeight: FontWeight.w800,
                  // Keep the label readable even when a route colour is low-
                  // contrast on the active white pill.
                  color: isActive ? palette.text : Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
