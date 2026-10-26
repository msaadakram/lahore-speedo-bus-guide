import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lahore_speedo_bus_guide/app/router.dart';
import 'package:lahore_speedo_bus_guide/app/theme/app_palette.dart';
import 'package:lahore_speedo_bus_guide/app/theme/app_theme.dart';
import 'package:lahore_speedo_bus_guide/app/theme/theme_controller.dart';
import 'package:lahore_speedo_bus_guide/core/storage/preferences_store.dart';
import 'package:lahore_speedo_bus_guide/data/repositories/journey_repository.dart';
import 'package:lahore_speedo_bus_guide/data/repositories/routes_repository.dart';
import 'package:lahore_speedo_bus_guide/data/repositories/stop_repository.dart';
import 'package:lahore_speedo_bus_guide/features/credits/credits_screen.dart';
import 'package:lahore_speedo_bus_guide/features/feedback/feedback_screen.dart';
import 'package:lahore_speedo_bus_guide/features/journey_detail/journey_detail_screen.dart';
import 'package:lahore_speedo_bus_guide/features/journey_results/journey_results_screen.dart';
import 'package:lahore_speedo_bus_guide/features/privacy/privacy_screen.dart';
import 'package:lahore_speedo_bus_guide/features/route_detail/route_detail_screen.dart';
import 'package:lahore_speedo_bus_guide/features/search/search_screen.dart';
import 'package:lahore_speedo_bus_guide/features/stop_detail/stop_detail_screen.dart';
import 'package:lahore_speedo_bus_guide/features/stop_picker/stop_picker_screen.dart';

/// Pins the app's maximum supported text scale across pushed screens, where
/// fixed Rows are most likely to regress into RenderFlex overflows.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await TestWidgetsFlutterBinding.instance.runAsync(() async {
      await RoutesRepository.instance.ensureLoaded();
      await StopRepository.instance.ensureLoaded();
    });
  });

  testWidgets('pushed screens render cleanly at the supported text scale', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(420, 900));
    tester.platformDispatcher.textScaleFactorTestValue = 1.4;
    addTearDown(() async {
      tester.platformDispatcher.clearTextScaleFactorTestValue();
      await tester.binding.setSurfaceSize(null);
    });

    final route = RoutesRepository.instance.routes.firstWhere(
      (route) => route.stops.length > 3,
    );
    final fromKey = route.stops.first.trim().toLowerCase();
    final toKey = route.stops.last.trim().toLowerCase();
    final journeys = JourneyRepository.findJourneys(
      fromKey,
      toKey,
      limit: 1,
      now: DateTime(2026, 1, 1, 9),
    );
    expect(journeys, isNotEmpty);

    final screens = <({String name, Widget screen})>[
      (
        name: 'route detail',
        screen: RouteDetailScreen(
          args: RouteDetailArgs(routeId: route.id, color: route.color),
        ),
      ),
      (
        name: 'stop detail',
        screen: StopDetailScreen(
          args: StopDetailArgs(stopName: route.stops.first),
        ),
      ),
      (
        name: 'journey results',
        screen: JourneyResultsScreen(
          args: JourneyResultsArgs(
            fromKey: fromKey,
            toKey: toKey,
            fromName: route.stops.first,
            toName: route.stops.last,
          ),
        ),
      ),
      (
        name: 'journey detail',
        screen: JourneyDetailScreen(
          args: JourneyDetailArgs(journey: journeys.first),
        ),
      ),
      (name: 'search', screen: const SearchScreen()),
      (name: 'stop picker', screen: const StopPickerScreen(mode: 'from')),
      (name: 'credits', screen: const CreditsScreen()),
      (name: 'feedback', screen: const FeedbackScreen()),
      (name: 'privacy', screen: const PrivacyPolicyScreen()),
    ];

    for (final entry in screens) {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            preferencesStoreProvider.overrideWithValue(
              MemoryPreferencesStore(),
            ),
          ],
          child: AppPaletteScope(
            palette: AppPalette.light,
            isDark: false,
            preference: ThemePreference.system,
            setThemePreference: (_) {},
            child: MaterialApp(theme: AppTheme.light(), home: entry.screen),
          ),
        ),
      );
      for (var i = 0; i < 15; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(
        tester.takeException(),
        isNull,
        reason: '${entry.name} must not overflow at 1.4× text scale',
      );
    }
  });
}
