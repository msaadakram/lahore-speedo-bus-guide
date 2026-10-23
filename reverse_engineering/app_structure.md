# App Structure

## Identity
| Field | Value |
|---|---|
| Application ID | `com.codez.lahoreelectricbusguide` |
| App label | **Lahore Speedo Bus Guide** |
| Version name | `2.1` |
| Version code | `12` |
| minSdk | 24 (Android 7.0) |
| targetSdk / compileSdk | 36 (Android 16) |
| Platform build version | 16 / 36 |
| React Native component name | `LahoreSpeedoBusGuide` |
| Main activity | `com.codez.lahoreelectricbusguide.MainActivity` (extends `com.facebook.react.ReactActivity`, `launchMode="singleTask"`, `windowSoftInputMode="adjustResize"`, `configChanges=keyboard\|keyboardHidden\|orientation\|screenLayout\|screenSize\|smallestScreenSize\|uiMode`) |
| Main application | `com.codez.lahoreelectricbusguide.MainApplication` (extends `android.app.Application`, `DefaultReactHost.getDefaultReactHost()` + `VectorIconsPackage` added manually) |
| Scheme | `usesCleartextTraffic="false"` (HTTPS only), `allowBackup="false"` |
| RTL | `supportsRtl="true"` |
| Required splits | `base__abi, base__density` (this base APK contains no `lib/*.so`; the native runtime ships in the ABI split) |

## Framework (recovered, not guessed)
The APK is a **React Native** application, proven by:
- `assets/index.android.bundle` – a **Hermes** bytecode bundle (magic `c6 1f bc 03 c1 03 19 1f`, bytecode version **98**), 3,020,312 bytes;
- `com.facebook.react.ReactActivity` / `ReactApplication` / `DefaultReactHost` / `PackageList` in smali;
- `android:extractNativeLibs="false"`;
- `com.oblador.vectoricons.VectorIconsPackage` registered in `MainApplication.reactHost_delegate$lambda$1`;
- 19 `react-native-vector-icons` TTFs in `assets/fonts/`;
- `MainActivity.getMainComponentName()` returns `"LahoreSpeedoBusGuide"`.

App metadata from the bundle header:
| Metric | Value |
|---|---|
| Function count | 12,238 |
| Identifier count | 17,686 |
| String count | 24,142 |
| RegExp count | 180 |
| Metro modules reconstructed | 1,383 (`__d` registrations) |

## Reverse-engineering method
1. `apktool d` → smali for all 5 dex files, decoded resources.
2. `hermes-dec` (P1sec) `hbc_decompiler.py` → register-machine JavaScript dump of the Hermes bundle (~20 MB).
3. A custom script rebuilt the Metro `__d(global, require, module)` graph (module id → deps → factory span).
4. `index.js` was located by finding the `__d` call whose factory calls `AppRegistry.registerComponent`; its dependency list is `[1, 2, 495, 1325, 1497]` where **1325 = `react-native-gesture-handler`**, **495 = `src/App.tsx`**, **1497 = `app.json`**.
5. The app's own 27 modules were isolated from 1,053 modules reachable from `App.tsx`.
6. A symbolic evaluator (`hermes/jsvalue.py`) re-materialised literal object/array data from the register machine, recovering the full GTFS dataset.

## Top-level entry chain
```
index.js
  └─ AppRegistry.registerComponent('LahoreSpeedoBusGuide', () => App)
        └─ App.tsx (module 495)
              ├─ SafeAreaProvider
              ├─ ThemeProvider (module 571 – app context, colours + AsyncStorage key 'themePreference')
              └─ AppShell
                    ├─ <SystemBars style={isDark ? 'dark' : 'light'} />
                    ├─ NavigationContainer (createStackNavigator, headerShown:false, animation:'slide_from_right')
                    │     ├─ MainTabs      → BottomTabs.tsx (module 557)
                    │     ├─ Search        → SearchScreen.tsx (1071)
                    │     ├─ RouteDetail   → RouteDetailScreen.tsx (1020)
                    │     ├─ StopDetail    → StopDetailScreen.tsx (1072)
                    │     ├─ Map           → MapScreen.tsx (1033)
                    │     ├─ StopPicker    → StopPickerScreen.tsx (1073)
                    │     ├─ JourneyResults→ JourneyResultsScreen.tsx (1075)
                    │     ├─ JourneyDetail → JourneyDetailScreen.tsx (1076)
                    │     ├─ Credits       → CreditsScreen.tsx (1081)
                    │     └─ Feedback      → FeedbackScreen.tsx (1082)
                    └─ ForceUpdateModal (module 1079)
```
