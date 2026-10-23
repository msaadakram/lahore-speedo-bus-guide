# Local Storage (recovered)

The app uses **AsyncStorage** only (module `800` exposes `getItem`/`setItem`; it is required by
`ThemeProvider` module 571 and `SettingsScreen` module 737).

| Key | Type | Purpose | Default | Read | Write | Delete |
|---|---|---|---|---|---|---|
| `themePreference` | `'system' \| 'light' \| 'dark'` | Theme preference driving `isDark` | `'system'` | On `ThemeProvider` mount (`useEffect([])`) | `setThemePreference(v)` / `toggleTheme(v)` | never removed |

### Read behaviour (module 571)
```js
useEffect(() => {
  AsyncStorage.getItem('themePreference')
    .then(v => { if (v === 'light' || v === 'dark' || v === 'system') setPreference(v); })
    .catch(() => {});          // errors are swallowed (no-arrow → `() => {}`)
}, []);
```

### Write behaviour
```js
const setThemePreference = useCallback((v) => {
  setPreference(v);
  AsyncStorage.setItem('themePreference', v).catch(() => {});
}, []);
```

### Notes
- `AsyncStorage` on Android is a SQLite-backed key/value store; **no** `secureStorage`
  (Keychain/Keystore) library is bundled.
- No Room/SQLite access from the app itself (`androidx.sqlite:sqlite-bundled` is a transitive
  dependency of a platform library, not used by app code).
- No file writes by the app other than AsyncStorage's database.
- WebView local storage is unused (the WebView library is only linked for its FileProvider).

### Flutter equivalent
`shared_preferences`, key `themePreference`, restored before first frame.
