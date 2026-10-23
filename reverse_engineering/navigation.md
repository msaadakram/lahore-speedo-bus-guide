# Navigation (recovered)

## Root — module `495 App.tsx`

```
SafeAreaProvider
└─ ThemeProvider                        (app colour context, module 571)
   └─ AppShell
      ├─ SystemBars style={isDark ? 'dark' : 'light'}
      ├─ NavigationContainer
      │  └─ Stack.Navigator id="MainStack"
      │       screenOptions={{ headerShown: false, animation: 'slide_from_right' }}
      └─ ForceUpdateModal (module 1079)
```

Stack route order (verbatim from `App.tsx`):

| # | Route name | Component | Module |
|---|---|---|---|
| 0 | `MainTabs` | `BottomTabs` | 557 |
| 1 | `Search` | `SearchScreen` | 1071 |
| 2 | `RouteDetail` | `RouteDetailScreen` | 1020 |
| 3 | `StopDetail` | `StopDetailScreen` | 1072 |
| 4 | `Map` | `MapScreen` | 1033 |
| 5 | `StopPicker` | `StopPickerScreen` | 1073 |
| 6 | `JourneyResults` | `JourneyResultsScreen` | 1075 |
| 7 | `JourneyDetail` | `JourneyDetailScreen` | 1076 |
| 8 | `Credits` | `CreditsScreen` | 1081 |
| 9 | `Feedback` | `FeedbackScreen` | 1082 |

- No deep links: `MainActivity` has no `BROWSABLE`/`VIEW` intent filter.
- No drawer. No nested navigators other than the bottom tabs (screen 0 of the stack).
- Android hardware back pops the stack; on `MainTabs` the bottom-tabs navigator returns to the
  initial tab and only then lets the activity be backgrounded.
- `launchMode="singleTask"` — the activity is reused, not recreated.
- Page transition animation is `slide_from_right` for the stack, `shift` for the tabs.

## Bottom tabs — module `557 BottomTabs.tsx`

`createBottomTabNavigator()`, `id='BottomTabs'`,
`screenOptions={{ headerShown: false, animation: 'shift' }}`, custom `tabBar` rendering React Native
Paper `BottomNavigation.Bar`:

| Tab | Component | `tabBarLabel` | icon inactive | icon active |
|---|---|---|---|---|
| 1 | `RouteFinderScreen` (569) | `Home` | `home-outline` | `home` |
| 2 | `NearbyScreen` (722) | `Nearby` | `map-marker-outline` | `map-marker` |
| 3 | `ScheduleScreen` (714) | `Schedule` | `bus-side` | `bus` |
| 4 | `SettingsScreen` (737) | `Settings` | `cog-outline` | `cog` |

All tab icons are **MaterialCommunityIcons**, size `24`.

## Cross-screen navigation (from the screen specs)

| From | Destinations |
|---|---|
| Home (569) | `RouteDetail`, `StopPicker`, `Search`, `Map`, `JourneyResults` |
| Schedule (714) | `RouteDetail` |
| Nearby (722) | `RouteDetail`, `StopDetail` |
| Search (1071) | `RouteDetail`, `StopDetail`, `JourneyResults` |
| RouteDetail (1020) | `StopDetail`, share intent |
| StopDetail (1072) | `RouteDetail`, external Maps |
| StopPicker (1073) | `JourneyResults` |
| Map (1033) | `RouteDetail`, `StopDetail`, external Maps directions |
| JourneyResults (1075) | `JourneyDetail` |
| JourneyDetail (1076) | share intent |
| Settings (737) | `Credits`, `Feedback`, external URLs, OS permission settings |
| Credits (1081) | back |
| Feedback (1082) | back |

Exact route-parameter names per screen are documented in `specs/*.md`.
