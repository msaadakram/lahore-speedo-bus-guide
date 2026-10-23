import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/router.dart';
import '../../app/theme/app_palette.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_tokens.dart';
import '../../data/models/category.dart';
import '../../data/models/route.dart';
import '../../data/repositories/routes_provider.dart';
import '../../shared/widgets/app_icons.dart';
import '../../shared/widgets/app_widgets.dart';
import '../../shared/widgets/route_widgets.dart';

/// ScheduleScreen (Metro module 714).
class ScheduleScreen extends ConsumerStatefulWidget {
  const ScheduleScreen({super.key});

  @override
  ConsumerState<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends ConsumerState<ScheduleScreen> {
  int _activeIndex = 0;
  List<RouteCategory> _categories = const [];
  List<BusRoute> _routes = const [];

  @override
  void initState() {
    super.initState();
    _sync();
  }

  void _sync({bool force = false}) {
    if (!mounted) return;
    if (_categories.isNotEmpty && !force) return;
    final categories =
        ref.read(routesDataProvider).valueOrNull?.categories ?? const [];
    if (categories.isEmpty) return;
    setState(() {
      _categories = categories;
      _routes = categories.first.data;
    });
  }

  RouteCategory get _active => _categories.isEmpty
      ? const RouteCategory(key: '', label: '', color: '#fc3b38', data: [])
      : _categories[_activeIndex];

  void _select(int index) {
    if (index == _activeIndex || _categories.isEmpty) return;
    setState(() {
      _activeIndex = index;
      _routes = _categories[index].data;
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPaletteScope.paletteOf(context);
    final insets = MediaQuery.paddingOf(context);
    final data = ref.watch(routesDataProvider);
    if (data.isLoading || data.valueOrNull == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    _sync();
    if (_categories.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final routes = _routes;

    return Scaffold(
      body: ColoredBox(
        color: palette.background,
        child: ListView(
          children: [
            // ------------------------------------------------------ header
            Container(
              decoration: BoxDecoration(
                gradient: palette.heroGradient,
                boxShadow: palette.softShadow,
              ),
              padding: const EdgeInsets.only(bottom: Tokens.spaceMd),
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.only(
                      left: AppSpacing.screen,
                      right: AppSpacing.screen,
                      top: insets.top + Tokens.spaceMd,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Lahore',
                              style: TextStyle(
                                fontSize: Tokens.fontXxl,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'Bus Schedule',
                              style: TextStyle(
                                fontSize: Tokens.fontLg,
                                fontWeight: FontWeight.w600,
                                color: Color(0xE6FFFFFF),
                              ),
                            ),
                          ],
                        ),
                        AppPressable(
                          onPressed: () =>
                              Navigator.of(context).pushNamed(Routes.search),
                          borderless: true,
                          rippleColor: palette.text,
                          child: Container(
                            padding: const EdgeInsets.all(Tokens.spaceSm),
                            decoration: BoxDecoration(
                              color: const Color(0x33FFFFFF),
                              borderRadius: BorderRadius.circular(
                                Tokens.radiusLg,
                              ),
                            ),
                            child: const Icon(
                              AppIcons.magnify,
                              size: 22,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: Tokens.spaceXl),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.screen,
                    ),
                    child: Row(
                      children: [
                        for (var i = 0; i < _categories.length; i++) ...[
                          if (i != 0) const SizedBox(width: 6),
                          CategoryTab(
                            expanded: false,
                            label: _categories[i].label,
                            iconAsset:
                                'assets/images/${_assetFor(_categories[i].key)}',
                            color: _parseColor(_categories[i].color),
                            isActive: i == _activeIndex,
                            onTap: () => _select(i),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                      left: AppSpacing.screen,
                      right: AppSpacing.screen,
                      top: Tokens.spaceMd,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${routes.length} Routes',
                          style: const TextStyle(
                            fontSize: Tokens.fontBase,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ------------------------------------------------------ list
            if (routes.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screen,
                  vertical: Tokens.spaceXl,
                ),
                child: Column(
                  children: [
                    Icon(
                      AppIcons.routes,
                      size: 20,
                      color: palette.textSecondary,
                    ),
                    const SizedBox(height: Tokens.spaceSm),
                    Text(
                      'No routes found in this category',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: Tokens.fontBase,
                        color: palette.textSecondary,
                      ),
                    ),
                  ],
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.only(top: Tokens.spaceSm),
                child: Column(
                  children: [
                    for (final route in routes)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.screen,
                          vertical: 4,
                        ),
                        child: RouteRow(
                          route: route,
                          accentColor: _parseColor(_active.color),
                          onTap: () => Navigator.of(context).pushNamed(
                            Routes.routeDetail,
                            arguments: RouteDetailArgs(
                              routeId: route.id,
                              color: _active.color,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            const SizedBox(height: Tokens.spaceXl),
          ],
        ),
      ),
    );
  }

  static String _assetFor(String key) => switch (key) {
    'speedo' => 'speedo.jpg',
    'metro' => 'metro.jpg',
    'orangeLine' => 'orangeline.jpg',
    'electric' => 'electric.jpg',
    _ => 'bus.jpg',
  };

  static Color _parseColor(String hex) {
    var h = hex.replaceAll('#', '');
    if (h.length == 6) h = 'FF$h';
    return Color(int.tryParse(h, radix: 16) ?? 0xFF000000);
  }
}
