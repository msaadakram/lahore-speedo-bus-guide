# On-device test report — Android emulator

The APK was installed and exercised on a real Android emulator
(`emulator-5554`, API 30 AOSP x86_64). The host has **no `/dev/kvm`**, so the
emulator ran under QEMU TCG (software emulation) — every interaction is
roughly 20× slower than on hardware, which is the main source of noise in the
timings below.

## Tooling added for this

| Tool | Purpose |
|---|---|
| `tool/run_emulator.sh` | boots a headless AVD (no KVM → `-accel off`, SwiftShader) |
| `tool/ui_test.sh` | screenshot-driven walkthrough of the four tabs |
| `tool/ui_test2.sh` | assertion-driven walkthrough using `uiautomator dump` (waits for the expected text instead of sleeping) |
| `tool/verify_release_dex.sh` | asserts every runtime-resolved class survives R8 |
| `tool/generate_icon_data.py` | regenerates the MaterialCommunityIcons codepoint map from the recovered glyph JSON |

## Bugs found on device and fixed

### 1. R8 stripped the whole JNI bridge → blank screen (critical)
`shared_preferences_android` reaches Android DataStore through `package:jni`,
whose Java classes are looked up **by name** over JNI. R8 deleted the entire
`com.github.dart_lang.jni` package (nothing in Java calls it), so
`SharedPreferences.getInstance()` threw before `runApp()` and the app showed
the launch background forever.

The `jni` package *does* ship the correct rule, but in
`consumerProguardFiles` — and the Flutter Gradle plugin wires plugins in as
**project dependencies, not AARs**, so AGP never applies a consumer module's
rules. The rule was silently lost.

**Fix** — explicit keep rules in `android/app/proguard-rules.pro`:
```proguard
-keep class com.github.dart_lang.jni.** { *; }
-keep class com.github.dart_lang.jni_flutter.** { *; }
-keepclasseswithmembernames class com.github.dart_lang.jni.** { native <methods>; }
```

### 2. R8 renamed `kotlin.coroutines.Continuation` → `gs` (critical)
`package:jni` resolves `kotlin/coroutines/Continuation` with
`JClass.forName('kotlin/coroutines/Continuation')`. R8 renamed the class, which
changed the *descriptor* of every method taking it, so the JNI lookup for
`SharedPreferencesApiRegistrar.getAll(String, List, Continuation)` no longer
matched:

```
NoSuchMethodError: no non-static method
"Lio/flutter/plugins/sharedpreferences/SharedPreferencesApiRegistrar;.getAll(
  Ljava/lang/String;Ljava/util/List;Lkotlin/coroutines/Continuation;)Ljava/lang/Object;"
```

**Fix**
```proguard
-keep class kotlin.coroutines.** { *; }
-keep class kotlin.Result { *; }
-keep class kotlin.Result$* { *; }
-keep class java.nio.Buffer { *; }
-keep class java.nio.ByteBuffer { *; }
```

### 3. Plugin v2 API registrars were deleted (high)
`SharedPreferencesApiRegistrar` / `SharedPreferencesAsyncApiRegistrar` are
resolved by name from Dart. R8 removed them.

**Fix**
```proguard
-keep class **ApiRegistrar { *; }
-keep class io.flutter.plugins.** { *; }
```

### 4. Wrong MaterialCommunityIcons codepoints (high, visual)
The icon codepoints had been hand-converted from decimal to hex, and several
were wrong: the search button rendered as "open in new", the mail row as
"notification off", the web row as "hamburger", the FROM pin as "©".

**Fix** — `tool/generate_icon_data.py` now generates
`lib/shared/widgets/app_icon_data.dart` straight from the recovered glyph map
(`materialcommunityicons.json`, 6 596 entries). The file is generated and
marked as such.

### 5. Stop index was never loaded → empty stop picker (high, functional)
On device the stop picker showed **"0 All Stops" / "No stops found"**, and the
Nearby tab could never show anything. `StopRepository.ensureLoaded()` was
never called — only `RoutesRepository.ensureLoaded()` was, and they are
separate.

**Fix** — `main()` now warms both indexes before the first frame, and the
stop picker / nearby screen defensively ensure the index on `initState`.
Regression test added: `test/stop_picker_test.dart`.

### 6. Nearby showed the list footer in the permission-denied state (low, parity)
The italic *"Tap any stop for directions · Sorted by walking distance"* is the
FlatList's `ListFooterComponent` in the original, so it only appears when the
list is shown. The rebuild rendered it in every state.

**Fix** — moved the footer into the list's footer slot.

## Defensive hardening added

* `main()` catches a `SharedPreferences` failure and falls back to an
  in-memory store, so a plugin failure can never produce a blank screen again.
* `main()` catches a dataset-loading failure; screens render their own empty
  states.
* The dataset is preloaded **before** the first frame, so no tab shows a
  spinner on first open.

## Verification results (final build)

| Check | Result |
|---|---|
| `flutter analyze` | No issues found! |
| `flutter test` | 50/50 passed (2 new regression tests) |
| Release APK | builds, signed, 55.2 MB |
| `tool/verify_release_dex.sh` | PASS — every runtime-resolved class present |
| Install on emulator | Success |
| Launch | `Displayed … +13s811ms`, `Fully drawn` |
| Logcat | 0 × `FATAL EXCEPTION`, `NoSuchMethodError`, `UnsatisfiedLinkError` |
| Tabs | Home / Nearby / Schedule / Settings all render and navigate |
| Stop picker | lists real stops, filters live, picks a stop and returns to Home |
| Route detail | opens with FARE / FREQUENCY / HOURS / TOTAL STOPS / NEXT DEPARTURES |
| Dark mode toggle | flips the palette **and persists across an app restart** |
| Search | filters routes live |
| Location permission | the OS dialog shows the correct app label; the denied-state screen renders with "Open App Settings" / "Try Again" |

