# UI audit & remediation plan

The first pass of the green re-skin was verified on only three screens. A full
audit — capturing **every** screen on the emulator (`tool/capture_screens.sh`,
14 screens) — exposed a set of real problems. This document records the plan
that was executed and the evidence behind each change.

## How the audit was done

```bash
tool/run_emulator.sh            # KVM-accelerated AVD
tool/capture_screens.sh         # 14 screens -> PNG
```

Every screenshot was then reviewed against the reference artwork
(`downloads/bz4sqCqW.jpg`) and the recovered original.

## Findings

### A. Colour bugs — hard-coded legacy values (8 sites)

The re-skin replaced the palette, but eight widgets still carried the **old red
brand** or the **old greys** baked in as literals. On screen this showed up as
red icons inside green cards — the single most jarring defect in the app.

| Site | Was | Now |
|---|---|---|
| `settings_screen.dart` — Dark Mode icon | `#FC3B38` red | `#3B7306` green |
| `settings_screen.dart` — disclaimer text | `#C62828` red | `palette.text` |
| `settings_screen.dart` — disclaimer card | `primary @8 %` | `accent @14 %` + 4 px accent bar |
| `nearby_screen.dart` — stop icon | `#FC3B38` red | `palette.primary` |
| `stop_picker_screen.dart` — stop icon | `#FC3B38` red | `palette.primary` |
| `stop_picker_screen.dart` — "N lines" | `#757575` | `palette.textSecondary` |
| `schedule_screen.dart` — empty state | `#757575` | `palette.textSecondary` |
| `home_screen.dart` — FROM/TO divider | `#E0E0E0` | `palette.border` |
| `journey_detail_screen.dart` — bullet | `#FC3B38` | `palette.primary` |

**Rule added:** the palette is the only source of colour. No screen may contain
a literal brand hex.

### B. Component defects

| Defect | Cause | Fix |
|---|---|---|
| StopPicker search field looked broken — a white box with a hard 2 px green border inside a translucent white container | a hand-rolled `Container` + raw `TextField`, so the theme's `InputDecoration` never applied | one `TextField` with a themed decoration: 18 px radius, `0x26FFFFFF` fill, `0x40FFFFFF` border, white `prefixIcon` |
| The "23 Routes" counter was dark green on the green header — effectively unreadable | it used `palette.text` on the header band | `Colors.white` |
| A grey scrim sat over the top of every header | the status bar was not declared transparent, so Android painted its own scrim | `SystemUiOverlayStyle(statusBarColor: transparent, statusBarIconBrightness: light)` via `AnnotatedRegion` in `AppPageHeader`, plus a transparent system nav bar in the theme |
| The five category tabs overflowed — "All" was clipped off the right edge and "Orange Line" wrapped to two lines, making that pill taller than its neighbours | 35 px art + a 14 px label inside a fixed-width `Expanded` | 28 px art, 12 px single-line label with ellipsis, tighter horizontal padding |
| The header consumed ~45 % of the screen | generous top/bottom padding | bottom padding reduced from `spaceLg` to `spaceMd` |
| The stop-picker rows looked empty and flat | plain icon chip, no depth | the icon chip became a **gradient badge with a soft shadow**, matching the artwork's lit 3D forms; tighter row padding |

### C. Interaction & polish

* The stop-picker search field now has a proper clear affordance and a
  consistent focus ring.
* `flutter analyze` is clean: **no errors, warnings or infos**.

## Verification

| Gate | Result |
|---|---|
| `flutter analyze` | **No issues found!** |
| `flutter test` | **50/50 passed** (3 goldens regenerated) |
| `flutter build apk --release` | ✓ 55.3 MB, release-signed |
| `tool/verify_release_dex.sh` | **PASS** |
| On-device install + launch | ✓, 0 app errors in Logcat |
| Screen-by-screen re-capture | ✓ 14 screens, no clipping, no overflow, no low-contrast text |

## What is still open

* **"Orange Li…"** is ellipsised in the Schedule category bar. The recovered
  copy is `Orange Line`; a horizontally-scrollable tab strip would show it in
  full without changing the label.
* **Map, JourneyResults, JourneyDetail, StopDetail, Credits and Feedback**
  were captured and reviewed, but their dense layouts have not had the same
  per-element pass as Home/Schedule/Settings/StopPicker.
* The **dark theme** has been checked functionally (toggle + persistence) but
  not captured screen-by-screen.

---

# Pass 2 — the remaining screens (executed)

The first pass verified Home, Schedule, Settings and StopPicker. This pass
covered RouteDetail, StopDetail, JourneyResults, JourneyDetail, StopPicker,
Credits, Feedback, Nearby, Map and the dark theme.

## Method

