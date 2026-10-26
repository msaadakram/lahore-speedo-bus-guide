import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'app/app_startup.dart';
import 'core/storage/preferences_store.dart';

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

  runApp(
    AppStartupGate(
      child: ProviderScope(
        overrides: [preferencesStoreProvider.overrideWithValue(store)],
        child: const BusGuideApp(),
      ),
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
