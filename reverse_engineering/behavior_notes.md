# Cross-cutting behaviour

## Theme
- `ThemeProvider` keeps `preference` ∈ `{'system','light','dark'}` (initial
  `'system'`), persisted under the AsyncStorage key `themePreference`, read once
  on mount and written by `setThemePreference`.
- `isDark = preference === 'dark' ? true : preference === 'light' ? false : colorScheme === 'dark'`.
- `Appearance.addChangeListener` keeps `colorScheme` in sync with the OS.
- `AppShell` sets the navigation-bar colour to `colors.card` and the system-bar
  style to `'dark'`/`'light'` whenever the palette changes.
- Each screen calls `useStatusBarColor(<colour>)` on focus, so the status bar
  matches the screen's header block (primary on Home/Schedule/Nearby/Settings).

## Back button
- React Navigation pops the stack; on `MainTabs` the bottom-tab navigator
  returns to the initial tab, and only then can the activity be backgrounded.
- `launchMode="singleTask"` means the activity is reused, not recreated.
- `ForceUpdateModal` uses an empty `onRequestClose` plus a BackHandler that
  swallows the hardware back while it is visible.
- `windowSoftInputMode="adjustResize"` everywhere.

## Rebuild mapping
| RN behaviour | Flutter |
|---|---|
| stack + bottom tabs | `AppRouter.onGenerateRoute` + `MainTabsHost` (`IndexedStack`-style switcher) |
| per-screen status-bar colour | system chrome driven by the active palette (see README limitation 7) |
| hardware back | default `Navigator` pop behaviour; `PopScope` on the modal |
| `adjustResize` | `windowSoftInputMode="adjustResize"` in the manifest |
| AsyncStorage | `shared_preferences` behind `PreferencesStore` |

## Responsiveness
The original app is a single-column phone layout; it declares
`small|normal|large|xlarge` and `anyDensity`. The rebuild uses
`SingleChildScrollView`/`ListView` for vertical overflow and `Wrap` for the
chip rows, so the same layout scales to any width without restructuring it —
which matches the original rather than reflowing it.
