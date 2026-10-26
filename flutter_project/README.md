# Lahore Speedo Bus Guide — Flutter rebuild

A faithful, production-quality Flutter reimplementation of the original
**Lahore Speedo Bus Guide** React Native application
(`com.codez.lahoreelectricbusguide`, version `2.1`, build `12`).

Everything in this project is derived from the shipped APK:
`assets/index.android.bundle` (Hermes bytecode), `res/`, `assets/` and the
decoded smali. See `../reverse_engineering/` for the full analysis.

---

## 1. Overview

| | |
|---|---|
| **Framework** | Flutter 3.47.5 / Dart 3.13.4 |
| **Application ID** | `com.lahorebus` |
| **Version** | `2.1.0+13` (current Play build) |
| **minSdk / targetSdk** | 24 / 36 (both identical to the original) |
| **State management** | Riverpod |
| **Maps** | `flutter_map` + OpenStreetMap tiles (no API key) |
| **Screens** | 14 |
| **Bundled data** | 28 routes, 601 stops, every timetable, fare and line colour |
| **Offline** | yes — the app has no required network calls |

## 2. Architecture

```
lib/
├── main.dart                       bootstrap + SharedPreferences injection
├── app/
│   ├── app.dart                    AppShell equivalent (theme scope + navigator)
│   ├── router.dart                 route names + typed route arguments
│   └── theme/
│       ├── app_colors.dart         recovered colour tokens
│       ├── app_palette.dart        COLORS / DARK_COLORS + InheritedWidget
│       ├── app_spacing.dart        per-screen layout metrics
│       ├── app_tokens.dart         SPACING / FONT_SIZE / BORDER_RADIUS (verbatim)
│       ├── app_theme.dart          Material ThemeData built from the palette
│       └── theme_controller.dart   `themePreference` persistence + platform sync
├── core/
│   ├── services/
│   │   ├── feedback_service.dart   Firestore-equivalent feedback submission
│   │   ├── link_launcher.dart      Linking.openURL equivalent
│   │   └── location_service.dart   react-native-geolocation-service equivalent
│   └── storage/
│       └── preferences_store.dart  AsyncStorage equivalent (+ in-memory test double)
├── data/
│   ├── models/                     BusRoute, RouteSchedule, RoutePattern,
│   │                               Coord, RouteCategory, BusStop
│   └── repositories/
│       ├── routes_repository.dart  asset loader + ROUTES/category helpers
│       ├── routes_provider.dart    Riverpod provider over the dataset
│       ├── stop_repository.dart    ALL_STOPS index + searchStops + haversine
│       ├── departures.dart         module-735 departure engine (verbatim formulas)
│       └── journey_repository.dart buildLeg / findBestTransfer / findJourneys
├── features/
│   ├── home/        RouteFinderScreen   ├── nearby/     NearbyScreen
│   ├── schedule/    ScheduleScreen      ├── settings/   SettingsScreen
│   ├── search/      SearchScreen        ├── map/        MapScreen
│   ├── route_detail/RouteDetailScreen   ├── stop_detail/StopDetailScreen
│   ├── stop_picker/ StopPickerScreen    ├── journey_results/ JourneyResultsScreen
│   ├── journey_detail/JourneyDetailScreen
│   ├── credits/     CreditsScreen       ├── feedback/   FeedbackScreen
│   └── update/      ForceUpdateModal
└── shared/
    └── widgets/
        ├── app_icons.dart         icon facade
        ├── app_icon_data.dart     exact MaterialCommunityIcons codepoints
        ├── app_widgets.dart       AppPressable, AppPageHeader, AppCard,
        │                          AppButton, StatBox, SectionHeader, EmptyState …
        ├── route_widgets.dart     BusIcon, TagChip, RouteChip, RouteRow, CategoryTab
        └── app_bottom_nav.dart    Paper-MD3 bottom bar + MainTabsHost
```

### State management
Riverpod was chosen because the app is medium-complexity (14 screens, a shared
dataset and several derived indexes) but has no long-lived streams. One
`FutureProvider` owns the dataset, one `StateNotifier` owns the theme, and
screens keep only their own interaction state (`useState` equivalents).

## 3. Design language (green, artwork-derived)