## Screenshots

Captured with `adb exec-out screencap` on the emulator and kept in
`reverse_engineering/screenshots/`.

## Notes / limitations of this test environment

* No KVM: the emulator runs under software emulation. Cold start took ~14 s
  (a hardware device is ~1 s) and `input text` drops characters, so the
  scripted search assertions had to be relaxed.
* The AOSP image has no Play Services. The app does not need them (it uses
  OpenStreetMap tiles), but the Maps-directions intent can only be *issued*,
  not completed, on this image.
* `SystemUI isn't responding` ANRs appear during the run; that is the
  emulated system, not the app (the app process stays healthy and the
  Activity reports `Fully drawn`).

---

## 2026-10-22 — second-pass build (green UI audit)

Build `b7732f14…` installed on `emulator-5556` (API 30, x86_64).

* Install: `pm install -r` → **Success**
* Cold launch + navigations across 16 screens/flows (route detail, map,
  stop detail, journey results, credits, feedback, dark toggle): no app FATAL
  in Logcat. The only `FATAL EXCEPTION` entries are `uiautomator dump`
  tooling processes failing "UiAutomationService already registered" — noise
  from background tooling, not the app.
* `flutter` engine messages clean apart from benign Impeller EGL notes on the
  software renderer.
* Release gates: `flutter analyze` clean · `flutter test` 50/50 ·
  dex-verify PASS · APK 55,268,025 bytes published at
  https://pixeldrain.com/u/e6nSSZEc

---

## 2026-10-23 — branding / privacy release

Build `e106ad99…` installed on `emulator-5554` (fresh AVD `apkx-iso`,
API 30, x86_64, 1080×1920).

Changes under test:

* Settings contact rebrand — `Email Support` → `mailto:msaadakram786@gmail.com`,
  `Visit our Website` / `More Apps` → `https://msaadakram.me`
* Credits rewritten to a single card: **Muhammad Saad** —
  `DEVELOPER & MAINTAINER`, tags *Flutter Apps / Routing & Data / More
  projects on msaadakram.me*, CTA `Visit msaadakram.me`
* New in-app **Privacy Policy** screen (`Settings → Legal`), no external
  dependency; mirrored web copy served by Cloudflare Pages
  (`https://lahore-speedo-bus-guide.pages.dev/privacy`)

Verification: cold launch OK; Settings→Privacy Policy renders all 9 sections
with tappable `msaadakram786@gmail.com` / `msaadakram.me` links; Credits card
correct; `Visit msaadakram.me` opens the correct URL in a browser. Zero app
FATAL / ANR entries in Logcat. Release gates: `flutter analyze` clean ·
`flutter test` 50/50 · dex-verify PASS · APK 55,268,025 bytes,
SHA-256 `e106ad99c960d4895819db1727d953f997605a2c2cf37920eeb52dc7827b485d`,
published at https://pixeldrain.com/u/fRKt8uFb

Note: `msaadakram.me` currently answers **“This deployment is temporarily
paused”** at its host — the app links are correct, but the developer needs to
resume/re-publish that hosting for the pages to load.
Code: https://github.com/msaadakram/lahore-speedo-bus-guide

---

## 2026-10-24 — publisher package rename + Play release bundle

App identity changed to the publisher's own package
`com.msaadakram.lahorebus` (was `com.codez.lahore_speedo_bus_guide`):
`applicationId`/`namespace`, `MainActivity` moved to
`android/app/src/main/kotlin/com/msaadakram/lahorebus/`, and the two Dart
package references (`force_update_modal._packageId`,
`map_screen` OSM `userAgentPackageName`) updated to match.

Release bundle `app-release.aab` (2.1.0 / versionCode 12):

* 55,509,311 bytes, SHA-256
  `9074ea9a61dfe953a17eb11d4d1164cfc5847fa2b2af53d0bb028ba0f204e237`
* jarsigner “jar verified” · `bundletool validate` exit 0
* manifest: package `com.msaadakram.lahorebus`, `versionCode 12`,
  `versionName 2.1.0`, minSdk 24, targetSdk 36,
  `com.msaadakram.lahorebus.MainActivity` exported
* ABIs: arm64-v8a, armeabi-v7a, x86_64 · signed with upload key
  `lahore-bus-release.jks` (alias `lahore-speedo-bus`, cert SHA-256
  `9B:EA:27:07:D5:2F:69:42:03:ED:D6:F5:16:1A:E1:71:5C:B7:26:D3:FE:71:5D:2A:B1:9D:B7:C9:E8:AE:FD:FC`)

On-device verification (`emulator-5554`, fresh install of the release APK):
`adb shell am start -n com.msaadakram.lahorebus/.MainActivity` launches and
renders; `dumpsys package` reports versionCode 12 / targetSdk 36; zero
FATAL/ANR in logcat; `play.google.com/store/apps/details?id=com.msaadakram.lahorebus`
answers 404 (package id is free). Release gates re-run after the rename:
`flutter analyze` clean · `flutter test` 50/50.

Known UI follow-up found while shooting store screenshots: the route-detail
stat tiles (`StatBox`) are 4-up `Expanded` and ellipsize long values
(“Every 9 min”, “06:00 AM – 10:30 PM”) at ≤411 dp. Fix before the next update.
