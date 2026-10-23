import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Thin abstraction over `shared_preferences` so tests can substitute an
/// in-memory implementation.
abstract class PreferencesStore {
  String? getString(String key);
  Future<void> setString(String key, String value);
  bool? getBool(String key);
  Future<void> setBool(String key, bool value);
  Future<void> remove(String key);
}

class SharedPreferencesStore implements PreferencesStore {
  SharedPreferencesStore(this._prefs);

  final SharedPreferences _prefs;

  @override
  String? getString(String key) => _prefs.getString(key);

  @override
  Future<void> setString(String key, String value) =>
      _prefs.setString(key, value);

  @override
  bool? getBool(String key) => _prefs.getBool(key);

  @override
  Future<void> setBool(String key, bool value) => _prefs.setBool(key, value);

  @override
  Future<void> remove(String key) => _prefs.remove(key);
}

/// In-memory implementation used by unit/widget tests.
class MemoryPreferencesStore implements PreferencesStore {
  final Map<String, String> _strings = {};
  final Map<String, bool> _bools = {};

  @override
  String? getString(String key) => _strings[key];

  @override
  Future<void> setString(String key, String value) async {
    _strings[key] = value;
  }

  @override
  bool? getBool(String key) => _bools[key];

  @override
  Future<void> setBool(String key, bool value) async {
    _bools[key] = value;
  }

  @override
  Future<void> remove(String key) async {
    _strings.remove(key);
    _bools.remove(key);
  }
}

final sharedPreferencesProvider = FutureProvider<SharedPreferences>(
  (ref) => SharedPreferences.getInstance(),
);

final preferencesStoreProvider = Provider<PreferencesStore>((ref) {
  final async = ref.watch(sharedPreferencesProvider);
  return async.whenOrNull(
    data: SharedPreferencesStore.new,
    error: (e, s) => MemoryPreferencesStore(),
  )!;
});