The UI was re-skinned from the reference artwork `downloads/bz4sqCqW.jpg` — a
soft 3D render with a grass-green gradient backdrop, chunky rounded forms,
diffuse green-tinted shadows and warm khaki accents. Every colour was **sampled
directly from that image** (the dominant `#83A034` alone is 6.7 % of its pixels).

| Role | Value | Source |
|---|---|---|
| `primary` | `#3B7306` / `#8FBB2A` dark | forest band of the backdrop gradient |
| `primaryBright` | `#83A034` | the dominant colour of the artwork |
| `accent` | `#9BB224` | bright leaf highlight |
| `background` | `#F3F8E4` / `#101808` dark | barely-green off-white |
| `text` | `#1E2A10` | near-black with a green cast |
| `textSecondary` | `#5F7346` | muted olive (the hoodie's khaki) |

Shape, elevation and typography follow the same source: 24–32 px radii, **pill**
buttons, soft green-tinted shadows instead of the original's flat 1 px borders,
curved hero headers, elevated grouped cards and a vertical `heroGradient`
(deep forest tones, tuned so white header copy passes AA contrast in both
themes).

The 2026 UI pass adds a rounded bottom navigation bar with an animated active
pill, a lazy `IndexedStack` that preserves each tab's state, a three-state
Appearance selector (System / Light / Dark), clearer journey and route cards,
and a consistent empty/loading/error system. The original copy, offline dataset
and interaction model remain unchanged.

Full detail: `../reverse_engineering/design_system_green.md`.

### Recovered tokens (kept verbatim)


```dart
SPACING      = { xs: 4, sm: 8, md: 16, lg: 24, xl: 32, xxl: 48 }
FONT_SIZE    = { xs: 10, sm: 12, md: 14, base: 16, lg: 18, xl: 22, xxl: 28, xxxl: 36 }
BORDER_RADIUS= { sm: 6, md: 10, lg: 16, xl: 24, full: 999 }

COLORS       = { primary #fc3b38, background #F5F7FA, card #FFFFFF,
                 border #E0E0E0, text #212121, textSecondary #757575,
                 overlay rgba(0,0,0,0.5) }
DARK_COLORS  = { primary #fc3b38, background #121212, card #2C2C2C,
                 border #333333, text #EEEEEE, textSecondary #AAAAAA,
                 overlay rgba(0,0,0,0.7) }
```

Icons use the **exact** glyphs from the `MaterialCommunityIcons` font shipped in
the original APK (`assets/fonts/material_community_icons.ttf`); the
name→codepoint map was recovered from the Hermes bundle, so rendering is
identical rather than approximated.

## 4. Setup

```bash
# Requires Flutter 3.47 (Dart 3.13) and the Android SDK with
#   platform 36  +  build-tools 34.0.0  +  NDK 28.2.13676358
flutter pub get
flutter gen-l10n        # (not used: the app is English-only)
```

### Environment variables
Copy `.env.example` to `.env`, or pass values at build time with
`--dart-define`. See the comments in `.env.example` — the app runs with no
variables set.

### Run

```bash
flutter run                       # debug
flutter run --release             # release on a connected device
```

## 5. Build

```bash
flutter build apk --release       # → build/app/outputs/flutter-apk/app-release.apk
flutter build appbundle --release # → build/app/outputs/bundle/release/app-release.aab
```

The release APK is ~55 MB (dominated by the bundled icon and image fonts) and
declares only the four permissions the rebuilt functionality needs:
`INTERNET`, `ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION`,
`ACCESS_NETWORK_STATE`.

## 6. On-device testing (Android emulator)

The release APK was installed and driven on a real Android emulator
(API 30, x86_64) with ADB. Six genuine bugs were found and fixed — two of them
critical release-only breakages caused by R8. See
`../reverse_engineering/on_device_test_report.md` for the full report.

```bash
tool/run_emulator.sh          # boot a headless AVD (no KVM -> software emulation)
tool/ui_test2.sh              # assertion-driven walkthrough (uiautomator)
tool/verify_release_dex.sh    # assert every runtime-resolved class survived R8
tool/generate_icon_data.py   # regenerate the icon codepoint map
```

Key on-device fixes:

| Bug | Symptom | Fix |
|---|---|---|
| R8 deleted `com.github.dart_lang.jni` | **blank screen** | `-keep class com.github.dart_lang.jni.** { *; }` |
| R8 renamed `kotlin.coroutines.Continuation` | `NoSuchMethodError` on `SharedPreferences.getAll` | `-keep class kotlin.coroutines.** { *; }` |
| R8 deleted the plugin v2 API registrars | preferences / links / share broken | `-keep class **ApiRegistrar { *; }` |
| Hand-converted icon codepoints | wrong glyphs everywhere | generated from the recovered glyph map |
| Stop index never loaded | picker showed "0 All Stops" | warm both indexes before the first frame |
| Nearby footer shown in the denied state | parity deviation | moved to the list footer slot |

`tool/verify_release_dex.sh` now guards all of these at build time.

## 7. Testing

```bash
flutter analyze                   # 0 errors, 0 warnings
flutter test                      # 58 tests
flutter test integration_test     # on-device journeys (needs a device/emulator)
dart format .                     # formatting
```

| Suite | File | What it covers |
|---|---|---|
| Units | `test/widget_test.dart` | route model, Coord, the whole departure engine, route names & typed arguments |
| Units | `test/theme_test.dart` | every recovered token, both palettes, `ThemeController` persistence and platform-follow behaviour |
| Units | `test/repository_test.dart` | the bundled dataset: 28 routes, category counts (23/1/1/3), `categoryOf`, normalised stop index, haversine |
| Units | `test/journey_test.dart` | `buildLeg`, `findBestTransfer`, direct-first ranking, walking-transfer time and the no-phantom-leg invariant |
| Widgets | `test/widget_smoke_test.dart` | recovered on-screen copy, placeholder/disabled states, grouped sections and the disclaimer |
| Journeys | `test/journeys_test.dart` | launch → all four tabs; Search; Appearance switching; Schedule categories; large-text tab sweep |
| Robustness | `test/journey_results_states_test.dart` | dataset-load failure → Retry → recovery on Journey Results |
| Accessibility | `test/large_text_test.dart` | pushed route/journey/support screens at the maximum supported 1.4× text scale |
| Integration | `integration_test/app_test.dart` | same journeys on a real device (`flutter test integration_test`) |

## 8. Android configuration

| Setting | Value | Source |
|---|---|---|
| `applicationId` | `com.lahorebus` | publisher package (matches Play Console listing) |
| label | `Lahore Speedo Bus Guide` | `res/values/strings.xml` |
| launcher icon | supplied Speedo Bus Route Guide artwork, with adaptive Android foreground and all iOS app-icon sizes | `res/mipmap-*/ic_launcher.png`, `ios/Runner/Assets.xcassets/AppIcon.appiconset/` |
| `launchMode` | `singleTask` | original manifest |
| `windowSoftInputMode` | `adjustResize` | original manifest |
| `allowBackup` | `false` | original manifest |
| `supportsRtl` | `true` | original manifest |
| `usesCleartextTraffic` | `false` | original manifest |
| theme | `Theme.AppCompat.DayNight.NoActionBar` + `forceDarkAllowed=false` | original `AppTheme` |
| window background | `#F5F7FA` light / `#121212` dark | `COLORS.background` / `DARK_COLORS.background` |

## 9. Known limitations

1. **Google Maps API key is not reused.** The key in the original manifest is
   platform-restricted to the original package name and signing certificate.
   The Map screen uses OpenStreetMap tiles instead, so no key is needed.
   Attribution is included in the manifest metadata.
2. **Force-update / in-app-update is UI-only.** The original used Play Core
   (`sp-react-native-in-app-update`) with `IAUUpdateKind.IMMEDIATE` and a store
   version check. The rebuilt modal renders identically and opens the Play
   Store listing, but it is never triggered because the store check requires a
   published listing and the original signing key.
3. **Feedback writes to a configurable endpoint, not Firestore.**
   The original wrote to the Firestore collection `feedback` with
   `{name,email,location,type,comment,platform:'android',createdAt}`. The
   rebuild posts the same payload to `FEEDBACK_ENDPOINT`; with no endpoint
   configured it keeps the original visible behaviour (success dialog, `goBack`).
4. **The `Credits` route was unreachable in the original** (registered on the
   stack, never pushed). It is reachable from Settings → Help & Support here
   because an unreachable screen is a defect, not behaviour worth reproducing.
5. **Firebase Analytics / Ad-ID collection is dropped.** The original enabled
   analytics, ad-id collection and Play Billing probes by default. None of that
   is reimplemented: no ads, billing or tracking SDKs are bundled.
6. **Play Integrity (`com.pairip`) is not reproduced.** The original APK is
   wrapped by Google Play's Pairip anti-tampering library. It is not
   circumvented and not reimplemented — this is a clean reimplementation.
7. **`StatusBar` colour changes** are handled by the Flutter system chrome
   rather than `react-native-navigation-bar-color`; the effect is the same
   (the header block drives the bar colour per screen).
8. **Golden coverage is intentionally narrow.** `test/golden_test.dart`
   pins the launch surface and the Home, Schedule and Settings tabs;
   `tool/render_screens_test.dart` can regenerate wider light/dark references
   locally. A pixel-perfect baseline of the original APK could not be captured
   because its native runtime is in an ABI split that is not present in the
   base APK. Screen-level parity is therefore verified from the decompiled
   styles and the generated Flutter references.

## 10. Recovered / recreated / unrecoverable

**Recovered verbatim from the APK**
- Framework identity (React Native + Hermes, bytecode version 98).
- Complete app module graph (1,053 modules reachable from `App.tsx`).
- All 28 routes, 601 stops, coordinates, schedules, frequencies, fares, line
  colours and agency names.
- The navigation graph: stack routes and the four bottom tabs.
- Both light and dark palettes, and the design tokens.
- Every user-visible string (transcribed in `reverse_engineering/strings.md`
  and the screen specs).
- The departure-time engine, stop index/search and the journey planner.
- 20 image assets plus the launcher icon at all five densities.
- The MaterialCommunityIcons glyph map (6,596 entries).
- Theme persistence (`AsyncStorage` key `themePreference`).

**Recreated (behaviour inferred, values recovered)**
- Journey scheduling/clock rendering, because `waitMinutesFrom`,
  `walkMinutesFor` and `formatDeparture` were inlined by Hermes and their
  bodies are not directly readable; the recovered constants (80 m/min,
  600 m walk radius, 2 min/stop, 3 × walk-minute transfer penalty) are used.
- The Schedule header colour (`activeCategory?.color ?? colors.primary`) —
  hermes-dec renders the null check with inverted polarity.
- `ThemePreference` default `'system'` follows `Appearance.getColorScheme()`.
- Screen sizes for the two bottom-nav icon variants and the exact switch
  thumb/track colours (both follow the palette).

**Unable to recover**
- Any server-side data: there is none (all data is bundled).
- The Pairip-protected code paths.
- Analytics and install-referrer payloads (excluded by design).
- The original signing certificate and release key (not needed, not reused).
- A pixel-exact visual baseline (see limitation 8).

## 11. Documentation

| Document | Contents |
|---|---|
| `../reverse_engineering/README.md` | index of the analysis |
| `../reverse_engineering/app_structure.md` | identity, framework proof, reverse-engineering method, entry chain |
| `../reverse_engineering/navigation.md` | stack + tab graphs and every navigation call |
| `../reverse_engineering/design_system.md` | colours, theme mechanism, typography, layout metrics, components |
| `../reverse_engineering/dependencies.md` | native + JS library inventory and the Flutter replacements |
| `../reverse_engineering/permissions.md` | permissions, providers, services, receivers, manifest metadata |
| `../reverse_engineering/storage_analysis.md` | the `themePreference` key and read/write behaviour |
| `../reverse_engineering/network_analysis.md` / `api_analysis.md` | what the app talks to and the legal position |
| `../reverse_engineering/assets.md` | every extracted asset with sizes and tints |
| `../reverse_engineering/strings.md` | all system and data strings |
| `../reverse_engineering/screens.md`, `features.md` | screen inventory |
| `../reverse_engineering/behavior_notes.md`, `unknowns.md` | behaviour and open questions |
| `../reverse_engineering/test_matrix.md` | the parity checklist |
| `../reverse_engineering/specs/*.md` | screen-by-screen implementation specs |
| `../reverse_engineering/REVERSE_ENGINEERING_REPORT.md` | the honest final report |
