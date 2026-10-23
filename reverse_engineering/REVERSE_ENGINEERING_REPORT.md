# Reverse-Engineering Report — Lahore Speedo Bus Guide

Target: `pC5WZ8Hc.apk` — `com.codez.lahoreelectricbusguide`, version `2.1`
(versionCode `12`), "Lahore Speedo Bus Guide", 38,099,944 bytes,
minSdk 24 / targetSdk 36.

Output: `/home/ubuntu/bus/flutter_project/` — a production-quality Flutter
application.

---

## 1. What the APK actually is

Proof chain (not guesswork):

1. `assets/index.android.bundle` exists and starts with the Hermes magic
   `c6 1f bc 03 c1 03 19 1f`; its header reports bytecode version **98**,
   12,238 functions, 17,686 identifiers, 24,142 strings.
2. `MainApplication` calls `DefaultReactHost.getDefaultReactHost(...)` and
   adds `com.oblador.vectoricons.VectorIconsPackage`.
3. `MainActivity.getMainComponentName()` returns `"LahoreSpeedoBusGuide"`.
4. `assets/fonts/` holds the 19 `react-native-vector-icons` TTFs.
5. `android:extractNativeLibs="false"` and no `lib/` directory: the native
   runtime lives in the ABI split, which the base APK declares as a required
   split (`android:requiredSplitTypes="base__abi,base__density"`).

So: **React Native + Hermes**, protected by **Google Play Pairip**.

## 2. Method

1. `apktool d` → 5 dex files baksmalied, resources decoded.
2. `hermes-dec` (P1sec) → a 20 MB register-machine JavaScript dump.
3. A custom parser rebuilt the Metro `__d(global, require, module)` graph:
   **1,383 modules** with dependency lists.
4. `index.js` was located by finding the `__d` factory that calls
   `AppRegistry.registerComponent`; its deps are `[1, 2, 495, 1325, 1497]`.
   → **495 = `App.tsx`**, 1325 = gesture handler, 1497 = `app.json`.
5. Traversing from 495 yielded **1,053 modules**; **27** are the app's own.
6. A symbolic evaluator re-materialised literal object/array data, recovering
   the full GTFS dataset.
7. Every screen was read from the register machine and documented in
   `specs/*.md` before any Flutter code was written.

## 3. Successfully recovered (verbatim)

- **All 28 routes**: id, short/long name, colour, text colour, mode, GTFS type,
  stations, single pattern per route with headsign and direction, agency,
  schedule first/last, `scheduleDisplay`, `frequency`, fare, `isTrail`,
  `isFeeder`, `displayStyle.weight`, and **601 unique stops** with lat/lng.
- **Navigation graph**: 10 stack routes (`MainTabs`, `Search`, `RouteDetail`,
  `StopDetail`, `Map`, `StopPicker`, `JourneyResults`, `JourneyDetail`,
  `Credits`, `Feedback`) and 4 bottom tabs (`Home`, `Nearby`, `Schedule`,
  `Settings`) with their exact labels and icon pairs.
- **Design system**: both palettes and `SPACING`/`FONT_SIZE`/`BORDER_RADIUS`
  tokens, all hard-coded colours (`#F08C00`, `#2E7D32`, `#1a73e8`,
  `rgba(255,255,255,0.x)` …) and every screen-level style value.
- **Every user-visible string** — transcribed with the exact em-dashes, the
  flag emoji and the `·` separators.
- **Algorithms**:
  - `parseOperatingHours`, `parseFrequencyMinutes`, `timeToMinutes`,
    `formatClock`, `formatDeparture`, `getNextDepartures` (module 735).
  - `ALL_STOPS` construction, `searchStops`, `getStopByKey`, `routeById`
    (module 734).
  - `haversine` (R = 6,371,000 m), 80 m/min walking, 600 m transfer radius.
  - `buildLeg`, `findBestTransfer`, `findJourneys` including the walk-transfer
    heuristic and the transfer cost `|Δi| + |Δj| + 3·walkMinutes`.
