# Screen inventory

Legend: **Route** is the React Navigation stack route; **Tab** marks the four
bottom-tabs entry points.

| # | Screen | Route | Purpose | Entry | Exit |
|---|---|---|---|---|---|
| 1 | `RouteFinderScreen` | `MainTabs` → Home | Trip planner: pick FROM/TO, "Find Routes" | tab 0 | → `Search`, `StopPicker`, `JourneyResults` |
| 2 | `NearbyScreen` | `MainTabs` → Nearby | Stops near the device, sorted by walking distance | tab 1 | → `StopDetail` |
| 3 | `ScheduleScreen` | `MainTabs` → Schedule | Category tabs + all routes with frequency | tab 2 | → `Search`, `RouteDetail` |
| 4 | `SettingsScreen` | `MainTabs` → Settings | Dark Mode, disclaimer, links | tab 3 | → `Feedback`, OS settings, external URLs |
| 5 | `SearchScreen` | `Search` | Search routes by name/stop | Home & Schedule header | → `RouteDetail` |
| 6 | `RouteDetailScreen` | `RouteDetail` | Stats, next departures, stop list, share, map | Schedule rows, Search rows, StopDetail | → `StopDetail`, share intent, `Map` |
| 7 | `StopDetailScreen` | `StopDetail` | Lines serving a stop + next departures | Nearby rows, Map marker, RouteDetail stops | → `RouteDetail`, `Map` |
| 8 | `MapScreen` | `Map` | Route/stop map + bottom sheet + directions | RouteDetail, StopDetail | → `StopDetail`, `RouteDetail`, external Maps |
| 9 | `StopPickerScreen` | `StopPicker` | Search stops / use current location | Home FROM/TO | pops a selected stop |
| 10 | `JourneyResultsScreen` | `JourneyResults` | Direct/1-transfer journeys | Home "Find Routes" | → `JourneyDetail` |
| 11 | `JourneyDetailScreen` | `JourneyDetail` | Step-by-step legs, stats, share | JourneyResults rows | share intent |
| 12 | `CreditsScreen` | `Credits` | Team cards + LinkedIn links (unreachable in the original) | Settings → Help (added here) | back |
| 13 | `FeedbackScreen` | `Feedback` | 5-field form → Firestore `feedback` | Settings rows | back |
| 14 | `ForceUpdateModal` | overlay | Store-update prompt (`IAUUpdateKind.IMMEDIATE`) | `AppShell` update check | Play Store |

Splash/onboarding/login/registration/profile/edit screens do **not** exist in
the original — there is no authentication of any kind.
