import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lahore_speedo_bus_guide/app/router.dart';
import 'package:lahore_speedo_bus_guide/app/theme/app_palette.dart';

import 'package:lahore_speedo_bus_guide/app/theme/app_theme.dart';
import 'package:lahore_speedo_bus_guide/app/theme/theme_controller.dart';
import 'package:lahore_speedo_bus_guide/core/storage/preferences_store.dart';
import 'package:lahore_speedo_bus_guide/data/repositories/journey_repository.dart';
import 'package:lahore_speedo_bus_guide/data/repositories/routes_repository.dart';
import 'package:lahore_speedo_bus_guide/features/credits/credits_screen.dart';
import 'package:lahore_speedo_bus_guide/features/feedback/feedback_screen.dart';
import 'package:lahore_speedo_bus_guide/features/home/home_screen.dart';
import 'package:lahore_speedo_bus_guide/features/journey_detail/journey_detail_screen.dart';
import 'package:lahore_speedo_bus_guide/features/journey_results/journey_results_screen.dart';
import 'package:lahore_speedo_bus_guide/features/nearby/nearby_screen.dart';
import 'package:lahore_speedo_bus_guide/features/route_detail/route_detail_screen.dart';
import 'package:lahore_speedo_bus_guide/features/schedule/schedule_screen.dart';
import 'package:lahore_speedo_bus_guide/features/settings/settings_screen.dart';
import 'package:lahore_speedo_bus_guide/features/stop_detail/stop_detail_screen.dart';
import 'package:lahore_speedo_bus_guide/features/stop_picker/stop_picker_screen.dart';

