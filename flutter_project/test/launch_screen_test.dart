import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lahore_speedo_bus_guide/app/app_startup.dart';
import 'package:lahore_speedo_bus_guide/features/launch/launch_screen.dart';

void main() {
  testWidgets('launch screen shows the Speedo identity and loading state', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: LaunchScreen()));
    await tester.runAsync(
      () => precacheImage(
        const AssetImage('assets/images/speedo_logo.png'),
        tester.element(find.byType(LaunchScreen)),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('PREPARING YOUR ROUTES'), findsOneWidget);
    expect(find.text('Lahore  •  Ready offline'), findsOneWidget);
    expect(find.bySemanticsLabel('Speedo Bus Route Guide'), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
    expect(tester.takeException(), isNull);

    await expectLater(
      find.byType(LaunchScreen),
      matchesGoldenFile('goldens/launch_screen.png'),
    );
  });

  testWidgets('startup gate waits for initialization and hands off the app', (
    tester,
  ) async {
    final completer = Completer<void>();

    await tester.pumpWidget(
      MaterialApp(
        home: AppStartupGate(
          initialize: () => completer.future,
          minimumDuration: Duration.zero,
          child: const Text('App ready'),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(LaunchScreen), findsOneWidget);
    expect(find.text('App ready'), findsNothing);

    completer.complete();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.text('App ready'), findsOneWidget);
    expect(find.byType(LaunchScreen), findsNothing);
  });

  testWidgets('startup gate keeps the launch screen for its minimum duration', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AppStartupGate(
          initialize: () async {},
          minimumDuration: const Duration(milliseconds: 500),
          child: const Text('App ready'),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byType(LaunchScreen), findsOneWidget);
    expect(find.text('App ready'), findsNothing);

    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.text('App ready'), findsOneWidget);
    expect(find.byType(LaunchScreen), findsNothing);
  });
}