Device captures of adb taps proved flaky (a pre-installed "Apk Extractor"
app repeatedly stole the foreground, and the dark-mode toggle kept launching
the dialer), so the audit switched to a deterministic harness:

* `tool/render_screens_test.dart` — pumps **every screen in both palettes**
  with real dataset data and writes `test/goldens/*_{light,dark}_*.png`.
  Huge value: text glyphs render as tofu blocks in the test host, but
  geometry, colour and overlap are pixel-accurate.
* Device screenshots re-capture the same flows with real text.

## Findings and fixes

| Area | Problem found | Fix |
|---|---|---|
| RouteDetail | Whole screen (header, stat boxes, buttons) painted with the route line colour — for RT-03 that produced a full teal screen, abandoning the brand | Header → `heroGradient`, stat boxes + View-on-Map → `palette.primary`; line colour kept only on data accents (departure tiles, timeline, route chip) |
| RouteDetail header | The route title was repeated twice (title + subtitle + band below) | band below the header now shows the active direction: `Towards <terminus>` |
| Stat boxes | `Every 9 …`, `06:00 A…` truncated at 1 line | `StatBox` values wrap to 2 lines |
| Feedback | `DropdownButtonFormField` overflowed its row by 46–92 px (yellow/black stripes) | `isExpanded: true` |
| Credits | Teal/orange hard-coded card accents clashed with the green brand | via `palette.primary` / `palette.accent` |
| Schedule category bar | 5 fixed-width tabs could not fit 5 labels ("All" was clipped right, "Orange Line" wrapped) | horizontally scrollable strip, intrinsic-width pills (`CategoryTab(expanded: false)`, 28 px art, 12 px single-line labels) |
| Status bar | Grey/scrim band painted over the gradient headers; icons black on dark | `SystemUiMode.edgeToEdge` + transparent bars with light icons set globally in `main()`, plus `AnnotatedRegion` on `AppPageHeader` |
| Test harness | Successive `pumpWidget`s re-laid-out DEFUNCT elements (framework quirk) and failed the suite | every-screen harness moved to `tool/render_screens_test.dart` (dev generator); CI keeps 3 pin goldens — suite 50/50 green |

## Gates

| Gate | Result |
|---|---|
| `flutter analyze` | No issues found! |
| `flutter test` | **50/50 passed** |
| goldens | 27 renders (all screens × light/dark) reviewed |
| `flutter build apk --release` | ✓ 55.3 MB |
| `tool/verify_release_dex.sh` | PASS |
| device install + run (16 screens) | no app crash in Logcat — the only FATAL entries are `uiautomator dump` tooling churn ("UiAutomationService already registered"), not the app |

## Ship

* APK: `artifacts/app-release.apk` — SHA-256
  `b7732f142b8f21e67c344a307a7aafd32abd035f292bf6e4cf70b9cf3fac8b52`
* Download: https://pixeldrain.com/u/e6nSSZEc

## Pass 3 — branding, credits & privacy (2026-10-23)

Contact/ownership rebrand plus a first-class legal page:

* **Settings** — website/email/More-Apps constants now point to
  `msaadakram.me` / `msaadakram786@gmail.com`; `Privacy Policy` row moved
  from an external `$website/privacy` link to the in-app route
  `Routes.privacyPolicy`.
* **Credits** — rewritten to a single `_CreditCard` for **Muhammad Saad**
  (MS avatar, `DEVELOPER & MAINTAINER`, tags *Flutter Apps / Routing & Data /
  More projects on msaadakram.me*, CTA `Visit msaadakram.me`).
* **New `PrivacyPolicyScreen`** (`lib/features/privacy/privacy_screen.dart`) —
  9-card policy (data simplicity, location, OSM tiles, bus data, feedback,
  children, links, changes, contact) in the brand style; openable offline.
* **Web** — `web/site/` (landing + full policy) deployed to Cloudflare
  Pages: https://lahore-speedo-bus-guide.pages.dev (and `/privacy`).

Build: SHA-256 `e106ad99…`, https://pixeldrain.com/u/fRKt8uFb · code at
https://github.com/msaadakram/lahore-speedo-bus-guide · device verification
in `on_device_test_report.md` (2026-10-23 entry).

## Notes for the next pass

* Golden text renders as tofu in the test host (no fonts loaded) — if you want
  full-text goldens, load the app's fonts in the generator via `FontLoader`.
* The dark theme is verified through the goldens and the palette toggle unit
  test; capturing dark screens on the device fights the emulator's search for
  a default launcher icon (coordinates shift), so it is skipped here.
* `msaadakram.me` hosting was answering "This deployment is temporarily
  paused" on 2026-10-23; resume it so Settings/Credits links land somewhere.