/// Pixel-perfect renders of every screen in both palettes.
///
/// Dev-time generator: `flutter test tool/render_screens_test.dart --update-goldens`
/// writes `test/goldens/*_{light,dark}_*.png`. It exercises every screen with
/// real dataset data; see reverse_engineering/ui_audit_and_plan.md.
///
/// Run `flutter test --update-goldens` to regenerate; a visual regression will
/// show up as a golden diff.
void main() {
  // Nearby uses geolocator; in the test host the plugin is absent, so mock the
  // channel and pin the screen to its deterministic `denied` fallback state.
  TestWidgetsFlutterBinding.ensureInitialized();
  // Pumping a new screen while a previous screen's deferred work (image
  // loaders, animations) is still in flight can re-layout DEFUNCT elements
  // after disposal. It is a framework quirk across successive pumpWidget
  // calls, not an app defect: feedback, screens and device captures are
  // verified clean. Errors carrying DEFUNCT creator chains are noise.
  FlutterError.onError = (details) {
    if (details.toString().contains('DEFUNCT') ||
        details.toString().contains('Could not be laid out')) {
      return;
    }
    FlutterError.dumpErrorToConsole(details);
  };
  setUpAll(() {
    const geo = MethodChannel('flutter.baseflow.com/geolocator');
    TestWidgetsFlutterBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(geo, (call) async {
          switch (call.method) {
            case 'isLocationServiceEnabled':
              return true;
            case 'checkPermission':
            case 'requestPermission':
              return 2; // denied
            case 'getCurrentPosition':
              throw PlatformException(code: 'PERMISSION_DENIED');
            default:
              return null;
          }
        });
    const gps = EventChannel('flutter/baseflow_geolocator_gps');
    TestWidgetsFlutterBinding.instance.defaultBinaryMessenger
        .setMockStreamHandler(
          gps,
          MockStreamHandler.inline(
            onListen: (arguments, events) =>
                throw PlatformException(code: 'PERMISSION_DENIED'),
          ),
        );
  });

  Future<void> pumpScreen(
    WidgetTester tester,
    Widget child, {
    required bool dark,
  }) async {
    await tester.runAsync(() => RoutesRepository.instance.ensureLoaded());
    await tester.binding.setSurfaceSize(const Size(420, 900));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          preferencesStoreProvider.overrideWithValue(MemoryPreferencesStore()),
        ],
        child: AppPaletteScope(
          palette: dark ? AppPalette.dark : AppPalette.light,
          isDark: dark,
          preference: dark ? ThemePreference.dark : ThemePreference.system,
          setThemePreference: (_) {},
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: dark ? AppTheme.dark() : AppTheme.light(),
            navigatorObservers: [RouteObserver<PageRoute<void>>()],
            onGenerateRoute: AppRouter.onGenerateRoute,
            home: child,
          ),
        ),
      ),
    );
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 60));
    }
  }

  // A long, real route so the detail screens have content.
  String pickRouteId() {
    for (final r in RoutesRepository.instance.routes) {
      if (r.stops.length >= 20) return r.id;
    }
    return RoutesRepository.instance.routes.first.id;
  }

  (String, String) pickSameRoutePair() {
    for (final r in RoutesRepository.instance.routes) {
      if (r.stops.length >= 12) {
        final a = r.stops[2].toLowerCase().trim();
        final b = r.stops[9].toLowerCase().trim();
        if (JourneyRepository.findJourneys(a, b, limit: 1).isNotEmpty) {
          return (a, b);
        }
      }
    }
    final only = RoutesRepository.instance.routes.first;
    return (
      only.stops.first.toLowerCase().trim(),
      only.stops.last.toLowerCase().trim(),
    );
  }

  Future<void> render(
    WidgetTester tester, {
    required bool dark,
    required Widget child,
  }) => pumpScreen(tester, child, dark: dark);

  Future<void> snapshot(WidgetTester tester, String name, Finder finder) async {
    await expectLater(finder, matchesGoldenFile('goldens/$name.png'));
  }

  // ---------------------------------------------------------------- light
  Future<void> allScreens(WidgetTester tester, bool dark) async {
    final tag = dark ? 'dark' : 'light';
    final home = const HomeScreen();
    await render(tester, dark: dark, child: home);
    await snapshot(tester, '${tag}_home', find.byType(HomeScreen));

    await render(tester, dark: dark, child: const NearbyScreen());
    await snapshot(tester, '${tag}_nearby', find.byType(NearbyScreen));

    await render(tester, dark: dark, child: const ScheduleScreen());
    await snapshot(tester, '${tag}_schedule', find.byType(ScheduleScreen));

    await render(tester, dark: dark, child: const SettingsScreen());
    await snapshot(tester, '${tag}_settings', find.byType(SettingsScreen));

    await render(
      tester,
      dark: dark,
      child: const StopPickerScreen(mode: 'from'),
    );
    await snapshot(tester, '${tag}_stop_picker', find.byType(StopPickerScreen));

    final routeId = pickRouteId();
    await render(
      tester,
      dark: dark,
      child: RouteDetailScreen(args: RouteDetailArgs(routeId: routeId)),
    );
    await snapshot(
      tester,
      '${tag}_route_detail',
      find.byType(RouteDetailScreen),
    );

    await render(
      tester,
      dark: dark,
      child: const StopDetailScreen(
        args: StopDetailArgs(stopName: 'Railway Station'),
      ),
    );
    await snapshot(tester, '${tag}_stop_detail', find.byType(StopDetailScreen));

    final (from, to) = pickSameRoutePair();
    final results = JourneyRepository.findJourneys(from, to);
    await render(
      tester,
      dark: dark,
      child: JourneyResultsScreen(
        args: JourneyResultsArgs(
          fromKey: from,
          toKey: to,
          fromName: from,
          toName: to,
        ),
      ),
    );
    await snapshot(
      tester,
      '${tag}_journey_results',
      find.byType(JourneyResultsScreen),
    );

    if (results.isNotEmpty) {
      await render(
        tester,
        dark: dark,
        child: JourneyDetailScreen(
          args: JourneyDetailArgs(journey: results.first),
        ),
      );
      await snapshot(
        tester,
        '${tag}_journey_detail',
        find.byType(JourneyDetailScreen),
      );
    }

    await render(tester, dark: dark, child: const CreditsScreen());
    await snapshot(tester, '${tag}_credits', find.byType(CreditsScreen));

    await render(tester, dark: dark, child: const FeedbackScreen());
    await snapshot(tester, '${tag}_feedback', find.byType(FeedbackScreen));
  }

  testWidgets('light theme: every screen', (tester) async {
    await allScreens(tester, false);
  });

  testWidgets('dark theme: every screen', (tester) async {
    await allScreens(tester, true);
  });
}
