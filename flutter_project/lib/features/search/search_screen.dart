import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/router.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_tokens.dart';
import '../../data/models/route.dart';
import '../../data/repositories/routes_provider.dart';
import '../../shared/widgets/app_icons.dart';
import '../../shared/widgets/app_widgets.dart';
import '../../shared/widgets/route_widgets.dart';

/// SearchScreen — instant, offline search across every route and stop.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(routesDataProvider);
    final routes = data.valueOrNull?.routes ?? const <BusRoute>[];
    final query = _query.trim().toLowerCase();
    final results = query.isEmpty
        ? routes
        : routes.where((route) => _matches(route, query)).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppCanvas(
        child: Column(
          children: [
            AppPageHeader(
              title: 'Search Routes',
              subtitle: _query.isEmpty
                  ? 'Search by route name or stop name'
                  : '${results.length} ${results.length == 1 ? 'result' : 'results'}',
              onBack: () => Navigator.of(context).pop(),
              bottomRadius: 36,
              bottom: TextField(
                controller: _controller,
                autofocus: true,
                onChanged: (value) => setState(() => _query = value),
                cursorColor: Colors.white,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: Tokens.fontBase,
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  hintText: 'Search by route name or stop name ...',
                  hintStyle: const TextStyle(
                    color: Color(0xB3FFFFFF),
                    fontSize: Tokens.fontBase,
                  ),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: .16),
                  prefixIcon: const Icon(
                    AppIcons.magnify,
                    size: 19,
                    color: Color(0xCCFFFFFF),
                  ),
                  prefixIconConstraints: const BoxConstraints(
                    minWidth: 44,
                    minHeight: 44,
                  ),
                  suffixIcon: _query.isEmpty
                      ? null
                      : AppPressable(
                          onPressed: () {
                            _controller.clear();
                            setState(() => _query = '');
                          },
                          semanticLabel: 'Clear search',
                          borderless: true,
                          rippleColor: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          child: const Icon(
                            AppIcons.close,
                            size: 17,
                            color: Color(0xCCFFFFFF),
                          ),
                        ),
                  suffixIconConstraints: const BoxConstraints(
                    minWidth: 42,
                    minHeight: 42,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(Tokens.shapeMd),
                    borderSide: const BorderSide(color: Color(0x40FFFFFF)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(Tokens.shapeMd),
                    borderSide: const BorderSide(color: Color(0x40FFFFFF)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(Tokens.shapeMd),
                    borderSide: const BorderSide(
                      color: Color(0x99FFFFFF),
                      width: 2,
                    ),
                  ),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: Tokens.spaceSm,
                    vertical: 14,
                  ),
                ),
              ),
            ),
            Expanded(
              child: _query.isEmpty
                  ? const EmptyState(
                      icon: AppIcons.magnify,
                      title: 'Start typing to search',
                      message: 'Search all Speedo, Metro, Orange Line and Electric routes.',
                    )
                  : results.isEmpty
                  ? const EmptyState(
                      icon: AppIcons.search,
                      title: 'No routes found',
                      message: 'Try another route, stop or destination name.',
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
                      itemBuilder: (context, index) {
                        final route = results[index];
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

  bool _matches(BusRoute route, String query) {
    if (route.name.toLowerCase().contains(query)) return true;
    if (route.stationAddress.toLowerCase().contains(query)) return true;
    if (route.id.toLowerCase().contains(query)) return true;
    if ((route.frequency ?? '').toLowerCase().contains(query)) return true;
    if (route.category.toLowerCase().contains(query)) return true;
    return route.stops.any((stop) => stop.toLowerCase().contains(query));
  }
}
