import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/preferences_store.dart';
import 'app_palette.dart';

/// `'system' | 'light' | 'dark'` — the three values stored in AsyncStorage
/// under the recovered key `themePreference`.
enum ThemePreference { system, light, dark }

extension ThemePreferenceWire on ThemePreference {
  String toWire() => switch (this) {
    ThemePreference.system => 'system',
    ThemePreference.light => 'light',
    ThemePreference.dark => 'dark',
  };

  static ThemePreference fromWire(String? value) => switch (value) {
    'light' => ThemePreference.light,
    'dark' => ThemePreference.dark,
    _ => ThemePreference.system,
  };
}

class ThemeState {
  const ThemeState({
    required this.preference,
    required this.platformBrightness,
  });

  final ThemePreference preference;
  final Brightness platformBrightness;

  /// isDark = preference === 'dark' ? true
  ///        : preference === 'light' ? false : colorScheme === 'dark'
  bool get isDark => switch (preference) {
    ThemePreference.dark => true,
    ThemePreference.light => false,
    ThemePreference.system => platformBrightness == Brightness.dark,
  };

  AppPalette get palette => isDark ? AppPalette.dark : AppPalette.light;

  ThemeMode get themeMode => switch (preference) {
    ThemePreference.dark => ThemeMode.dark,
    ThemePreference.light => ThemeMode.light,
    ThemePreference.system => ThemeMode.system,
  };

  @override
  bool operator ==(Object other) =>
      other is ThemeState &&
      other.preference == preference &&
      other.platformBrightness == platformBrightness;

  @override
  int get hashCode => Object.hash(preference, platformBrightness);
}

class ThemeController extends StateNotifier<ThemeState> {
  ThemeController(this._store)
    : super(
        const ThemeState(
          preference: ThemePreference.system,
          platformBrightness: Brightness.light,
        ),
      ) {
    _restore();
  }

  static const storageKey = 'themePreference';
  final PreferencesStore _store;

  /// Reads the persisted preference. `SharedPreferences` is fully loaded in
  /// `main()` before the first frame, so the read is synchronous — the original
  /// AsyncStorage read was awaited, but the effect is the same because nothing
  /// renders before the value is available.
  void _restore() {
    final stored = _store.getString(storageKey);
    if (stored != null) {
      state = ThemeState(
        preference: ThemePreferenceWire.fromWire(stored),
        platformBrightness: state.platformBrightness,
      );
    }
  }

  void onPlatformBrightnessChanged(Brightness brightness) {
    if (brightness == state.platformBrightness) return;
    state = ThemeState(
      preference: state.preference,
      platformBrightness: brightness,
    );
  }

  Future<void> setPreference(ThemePreference value) async {
    state = ThemeState(
      preference: value,
      platformBrightness: state.platformBrightness,
    );
    await _store.setString(storageKey, value.toWire());
  }

  Future<void> toggleTheme() async {
    await setPreference(
      state.isDark ? ThemePreference.light : ThemePreference.dark,
    );
  }
}

final themeControllerProvider =
    StateNotifierProvider<ThemeController, ThemeState>((ref) {
      return ThemeController(ref.watch(preferencesStoreProvider));
    });
