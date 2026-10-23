import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/router.dart';
import '../../app/theme/app_palette.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_tokens.dart';
import '../../data/models/route.dart';
import '../../data/repositories/routes_provider.dart';
import '../../shared/widgets/app_icons.dart';
import '../../shared/widgets/app_widgets.dart';
import '../../shared/widgets/route_widgets.dart';

/// SearchScreen (Metro module 1071).
///
/// The original matches case-insensitively on route name, station address, id,
/// stop names, frequency and category, in `ROUTES` order (no sort, no debounce).
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final palette = AppPaletteScope.paletteOf(context);
    final insets = MediaQuery.paddingOf(context);
    final data = ref.watch(routesDataProvider);
    final routes = data.valueOrNull?.routes ?? const <BusRoute>[];
    final q = _query.toLowerCase();
    final results = q.isEmpty
        ? routes
        : routes.where((r) => _matches(r, q)).toList();

    return Scaffold(
      body: ColoredBox(
        color: palette.background,
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: palette.heroGradient,
                boxShadow: palette.softShadow,
              ),
              padding: EdgeInsets.only(
                left: Tokens.spaceMd,
                right: Tokens.spaceMd,
                top: insets.top + Tokens.spaceSm,
                bottom: Tokens.spaceSm,
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      AppPressable(
                        onPressed: () => Navigator.of(context).pop(),
                        borderless: true,
                        rippleColor: Colors.white,
                        child: const Padding(
                          padding: EdgeInsets.all(8),
                          child: Icon(
                            AppIcons.arrowLeft,
                            size: 24,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: Tokens.spaceSm),
                      Expanded(
                        child: TextField(
                          autofocus: true,
                          onChanged: (v) => setState(() => _query = v),
                          cursorColor: Colors.white,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: Tokens.fontBase,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Search by route name or stop name ...',
                            hintStyle: TextStyle(
                              color: Color(0xB3FFFFFF),
                              fontSize: Tokens.fontBase,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Tokens.spaceSm),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Search Routes',
                      style: TextStyle(
                        fontSize: Tokens.fontSm,
                        fontWeight: FontWeight.w600,
                        color: palette.text,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: _query.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            AppIcons.magnify,
                            size: 40,
                            color: palette.textSecondary,
                          ),
                          const SizedBox(height: Tokens.spaceMd),
                          Text(
                            'Start typing to search',
                            style: TextStyle(
                              color: palette.textSecondary,
                              fontSize: Tokens.fontBase,
                            ),
                          ),
                        ],
                      ),
                    )
                  : results.isEmpty
                  ? const EmptyState(
                      icon: AppIcons.search,
                      message: 'No routes found',
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.screen,
                        Tokens.spaceMd,
                        AppSpacing.screen,
                        Tokens.spaceXl,
                      ),
                      itemCount: results.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: Tokens.spaceSm),
                      itemBuilder: (context, i) {
                        final route = results[i];
                        return RouteRow(
                          route: route,
                          onTap: () => Navigator.of(context).pushNamed(
                            Routes.routeDetail,
                            arguments: RouteDetailArgs(
                              routeId: route.id,
                              color: route.color,
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

  bool _matches(BusRoute r, String q) {
    if (r.name.toLowerCase().contains(q)) return true;
    if (r.stationAddress.toLowerCase().contains(q)) return true;
    if (r.id.toLowerCase().contains(q)) return true;
    if ((r.frequency ?? '').toLowerCase().contains(q)) return true;
    if (r.category.toLowerCase().contains(q)) return true;
    return r.stops.any((s) => s.toLowerCase().contains(q));
  }
}
