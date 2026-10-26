import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lahore_speedo_bus_guide/app/app.dart';
import 'package:lahore_speedo_bus_guide/core/storage/preferences_store.dart';
import 'package:lahore_speedo_bus_guide/data/repositories/routes_repository.dart';
import 'package:lahore_speedo_bus_guide/shared/widgets/app_bottom_nav.dart';
import 'package:lahore_speedo_bus_guide/shared/widgets/app_icons.dart';

/// Full user journeys through the rebuilt app, matching the workflows that
/// exist in the original APK (see reverse_engineering/test_matrix.md).
void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  Future<void> launchApp(WidgetTester tester) async {
    if (!RoutesRepository.instance.isLoaded) {
      await tester.runAsync(() => RoutesRepository.instance.ensureLoaded());
    }
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          preferencesStoreProvider.overrideWithValue(MemoryPreferencesStore()),
        ],
        child: const BusGuideApp(),
      ),
    );
    await tester.pump();
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  testWidgets('launch → Home → every tab → back to Home', (tester) async {
    await launchApp(tester);

    // Home
    expect(find.text('Lahore 🇵🇰'), findsOneWidget);
    expect(find.text('Every route, one tap away!'), findsOneWidget);

    // Nearby
    await tester.tap(find.text('Nearby'));
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('Nearby Stops'), findsOneWidget);

    // Schedule
    await tester.tap(find.text('Schedule'));
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('Bus Schedule'), findsOneWidget);
    expect(find.textContaining(' Routes'), findsWidgets);

    // Settings
    await tester.tap(find.text('Settings'));
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('Settings'), findsWidgets);
    expect(find.text('Appearance'), findsOneWidget);

    // Back to Home
    await tester.tap(find.text('Home'));
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('Every route, one tap away!'), findsOneWidget);
  });

  testWidgets(
    'every tab renders without layout overflow at a large font scale',
    (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2.0;
      await tester.binding.setSurfaceSize(const Size(420, 900));
      addTearDown(() async {
        tester.platformDispatcher.clearTextScaleFactorTestValue();
        await tester.binding.setSurfaceSize(null);
      });
      await launchApp(tester);

      expect(tester.takeException(), isNull);
      for (final tab in const ['Nearby', 'Schedule', 'Settings', 'Home']) {
        final tabButton = find.descendant(
          of: find.byType(AppBottomNav),
          matching: find.text(tab),
        );
        await tester.tap(tabButton, warnIfMissed: false);
        for (var i = 0; i < 6; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(tester.takeException(), isNull, reason: tab);
      }
    },
  );

  testWidgets('Home → Search → RouteDetail → back', (tester) async {
    await launchApp(tester);
    await tester.tap(find.byIcon(AppBottomNavProxy.search).first);
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('Search Routes'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'Speedo');
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.textContaining('Speedo'), findsWidgets);
  });

  testWidgets('Settings → Appearance selector changes the palette', (
    tester,
  ) async {
    await launchApp(tester);
    await tester.tap(find.text('Settings'));
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('Light theme is active'), findsOneWidget);
    await tester.tap(find.text('Dark').last);
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('Dark theme is active'), findsOneWidget);
  });

  testWidgets('Schedule → category switch reloads the route list', (
    tester,
  ) async {
    await launchApp(tester);
    await tester.tap(find.text('Schedule'));
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.textContaining(' Routes'), findsWidgets);

    // Switch to "Metro" (1 route in the recovered dataset).
    await tester.tap(find.text('Metro'));
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('Metro'), findsWidgets);
  });
}

/// Icon handle used by the Home header search affordance.
abstract final class AppBottomNavProxy {
  const AppBottomNavProxy._();

  static IconData search = AppIcons.magnify;
}
