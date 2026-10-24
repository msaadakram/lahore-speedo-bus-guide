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
import 'package:lahore_speedo_bus_guide/shared/widgets/app_icons.dart';
import 'package:lahore_speedo_bus_guide/shared/widgets/app_widgets.dart';

/// Widget-level smoke tests: they assert the *recovered* copy and the principal
/// interactive states of the screens, which is where a rebuild usually drifts.
void main() {
  setUpAll(() {
    // Load the bundled GTFS dataset outside the widget tree: `rootBundle`
    // performs real async work, which needs `runAsync`.
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  Future<void> pumpScreen(WidgetTester tester, Widget child) async {
    await tester.binding.setSurfaceSize(const Size(1280, 2400));
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
            theme: ThemeData.light(useMaterial3: true),
            home: child,
            routes: const {},
          ),
        ),
      ),
    );
    // `pumpAndSettle` never settles while a CircularProgressIndicator animates,
    // so settle with a bounded frame loop instead.
    for (var i = 0; i < 25; i++) {
      await tester.pump(const Duration(milliseconds: 80));
    }
    if (!RoutesRepository.instance.isLoaded) {
      await tester.runAsync(() => RoutesRepository.instance.ensureLoaded());
      await tester.pump();
    }
  }

  testWidgets('Home renders the recovered header copy', (tester) async {
    await pumpScreen(tester, const HomeScreen());
    expect(find.text('Lahore 🇵🇰'), findsOneWidget);
    expect(find.text('Every route, one tap away!'), findsOneWidget);
    expect(find.text('HOW IT WORKS'), findsOneWidget);
    expect(find.text('All Bus Types'), findsOneWidget);
    expect(find.text('Works Offline'), findsOneWidget);
    expect(find.text('Speedo'), findsOneWidget);
    expect(find.text('Metro'), findsOneWidget);
    expect(find.text('Orange Line'), findsOneWidget);
  });

  testWidgets('Home shows both placeholders and a disabled Find Routes', (
    tester,
  ) async {
    await pumpScreen(tester, const HomeScreen());
    expect(find.text('From — pick a stop'), findsOneWidget);
    expect(find.text('To — pick a stop'), findsOneWidget);
    final findRoutes = tester.widget<AppButton>(
      find.widgetWithText(AppButton, 'Find Routes'),
    );
    expect(findRoutes.enabled, false);
  });

  testWidgets('Home header exposes the search affordance', (tester) async {
    await pumpScreen(tester, const HomeScreen());
    expect(find.byIcon(AppIcons.magnify), findsWidgets);
  });

  testWidgets('Schedule shows the recovered header and all categories', (
    tester,
  ) async {
    await pumpScreen(tester, const ScheduleScreen());
    expect(find.text('Lahore'), findsWidgets);
    expect(find.text('Bus Schedule'), findsOneWidget);
    for (final label in const ['Speedo', 'Metro', 'Orange Line', 'Electric']) {
      expect(find.text(label), findsWidgets, reason: label);
    }
    expect(find.textContaining(' Routes'), findsWidgets);
  });

  testWidgets('Settings shows the disclaimer and every section', (
    tester,
  ) async {
    await pumpScreen(tester, const SettingsScreen());
    expect(find.text('Manage your preferences'), findsOneWidget);
    expect(find.byKey(const Key('app-brand-logo')), findsOneWidget);
    expect(find.text('Speedo Bus Route Guide'), findsOneWidget);
    expect(find.text('Dark Mode'), findsOneWidget);
    expect(find.text('CONTACT & SUPPORT'), findsOneWidget);
    expect(
      find.textContaining('This is an unofficial companion app'),
      findsOneWidget,
    );
    expect(find.text('Visit our Website'), findsOneWidget);
    expect(find.text('Send Feedback'), findsOneWidget);

    // The remaining sections are lower down the scroll view.
    final list = find.byType(ListView);
    expect(list, findsOneWidget);
    for (final section in const [
      'OFFICIAL SOURCES',
      'LEGAL',
      'HELP & SUPPORT',
      'Punjab Mass Transit Authority',
      'Samanabad',
    ]) {
      final needle = find.textContaining(section.split(' ').first);
      if (needle.evaluate().isNotEmpty) continue;
      await tester.drag(list, const Offset(0, -260));
      await tester.pumpAndSettle();
    }
    expect(find.text('Punjab Mass Transit Authority'), findsWidgets);
  });

  testWidgets('shared widgets render', (tester) async {
    await pumpScreen(
      tester,
      const Scaffold(
        body: Column(
          children: [
            SectionHeader(text: 'SECTION'),
            StatBox(label: 'FARE', value: 'Rs 25'),
            EmptyState(
              icon: Icons.directions_bus_rounded,
              message: 'No routes found',
            ),
          ],
        ),
      ),
    );
    expect(find.text('SECTION'), findsOneWidget);
    expect(find.text('Rs 25'), findsOneWidget);
    expect(find.text('No routes found'), findsOneWidget);
  });
}
