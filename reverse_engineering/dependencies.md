# Dependencies (recovered from the APK / bundle)

## Native Android libraries (from META-INF `*.version` + `*.properties` and smali packages)
| Library | Version | Why it is here |
|---|---|---|
| `com.facebook.react:react-android` | RN 0.7x (New Architecture `DefaultReactHost`, `ReactNativeApplicationEntryPoint.loadReactNative`) | The app framework |
| Hermes engine | bytecode version 98 | JS runtime |
| `com.facebook.react:hermes-android` | (ABI split, not in this base APK) | JS engine |
| `androidx.appcompat` | from `META-INF/androidx.appcompat_appcompat.version` | RN dependency |
| `androidx.core:core-ktx` | `core-common.properties` | RN dependency |
| `kotlin-stdlib` | `kotlin-tooling-metadata.json` (Kotlin 2.x) | App + RN |
| `kotlinx-coroutines` | `DebugProbesKt.bin` present | RN |
| `com.google.firebase:firebase-common` / `firebase-firestore` / `firebase-analytics` / `firebase-installations` / `firebase-components` | property files present + `ComponentDiscoveryService` registrars | Feedback submission + logging |
| `com.google.android.gms:play-services-*` (base, basement, maps, location, tasks, auth, auth-api-phone, fido, stats, measurement-*, ads-identifier) | property files present + `SignInHubActivity`, `GoogleApiActivity`, measurement services | Firebase + maps |
| `androidx.work:work-runtime` | `androidx.work.*` services/receivers in manifest | Background work (Firebase) |
| `androidx.startup:startup-runtime` | manifest provider | Initialisation |
| `androidx.profileinstaller` | manifest provider + `assets/dexopt/baseline.prof(m)` | Baseline profiles |
| `androidx.emoji2` | manifest provider | Emoji compat |
| `androidx.lifecycle:lifecycle-process` | manifest provider | Process lifecycle |
| `androidx.sqlite:sqlite-bundled` | `META-INF/androidx.sqlite_sqlite-bundled.version` | Room/SQLite of a lib |
| `com.google.guava` + `failureaccess` + protobuf-lite (`google/protobuf/...`) | bundled .proto files | Firestore |
| `com.squareup.okhttp3` | `okhttp3/internal/publicsuffix` | Network stack |
| `com.android.billingclient` + `org.chromium.intent.action.PAY` queries | manifest | Google Play Billing probes |
| `com.pairip` (Play Integrity) | `com.pairip.application.Application` | Anti-tampering |

## JavaScript packages (recovered from the Metro module graph + `PackageList`)
| Package | Evidence | Used by |
|---|---|---|
| `react` / `react-native` | module graph | everything |
| `@react-navigation/native` + `@react-navigation/native-stack` + `@react-navigation/bottom-tabs` + `@react-navigation/elements` | modules 231, 1482, 557, 495; asset modules under `/assets/node_modules/@react-navigation/elements/lib/module/assets` (searchIcon, backIcon, backIconMask, clearIcon, closeIcon) | Navigation + header icons |
| `react-native-screens`, `react-native-safe-area-context`, `react-native-gesture-handler` | modules 1325, 848, 848 | App shell |
| `react-native-vector-icons` (+ `@react-native-vector-icons/*`) | `VectorIconsPackage` in `MainApplication`; 19 TTFs in `assets/fonts`; icon-name→glyph maps (e.g. `MaterialCommunityIcons`, `Ionicons`, `MaterialIcons`) | Icons throughout |
| `react-native-paper` | module 858/859/861 (`MD3LightTheme`, `configureFonts`); `BottomNavigation.Bar` used by the custom tab bar | Bottom navigation bar |
| `react-native-webview` | `RNCWebViewFileProvider` in manifest | WebView provider (registered) |
| `react-native-maps` | module 1033 (MapScreen: `onMapReady`, `handleMarkerPress`) | Map screen |
| `react-native-geolocation-service` | module 729 (`getCurrentPosition`, `watchPosition`, `setRNConfiguration`) | Nearby screen |
| `@notifee/react-native` | module 1485 (`isUsable`, `requestNotificationPermission`) | Notification permission request |
| `react-native-navigation-bar-color` | module 555 (setBarColor / setNavigationColor / setBarStyle), used in `AppShell` `useEffect` | Navigation bar tinting |
| `react-native-system-bars` / `expo-system-bars` | module 1494 (`SystemBars`), 1495 | Status bar appearance |
| `sp-react-native-in-app-update` | module 1315 (`IAUUpdateKind.IMMEDIATE`, `checkNeedsUpdate`, `startUpdate`, `storeVersion`) | Force update modal |
| `rn-emoji-keyboard` | module 1082 (FeedbackScreen uses `react-native-emoji-selector`-style picker lib) | Feedback |
| `react-native-element-dropdown` | assets `/assets/node_modules/react-native-element-dropdown/src/assets` (close.png, down.png) | Feedback "Type" field |
| `@react-native-async-storage/async-storage` | module 800 (`getItem`/`setItem`), key `themePreference` | Theme preference |
| `@react-native-firebase/app`, `@react-native-firebase/firestore` | module 1082 + manifest registrars | Feedback submission |
| `react-native-permissions`-style helper | module 1491 (`check`, `checkMultiple`, `request`, `requestMultiple`, `openSettings`, `shouldRequestPermission`) | Permission flows |
| `react-native-bottom-tabs` | modules 837/843/844 (TabsHost, TabsScreen) | JS-side tab host |

## Flutter equivalents selected for the rebuild
| Original | Flutter replacement |
|---|---|
| React Navigation stack + bottom tabs | `Navigator 2.0` via a small declarative router over `Navigator` |
| React Navigation theme context | `ThemeNotifier` (ChangeNotifier) + `ThemeData` |
| `react-native-vector-icons` | Material Symbols Rounded subset bundled as an `IconData` map |
| `react-native-maps` | `flutter_map` (OSM) — no API key required, fully offline |
| `react-native-geolocation-service` | `geolocator` |
| `@react-native-async-storage/async-storage` | `shared_preferences` (key `themePreference`) |
| `@react-native-firebase/firestore` | local repository + optional Firestore REST backend gated behind `.env` |
| `react-native-vector-icons` fonts | bundled custom `IconData` font map |
