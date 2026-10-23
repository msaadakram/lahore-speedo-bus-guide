import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'core/storage/preferences_store.dart';
import 'data/repositories/routes_repository.dart';
import 'data/repositories/stop_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Edge-to-edge everywhere: transparent system bars, light icons over the
  // coloured headers.
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Never let a storage failure stop the app from starting. The original
  // app is fully offline and its only persisted value is the theme
  // preference, so falling back to an in-memory store degrades gracefully
  // instead of leaving the user with a blank screen.
  final store = await _openStore();

  // Warm the bundled GTFS dataset before the first frame so that every tab —
  // especially "Schedule" — renders its content immediately instead of
  // showing a spinner while the 460 KB JSON is parsed.
  await _warmDataset();

  runApp(
    ProviderScope(
      overrides: [preferencesStoreProvider.overrideWithValue(store)],
      child: const BusGuideApp(),
    ),
  );
}

/// Opens the persistent preference store, falling back to memory on failure.
Future<PreferencesStore> _openStore() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    return SharedPreferencesStore(prefs);
  } catch (error, stack) {
    debugPrint('Falling back to in-memory preferences: $error');
    debugPrintStack(stackTrace: stack);
    return MemoryPreferencesStore();
  }
}

/// Preloads the embedded route dataset. Failure is non-fatal: the screens
/// render their own empty states.
Future<void> _warmDataset() async {
  try {
    // The stop index is derived from the routes, and it is what the Nearby
    // tab and the stop picker read. Both must be ready before the first
    // frame, otherwise those screens briefly (or permanently) show an empty
    // list.
    await RoutesRepository.instance.ensureLoaded();
    await StopRepository.instance.ensureLoaded();
  } catch (error, stack) {
    debugPrint('Could not preload the route dataset: $error');
    debugPrintStack(stackTrace: stack);
  }
}
