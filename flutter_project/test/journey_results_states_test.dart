import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lahore_speedo_bus_guide/app/router.dart';
import 'package:lahore_speedo_bus_guide/app/theme/app_palette.dart';
import 'package:lahore_speedo_bus_guide/app/theme/app_theme.dart';
import 'package:lahore_speedo_bus_guide/app/theme/theme_controller.dart';
import 'package:lahore_speedo_bus_guide/core/storage/preferences_store.dart';
import 'package:lahore_speedo_bus_guide/data/repositories/routes_provider.dart';
import 'package:lahore_speedo_bus_guide/data/repositories/routes_repository.dart';
import 'package:lahore_speedo_bus_guide/data/repositories/stop_repository.dart';
import 'package:lahore_speedo_bus_guide/features/journey_results/journey_results_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late JourneyResultsArgs args;

  setUpAll(() async {
    await testerRootBundleLoad();
    final route = RoutesRepository.instance.routes.firstWhere(
      (route) => route.stops.length > 3,
    );
    args = JourneyResultsArgs(
      fromKey: route.stops.first.trim().toLowerCase(),
      toKey: route.stops.last.trim().toLowerCase(),
      fromName: route.stops.first,
      toName: route.stops.last,
    );
  });

  Future<void> pumpScreen(
    WidgetTester tester,
    Future<RoutesData> Function() loader,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          preferencesStoreProvider.overrideWithValue(MemoryPreferencesStore()),
          routesDataProvider.overrideWith((ref) => loader()),
        ],
        child: AppPaletteScope(
          palette: AppPalette.light,
          isDark: false,
          preference: ThemePreference.system,
          setThemePreference: (_) {},
          child: MaterialApp(
            theme: AppTheme.light(),
            home: JourneyResultsScreen(args: args),
          ),
        ),
      ),
    );
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  testWidgets('journey results recover from a dataset load failure', (
    tester,
  ) async {
    var attempts = 0;

    Future<RoutesData> failingFirstTime() async {
      attempts++;
      if (attempts == 1) {
        throw StateError('dataset unavailable');
      }
      await RoutesRepository.instance.ensureLoaded();
      return RoutesData(
        routes: RoutesRepository.instance.routes,
        categories: RoutesRepository.instance.categories,
        stops: RoutesRepository.instance.stops,
      );
    }

    await pumpScreen(tester, failingFirstTime);

    expect(find.text('Route data unavailable'), findsWidgets);
    expect(find.text('Retry'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    await tester.tap(find.text('Retry'));
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(attempts, 2);
    expect(find.text('Route data unavailable'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.textContaining('route'), findsWidgets);
    expect(find.text('No route found'), findsNothing);
  });
}

/// Loads the real bundled asset outside the fake async clock.
Future<void> testerRootBundleLoad() async {
  await TestWidgetsFlutterBinding.instance.runAsync(() async {
    await RoutesRepository.instance.ensureLoaded();
    await StopRepository.instance.ensureLoaded();
  });
}
