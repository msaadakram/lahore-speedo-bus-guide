import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lahore_speedo_bus_guide/app/theme/app_palette.dart';
import 'package:lahore_speedo_bus_guide/app/theme/theme_controller.dart';
import 'package:lahore_speedo_bus_guide/core/storage/preferences_store.dart';
import 'package:lahore_speedo_bus_guide/data/repositories/routes_repository.dart';
import 'package:lahore_speedo_bus_guide/features/home/home_screen.dart';
import 'package:lahore_speedo_bus_guide/features/schedule/schedule_screen.dart';
import 'package:lahore_speedo_bus_guide/features/settings/settings_screen.dart';

/// Render-pin goldens for the three core tabs.
///
/// The full every-screen render generator lives in
/// `tool/render_screens_test.dart`; this file pins the screens that ship in
/// CI as regression checks.
void main() {
  Future<void> pumpScreen(WidgetTester tester, Widget child) async {
    // The dataset lives in an asset; load it for real before rendering.
    await tester.runAsync(() => RoutesRepository.instance.ensureLoaded());
    await tester.binding.setSurfaceSize(const Size(420, 900));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          preferencesStoreProvider.overrideWithValue(MemoryPreferencesStore()),
        ],
        child: AppPaletteScope(
          palette: AppPalette.light,
          isDark: false,
          preference: ThemePreference.system,
          setThemePreference: (_) {},
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: ThemeData.light(useMaterial3: true),
            home: child,
          ),
        ),
      ),
    );
    // The app logo is an asynchronously decoded asset. Precache it outside
    // the fake clock so the Settings golden includes the real artwork.
    if (child is SettingsScreen) {
      await tester.runAsync(
        () => precacheImage(
          const AssetImage('assets/images/app_logo.png'),
          tester.element(find.byType(MaterialApp)),
        ),
      );
    }
    for (var i = 0; i < 25; i++) {
      await tester.pump(const Duration(milliseconds: 80));
    }
  }

  testWidgets('Home renders', (tester) async {
    await pumpScreen(tester, const HomeScreen());
    await expectLater(
      find.byType(HomeScreen),
      matchesGoldenFile('goldens/home_screen.png'),
    );
  });

  testWidgets('Schedule renders', (tester) async {
    await pumpScreen(tester, const ScheduleScreen());
    await expectLater(
      find.byType(ScheduleScreen),
      matchesGoldenFile('goldens/schedule_screen.png'),
    );
  });

  testWidgets('Settings renders', (tester) async {
    await pumpScreen(tester, const SettingsScreen());
    await expectLater(
      find.byType(SettingsScreen),
      matchesGoldenFile('goldens/settings_screen.png'),
    );
  });
}