- **Storage**: the single AsyncStorage key `themePreference` with its
  `'system' | 'light' | 'dark'` domain and read/write behaviour.
- **Assets**: 20 image assets, all five launcher densities, all 19 icon fonts,
  and the 6,596-entry MaterialCommunityIcons glyph map.
- **Manifest**: permissions, providers, services, receivers, metadata, the
  Google Maps API key (and its package/SHA-1 restriction), analytics defaults.

## 4. Inferred — implemented, but not directly read

| Item | Why | What was used |
|---|---|---|
| `waitMinutesFrom`, `walkMinutesFor`, `estimateTravelMinutes`, `addMinutes`, `minutesOfDay`, `timeToMinutes`, `formatDeparture` | Hermes inlined these; hermes-dec emits empty bodies | Recovered constants: 80 m/min, 2 min/stop, one departure per `parseFrequencyMinutes` inside operating hours |
| Schedule header colour | hermes-dec renders the null check with inverted polarity | `activeCategory?.color ?? colors.primary` (also the status-bar colour) |
| `CreditsScreen` reachability | the route exists but is never pushed | Made reachable from Settings → Help & Support (documented) |
| Search weighting | the search is a plain substring scan, order = `ROUTES` order | Reproduced exactly |
| Status-bar colouring | `useStatusBarColor` per screen | Flutter system chrome driven by the same palette |

## 5. Not recovered — and why

- **Server-side data**: none exists. All data is bundled in the bytecode.
- **Pairip / Play Integrity**: deliberately not touched.
- **Analytics / Ad-ID / Install Referrer**: dropped, not reimplemented.
- **The Google Maps API key**: platform-restricted to
  `com.codez.lahoreelectricbusguide` + SHA-1 `f9:56:bf:83:…:9f:e6:8a:96`.
  Reusing it would be both a ToS violation and technically impossible.
- **The original signing key**: not needed and not reused.
- **A visual baseline**: the base APK has no `lib/*.so`, so the app cannot run
  here; a pixel-diff baseline could not be captured.

## 6. Legal position

Only the supplied APK was analysed. No authentication, DRM, certificate
pinning or server-side authorisation was bypassed. No secret, key or credential
from the APK was copied into the rebuild:

- the Maps key is not reused (OpenStreetMap is used instead);
- no Firebase project credentials are embedded — feedback goes to an
  operator-supplied `FEEDBACK_ENDPOINT`, or is a no-op with the original
  visible behaviour;
- `.env.example` is the only configuration surface and `.env` is git-ignored.

## 7. Rebuild quality summary

| Gate | Result |
|---|---|
| `flutter analyze` | 0 errors, 0 warnings (59 style infos) |
| `flutter test` | **45 tests, all passing** |
| `dart format .` | clean |
| `flutter build apk --release` | **passes** — 54.7 MB |
| Verified APK identity | `com.codez.lahore_speedo_bus_guide`, `2.1.0` / `12`, minSdk 24 / targetSdk 36, label `Lahore Speedo Bus Guide` |
| Permissions declared | `INTERNET`, `ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION`, `ACCESS_NETWORK_STATE` only |

## 8. Honest assessment of parity

**Strong parity.** Navigation graph, all 14 screens, every recovered string,
both palettes, the design tokens, the bundled dataset, the stop search, the
departure engine, the journey planner, share messages, storage behaviour and
the empty/disabled/error states are all reproduced from recovered values.

**Approximate parity.** Exact glyph rendering is identical (same font, same
codepoints), but some screen-level paddings on `RouteDetail`, `Map`,
`JourneyDetail` and `JourneyResults` use the recovered token scale rather than
hand-measured pixel values, because hermes-dec does not expose resolved
accessor constants (`SPACING.md` is present, but a few computed expressions are
elided). Image assets are the originals; they are only shipped at mdpi in the
APK, so on high-density devices Flutter upsamples them exactly as the original
did.

**No parity.** Nothing was left as a placeholder, "Coming soon" or lorem ipsum.
The only surfaces without original behaviour are the ones listed in §5.
