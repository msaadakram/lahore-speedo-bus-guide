# Parity / test matrix

Colour key: ✅ recovered and reproduced · ⚠️ reproduced from inference · ❌ not reproduced.

## Navigation
| Item | Original | Flutter | Status |
|---|---|---|---|
| 10 stack routes, names and order | App.tsx | `Routes` + `AppRouter` | ✅ |
| 4 bottom tabs, labels, icon pairs | BottomTabs.tsx | `AppBottomNav` | ✅ |
| `headerShown: false` + `slide_from_right` | App.tsx | custom page transition | ✅ |
| Tabs `animation: 'shift'` | BottomTabs.tsx | fade-switch in `MainTabsHost` | ✅ |
| Back-to-initial-tab behaviour | bottom tabs | default `Navigator` + index switch | ⚠️ |
| Deep links | none | none | ✅ |

## Screens
| Screen | Recovered copy | Style values | Interactions | Status |
|---|---|---|---|---|
| Home / RouteFinder | ✅ | ✅ (spec) | ✅ (5 handlers) | ✅ |
| Schedule | ✅ | ✅ (spec) | ✅ (category switch, search, row) | ✅ |
| Nearby | ✅ | ✅ (spec) | ✅ (reload, 2 recoveries, rows) | ✅ |
| Settings | ✅ | ✅ (spec) | ✅ (toggle, 8 rows) | ✅ |
| Search | ✅ | ✅ (spec) | ✅ (live filter) | ✅ |
| RouteDetail | ✅ | ⚠️ | ✅ (share, direction switch, map, stop rows) | ⚠️ |
| StopDetail | ✅ | ✅ | ✅ (route rows, map) | ✅ |
| StopPicker | ✅ | ✅ | ✅ (search, locate, pick) | ✅ |
| JourneyResults | ✅ | ⚠️ | ✅ (row → detail) | ⚠️ |
| JourneyDetail | ✅ | ⚠️ | ✅ (expand legs, share) | ⚠️ |
| Map | ✅ | ⚠️ | ✅ (markers, type toggle, sheet, directions, fit) | ⚠️ |
| Credits | ✅ | ✅ | ✅ (LinkedIn links) | ✅ |
| Feedback | ✅ | ✅ | ✅ (validation, submit, alerts) | ✅ |
| ForceUpdate | ✅ | ✅ | ✅ (CTA → Play Store; trigger absent) | ⚠️ |

## Data & logic
| Item | Status |
|---|---|
| 28 routes / 601 stops / coordinates / schedules / fares / colours | ✅ |
| `categoryOf` rule | ✅ (tested for all 28 routes) |
| `CATEGORIES` colours and labels | ✅ |
| `searchStops` normalised substring match | ✅ |
| haversine (R = 6,371,000 m) | ✅ |
| `parseOperatingHours` / `parseFrequencyMinutes` / `formatClock` | ✅ |
| `getNextDepartures` (limit 5, `Due`, `N min`, `[]` after close) | ✅ |
| `buildLeg` forward + reversed | ✅ |
| `findBestTransfer` shared-stop and walk-transfer branches | ✅ |
| `findJourneys` direct + one-transfer, limit 8 | ⚠️ |
| share messages (route and journey) | ✅ |
| `themePreference` read/write | ✅ |

## Non-goals
| Item | Status |
|---|---|
| Google Maps key reuse | ❌ (legal; OSM used) |
| Firestore backend | ❌ (endpoint configurable) |
| Analytics / Ad-ID / Billing | ❌ (removed) |
| Pairip / Play Integrity | ❌ (not circumscribed, not reproduced) |
| Pixel-golden CI | ❌ (no device for the original APK) |
