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

/// ScheduleScreen — category-aware timetable browser.
class ScheduleScreen extends ConsumerStatefulWidget {
  const ScheduleScreen({super.key});

  @override
  ConsumerState<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends ConsumerState<ScheduleScreen> {
  int _activeIndex = 0;

  void _select(int index) {
    final categories =
        ref.read(routesDataProvider).valueOrNull?.categories ??
        const <RouteCategory>[];
    if (index < 0 || index >= categories.length || index == _activeIndex) {
      return;
    }
    setState(() => _activeIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPaletteScope.paletteOf(context);
    final data = ref.watch(routesDataProvider);
    final categories = data.valueOrNull?.categories ?? const <RouteCategory>[];
    final activeIndex = categories.isEmpty
        ? 0
        : _activeIndex.clamp(0, categories.length - 1);
    final activeCategory = categories.isEmpty ? null : categories[activeIndex];
    final routes = activeCategory?.data ?? const <BusRoute>[];

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppCanvas(
        child: Column(
          children: [
            AppPageHeader(
              title: 'Lahore',
              subtitle: 'Bus Schedule',
              bottomRadius: 36,
              trailing: AppGlassButton(
                icon: AppIcons.magnify,
                tooltip: 'Search routes',
                onPressed: () => Navigator.of(context).pushNamed(Routes.search),
              ),
              bottom: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    clipBehavior: Clip.none,
                    child: Row(
                      children: [
                        for (var i = 0; i < categories.length; i++) ...[
                          if (i != 0) const SizedBox(width: Tokens.spaceSm),
                          CategoryTab(
                            expanded: false,
                            label: categories[i].label,
                            iconAsset:
                                'assets/images/${_assetFor(categories[i].key)}',
                            color: _parseColor(categories[i].color),
                            isActive: i == activeIndex,
                            onTap: () => _select(i),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: Tokens.spaceMd),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Tokens.spaceMd,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .18),
                      borderRadius: BorderRadius.circular(Tokens.shapePill),
                    ),
                    child: Text(
                      '${routes.length} ${routes.length == 1 ? 'Route' : 'Routes'}',
                      style: const TextStyle(
                        fontSize: Tokens.fontSm,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: data.isLoading
                  ? Center(
                      child: CircularProgressIndicator(color: palette.primary),
                    )
                  : categories.isEmpty
                  ? const EmptyState(
                      icon: AppIcons.bus,
                      title: 'Schedule unavailable',
                      message: 'The bundled route data could not be loaded. Please restart the app.',
                    )
                  : routes.isEmpty
                  ? const EmptyState(
                      icon: AppIcons.routes,
                      title: 'No routes found',
                      message:
                          'There are no routes in this category right now.',
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.screen,
                        Tokens.spaceMd,
                        AppSpacing.screen,
                        Tokens.spaceXl,
                      ),
                      itemCount: routes.length,
                      itemBuilder: (context, index) {
                        final route = routes[index];
                        return Padding(
                          padding: const EdgeInsets.only(
                            bottom: Tokens.spaceSm,
                          ),
                          child: RouteRow(
                            route: route,
                            accentColor: _parseColor(
                              activeCategory?.color ?? route.color,
                            ),
                            onTap: () => Navigator.of(context).pushNamed(
                              Routes.routeDetail,
                              arguments: RouteDetailArgs(
                                routeId: route.id,
                                color: activeCategory?.color ?? route.color,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
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
    return Color(int.tryParse(h, radix: 16) ?? 0xFF3B7306);
  }
}
