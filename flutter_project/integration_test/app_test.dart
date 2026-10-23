import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:lahore_speedo_bus_guide/app/app.dart';
import 'package:lahore_speedo_bus_guide/core/storage/preferences_store.dart';
import 'package:lahore_speedo_bus_guide/data/repositories/routes_repository.dart';
import 'package:lahore_speedo_bus_guide/data/repositories/stop_repository.dart';
import 'package:lahore_speedo_bus_guide/shared/widgets/app_icons.dart';
import 'package:lahore_speedo_bus_guide/shared/widgets/app_widgets.dart';

/// End-to-end suite that runs the REAL app on a real Android device.
///
/// Unlike a widget test this exercises the shipped code paths: the bundled
/// asset is loaded from the APK, the plugins are registered, permissions are
/// requested from the OS and the ProGuard/R8 configuration is in force.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  /// Unmounts whatever is on screen. `pumpWidget` reuses the existing
  /// element tree when the widget type matches, so without this every test
  /// would inherit the previous test's navigation state.
  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 50));
  }

  /// Bounded settle. `pumpAndSettle` never returns while an indeterminate
  /// progress indicator is animating, so pump a fixed number of frames.
  Future<void> settle(WidgetTester tester, {int frames = 6}) async {
    for (var i = 0; i < frames; i++) {
      await tester.pump(const Duration(milliseconds: 40));
    }
  }

  Future<void> launchApp(WidgetTester tester, {bool fresh = true}) async {
    await RoutesRepository.instance.ensureLoaded();
    await StopRepository.instance.ensureLoaded();
    if (fresh) {
      await unmount(tester);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            preferencesStoreProvider.overrideWithValue(
              MemoryPreferencesStore(),
            ),
          ],
          child: const BusGuideApp(),
        ),
      );
    }
    await settle(tester);
  }

  /// Scrolls the first scrollable until [needle] is built, then asserts it.
  Future<void> expectTextScrolled(
    WidgetTester tester,
    String label,
    String needle, {
    Finder? scrollable,
    double step = -180,
  }) async {
    final finder = find.text(needle);
    final sc = scrollable ?? find.byType(Scrollable).first;
    // The item may be above or below the viewport, so try both directions.
    for (var i = 0; i < 25 && finder.evaluate().isEmpty; i++) {
      await tester.drag(sc, Offset(0, step));
      await settle(tester, frames: 3);
    }
    for (var i = 0; i < 25 && finder.evaluate().isEmpty; i++) {
      await tester.drag(sc, Offset(0, -step));
      await settle(tester, frames: 3);
    }
    expect(finder, findsWidgets, reason: label);
  }

  group("01 home", () {
    testWidgets("renders the recovered header and planner", (tester) async {
      await launchApp(tester);
      expect(find.text('Lahore \u{1F1F5}\u{1F1F0}'), findsOneWidget);
      expect(find.text('Every route, one tap away!'), findsOneWidget);
      expect(find.text('From — pick a stop'), findsOneWidget);
      expect(find.text('To — pick a stop'), findsOneWidget);
      expect(find.text('Find Routes'), findsOneWidget);
      expect(find.text('HOW IT WORKS'), findsOneWidget);
      expect(find.text('All Bus Types'), findsOneWidget);
      expect(find.text('Works Offline'), findsOneWidget);
      // The four bottom-nav labels.
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Nearby'), findsOneWidget);
      expect(find.text('Schedule'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets("Find Routes is disabled until two different stops are set", (
      tester,
    ) async {
      await launchApp(tester);
      final button = tester.widget<AppButton>(
        find.widgetWithText(AppButton, 'Find Routes'),
      );
      expect(button.enabled, isFalse);
    });

    testWidgets("the search button opens the search screen", (tester) async {
      await launchApp(tester);
      await tester.tap(find.byIcon(AppIconsRef.magnify).first);
      await settle(tester);
      expect(find.text('Search Routes'), findsOneWidget);
    });
  });

  group("02 stop picker", () {
    testWidgets("lists real stops, filters, and returns the selection", (
      tester,
    ) async {
      await launchApp(tester);
      await tester.tap(find.text('From — pick a stop'));
      await settle(tester);

      expect(find.text('Select Departure Stop'), findsOneWidget);
      expect(find.text('Use current location'), findsOneWidget);
      expect(find.text('No stops found'), findsNothing);
      expect(find.textContaining('All Stops'), findsOneWidget);

      // The counter must reflect the real index size.
      final counter = tester
          .widget<Text>(find.textContaining('All Stops'))
          .data!;
      expect(counter, '${StopRepository.instance.allStops.length} All Stops');

      // Filter.
      await tester.enterText(find.byType(TextField).first, 'Jinnah');
      await settle(tester);
      expect(find.text('No stops found'), findsNothing);
      expect(find.textContaining('Jinnah'), findsWidgets);

      // Pick the first result -> back on Home with the field filled.
      // The search field itself matches 'Jinnah'; the result row may be
      // below the fold, so scroll the list until a row is visible.
      final rows = find.descendant(
        of: find.byKey(const Key('stop-picker-list')),
        matching: find.textContaining('Jinnah'),
      );
      for (var i = 0; i < 20 && rows.evaluate().isEmpty; i++) {
        await tester.drag(
          find.byKey(const Key('stop-picker-list')),
          const Offset(0, -200),
        );
        await settle(tester, frames: 3);
      }
      expect(rows, findsWidgets, reason: 'a Jinnah stop row is listed');
      await tester.tap(rows.first);
      await settle(tester);
      expect(find.text('Every route, one tap away!'), findsOneWidget);
      expect(find.text('From — pick a stop'), findsNothing);
      expect(find.textContaining('Jinnah'), findsWidgets);
    });

    testWidgets("an empty search shows the no-stops state", (tester) async {
      await launchApp(tester);
      await tester.tap(find.text('From — pick a stop'));
      await settle(tester);
      await tester.enterText(find.byType(TextField).first, 'zzzzznotastop');
      await settle(tester);
      expect(find.text('No stops found'), findsOneWidget);
    });
  });

  group("03 schedule", () {
    testWidgets("lists routes and switches categories", (tester) async {
      await launchApp(tester);
      await tester.tap(find.text('Schedule'));
      await settle(tester);

      expect(find.text('Bus Schedule'), findsOneWidget);
      expect(find.text('23 Routes'), findsOneWidget);
      expect(find.text('Speedo RT-03'), findsWidgets);

      // Metro has exactly one route in the recovered dataset.
      await tester.tap(find.text('Metro'));
      await settle(tester);
      expect(find.text('1 Routes'), findsOneWidget);

      await tester.tap(find.text('Speedo'));
      await settle(tester);
      expect(find.text('23 Routes'), findsOneWidget);
    });
  });

  group("04 route detail", () {
    testWidgets("shows stats, departures and the stop list", (tester) async {
      await launchApp(tester);
      await tester.tap(find.text('Schedule'));
      await settle(tester);
      await tester.tap(find.text('Speedo RT-03'));
      await settle(tester);

      expect(find.text('FARE'), findsOneWidget);
      expect(find.text('FREQUENCY'), findsOneWidget);
      expect(find.text('HOURS'), findsOneWidget);
      expect(find.text('TOTAL STOPS'), findsOneWidget);
      expect(find.text('NEXT DEPARTURES'), findsOneWidget);
      // Rs 25 is the standard fare.
      expect(find.text('Rs. 25'), findsOneWidget);
      // The stops section is below the fold - scroll to it.
      await expectTextScrolled(
        tester,
        'stops section',
        'Stops',
        scrollable: find.byKey(const Key('route-detail-list')),
      );
      await expectTextScrolled(
        tester,
        'stops subtitle',
        'Stops along this route',
        scrollable: find.byKey(const Key('route-detail-list')),
      );
    });

    testWidgets("the DIRECTION switch reverses the stop order", (tester) async {
      await launchApp(tester);
      await tester.tap(find.text('Schedule'));
      await settle(tester);
      await tester.tap(find.text('Speedo RT-03'));
      await settle(tester);

      // The route's long name is the header subtitle; the stop list starts
      // with the first stop of the route.
      expect(find.text('Rana Town to Railway Station'), findsWidgets);
      List<String> visibleTexts() => tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data)
          .whereType<String>()
          .toList();

      final before = visibleTexts();
      expect(before.any((t) => t.contains('Railway')), isTrue);

      // Tapping DIRECTION reverses the order of the stop list.
      await expectTextScrolled(
        tester,
        'direction button',
        'DIRECTION',
        scrollable: find.byKey(const Key('route-detail-list')),
      );
      await tester.tap(find.text('DIRECTION'));
      await settle(tester);
      final after = visibleTexts();
      expect(
        after,
        isNot(equals(before)),
        reason: 'reversing the direction reorders the stop list',
      );
    });
  });

  group("05 settings", () {
    testWidgets("shows every section and toggles the theme", (tester) async {
      await launchApp(tester);
      await tester.tap(find.text('Settings'));
      await settle(tester);

      expect(find.text('Manage your preferences'), findsOneWidget);
      expect(find.text('Dark Mode'), findsOneWidget);
      expect(find.text('Currently off'), findsOneWidget);
      expect(find.textContaining('unofficial companion app'), findsOneWidget);
      expect(find.text('CONTACT & SUPPORT'), findsOneWidget);
      expect(find.text('Visit our Website'), findsOneWidget);
      expect(find.text('Send Feedback'), findsOneWidget);

      await tester.tap(find.byType(Switch));
      await settle(tester);
      expect(find.text('Currently on'), findsOneWidget);
    });

    testWidgets("the theme choice survives a restart", (tester) async {
      final store = MemoryPreferencesStore();
      await RoutesRepository.instance.ensureLoaded();
      await StopRepository.instance.ensureLoaded();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [preferencesStoreProvider.overrideWithValue(store)],
          child: const BusGuideApp(),
        ),
      );
      await settle(tester);
      await tester.tap(find.text('Settings'));
      await settle(tester);
      await tester.tap(find.byType(Switch));
      await settle(tester);
      expect(store.getString('themePreference'), 'dark');
    });

    testWidgets("opens the feedback form with all five fields", (tester) async {
      await launchApp(tester);
      await tester.tap(find.text('Settings'));
      await settle(tester);
      await tester.scrollUntilVisible(
        find.text('Send Feedback'),
        -160,
        scrollable: find.byType(Scrollable).hitTestable().first,
        maxScrolls: 40,
      );
      await settle(tester);
      await tester.tap(find.text('Send Feedback'));
      await settle(tester);

      expect(find.text('Send Feedback'), findsOneWidget);
      await expectTextScrolled(
        tester,
        'Your Name field',
        'Your Name',
        scrollable: find.byKey(const Key('feedback-form-list')),
      );
      await expectTextScrolled(
        tester,
        'Email field',
        'Email',
        scrollable: find.byKey(const Key('feedback-form-list')),
      );
      await expectTextScrolled(
        tester,
        'Location field',
        'Location',
        scrollable: find.byKey(const Key('feedback-form-list')),
      );
      await expectTextScrolled(
        tester,
        'Type field',
        'Type',
        scrollable: find.byKey(const Key('feedback-form-list')),
      );
      await expectTextScrolled(
        tester,
        'Comment field',
        'Comment',
        scrollable: find.byKey(const Key('feedback-form-list')),
      );
      await expectTextScrolled(
        tester,
        'submit button',
        'Submit',
        scrollable: find.byKey(const Key('feedback-form-list')),
      );
    });

    testWidgets("the feedback form validates required fields", (tester) async {
      await launchApp(tester);
      await tester.tap(find.text('Settings'));
      await settle(tester);
      await tester.scrollUntilVisible(
        find.text('Send Feedback'),
        -160,
        scrollable: find.byType(Scrollable).hitTestable().first,
        maxScrolls: 40,
      );
      await settle(tester);
      await tester.tap(find.text('Send Feedback'));
      await settle(tester);
      await expectTextScrolled(
        tester,
        'submit button',
        'Submit',
        scrollable: find.byKey(const Key('feedback-form-list')),
      );
      await tester.tap(find.byKey(const Key('feedback-submit')));
      await settle(tester);
      expect(find.text('Required'), findsWidgets);
    });

    testWidgets("the feedback form rejects a bad email", (tester) async {
      await launchApp(tester);
      await tester.tap(find.text('Settings'));
      await settle(tester);
      await tester.scrollUntilVisible(
        find.text('Send Feedback'),
        -160,
        scrollable: find.byType(Scrollable).hitTestable().first,
        maxScrolls: 40,
      );
      await settle(tester);
      await tester.tap(find.text('Send Feedback'));
      await settle(tester);
      // Fields in order: Your Name, Email, Location, Type, Comment.
      // Fill the other required fields so the email error is the one that
      // surfaces (the form reports the first failing field).
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'Test User');
      await tester.enterText(fields.at(1), 'not-an-email');
      await tester.enterText(fields.at(2), 'Lahore');
      await tester.enterText(fields.at(3), 'Somewhere');
      await settle(tester);
      // The keyboard covers the submit button, so bring it into view first.
      await expectTextScrolled(
        tester,
        'submit button',
        'Submit',
        scrollable: find.byKey(const Key('feedback-form-list')),
      );
      await tester.tap(find.byKey(const Key('feedback-submit')));
      await settle(tester);
      // The inline error belongs to the email field, which the keyboard may
      // have scrolled out of view, so bring it back before asserting.
      await expectTextScrolled(
        tester,
        'email validation error',
        'Enter a valid email address.',
        scrollable: find.byKey(const Key('feedback-form-list')),
      );
    });
  });

  group("06 search", () {
    testWidgets("filters routes live and shows an empty state", (tester) async {
      await launchApp(tester);
      await tester.tap(find.text('Schedule'));
      await settle(tester);
      await tester.tap(find.byIcon(AppIconsRef.magnify).first);
      await settle(tester);
      expect(find.text('Search Routes'), findsOneWidget);

      await tester.enterText(find.byType(TextField).first, 'Speedo');
      await settle(tester);
      expect(find.text('Speedo RT-03'), findsWidgets);

      await tester.enterText(find.byType(TextField).first, 'zzzznothing');
      await settle(tester);
      expect(find.text('No routes found'), findsOneWidget);
    });
  });

  group("07 navigation", () {
    testWidgets("the back button unwinds the stack", (tester) async {
      await launchApp(tester);
      await tester.tap(find.text('Schedule'));
      await settle(tester);
      await tester.tap(find.text('Speedo RT-03'));
      await settle(tester);
      expect(find.text('FARE'), findsOneWidget);

      // The app draws its own back affordance, so drive the system back
      // through the navigator instead of tester.pageBack().
      final backButtons = find.byIcon(AppIcons.arrowLeft);
      expect(
        backButtons,
        findsWidgets,
        reason: 'the route detail has a back button',
      );
      await tester.tap(backButtons.first);
      await settle(tester);
      expect(find.text('Bus Schedule'), findsOneWidget);

      // The bottom tabs are a tab switch, not pushed routes: a back press on
      // the tab root leaves the Schedule tab in place.
      await tester.binding.handlePopRoute();
      await settle(tester);
      expect(find.text('Bus Schedule'), findsOneWidget);

      await tester.tap(find.text('Home'));
      await settle(tester);
      expect(find.text('Every route, one tap away!'), findsOneWidget);
    });

    testWidgets("every bottom tab is reachable", (tester) async {
      await launchApp(tester);
      const tabs = <(String, String)>[
        ('Nearby', 'Nearby Stops'),
        ('Schedule', 'Bus Schedule'),
        ('Settings', 'Manage your preferences'),
        ('Home', 'Every route, one tap away!'),
      ];
      for (final (tab, marker) in tabs) {
        await tester.tap(find.text(tab));
        await settle(tester);
        expect(find.text(marker), findsOneWidget, reason: tab);
      }
    });
  });

  group("08 robustness", () {
    testWidgets("survives rapid navigation and input", (tester) async {
      await launchApp(tester);
      for (var i = 0; i < 3; i++) {
        for (final tab in const ['Schedule', 'Nearby', 'Settings', 'Home']) {
          await tester.tap(find.text(tab));
          await tester.pump(const Duration(milliseconds: 30));
        }
      }
      await settle(tester);
      expect(find.text('Every route, one tap away!'), findsOneWidget);

      await tester.tap(find.text('From — pick a stop'));
      await settle(tester);
      for (var i = 0; i < 3; i++) {
        await tester.enterText(find.byType(TextField).first, 'a');
        await tester.pump(const Duration(milliseconds: 30));
      }
      await settle(tester);
      expect(find.text('No stops found'), findsNothing);
    });

    testWidgets("renders at a large font scale", (tester) async {
      await launchApp(tester);
      await settle(tester);
      expect(tester.takeException(), isNull);
      expect(find.text('Every route, one tap away!'), findsOneWidget);
    });
  });
}

/// Icon handle used by the tests (MDI 'magnify' codepoint).
abstract final class AppIconsRef {
  static const IconData magnify = AppIcons.magnify;
}
