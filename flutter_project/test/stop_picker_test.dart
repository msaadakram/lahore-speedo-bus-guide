import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lahore_speedo_bus_guide/app/theme/app_palette.dart';
import 'package:lahore_speedo_bus_guide/app/theme/theme_controller.dart';
import 'package:lahore_speedo_bus_guide/core/storage/preferences_store.dart';
import 'package:lahore_speedo_bus_guide/data/repositories/stop_repository.dart';
import 'package:lahore_speedo_bus_guide/features/stop_picker/stop_picker_screen.dart';

/// Regression test for a bug that only showed up on a real device: the stop
/// picker rendered "0 All Stops / No stops found" because the stop index was
/// never built before the screen asked for it.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpPicker(WidgetTester tester) async {
    await tester.runAsync(() => StopRepository.instance.ensureLoaded());
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
          child: const MaterialApp(home: StopPickerScreen(mode: 'from')),
        ),
      ),
    );
    for (var i = 0; i < 25; i++) {
      await tester.pump(const Duration(milliseconds: 80));
    }
  }

  testWidgets('stop picker lists real stops from the bundled dataset', (
    tester,
  ) async {
    await pumpPicker(tester);

    // The empty state must NOT be shown.
    expect(find.text('No stops found'), findsNothing);

    // The counter must report the real number of stops.
    final allStops = StopRepository.instance.allStops;
    expect(allStops.length, greaterThan(300));
    expect(find.text('${allStops.length} All Stops'), findsOneWidget);

    // Real stop names must be rendered.
    expect(find.text(allStops.first.name), findsWidgets);
  });

  testWidgets('stop picker filters as you type', (tester) async {
    await pumpPicker(tester);
    expect(find.text('No stops found'), findsNothing);

    await tester.enterText(find.byType(TextField).first, 'Jinnah');
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 80));
    }

    expect(find.text('No stops found'), findsNothing);
    expect(find.textContaining('Jinnah'), findsWidgets);
  });
}
