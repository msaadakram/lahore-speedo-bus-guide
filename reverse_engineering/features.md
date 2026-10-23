# Feature inventory

| Feature | Original location | Flutter location |
|---|---|---|
| Category tabs (Speedo/Metro/Orange Line/Electric) | `categories.ts` (715) + `ScheduleScreen` (714) | `data/models/category.dart`, `route_widgets.CategoryTab` |
| Route list with frequency + long name | `ScheduleScreen` (714) | `features/schedule/schedule_screen.dart` |
| Stop search (normalised substring, alphabetical) | `stops.ts` (734) | `data/repositories/stop_repository.dart` |
| Route + stop search screen | `SearchScreen` (1071) | `features/search/search_screen.dart` |
| FROM/TO planner with swap | `RouteFinderScreen` (569) | `features/home/home_screen.dart` |
| Stop picker + "Use current location" | `StopPickerScreen` (1073) | `features/stop_picker/stop_picker_screen.dart` |
| Haversine nearest-stop lookup | (1073)/(734) | `stop_repository.haversineMeters` |
| Nearby stops with walk distance/time | `NearbyScreen` (722) | `features/nearby/nearby_screen.dart` |
| Location permission + OS-settings recovery | (722)/(1491) | `core/services/location_service.dart` |
| Route details (fare/frequency/hours/stops) | `RouteDetailScreen` (1020) | `features/route_detail/route_detail_screen.dart` |
| Stop details (lines + next departures) | `StopDetailScreen` (1072) | `features/stop_detail/stop_detail_screen.dart` |
| Next-departure engine | `schedule.ts` (735) | `data/repositories/departures.dart` |
| Route share (`${name} · ${freq} \| ${hours}`) | (1020) | `route_detail_screen.dart` |
| Journey planner (direct + 1 transfer + walk transfer) | `journeys.ts` (734) | `data/repositories/journey_repository.dart` |
| Journey results / step-by-step detail | (1075)/(1076) | `features/journey_results/…`, `features/journey_detail/…` |
| Journey share (multi-line itinerary) | (1076) | `journey_detail_screen.dart` |
| Map with markers, polyline, sheet, directions | `MapScreen` (1033) | `features/map/map_screen.dart` |
| External Maps directions | (1033) | `url_launcher` (`maps/dir/?api=1…travelmode=transit`) |
| Dark Mode + `themePreference` persistence | `ThemeProvider` (571/572) | `app/theme/theme_controller.dart` |
| Status/navigation-bar tinting per screen | (555)/(577) | Flutter system chrome driven by the palette |
| Settings with disclaimer + external links | `SettingsScreen` (737) | `features/settings/settings_screen.dart` |
| Credits | `CreditsScreen` (1081) | `features/credits/credits_screen.dart` |
| Feedback form + Firestore write | `FeedbackScreen` (1082) | `core/services/feedback_service.dart` |
| Force-update prompt | `ForceUpdateModal` (1079) | `features/update/force_update_modal.dart` |
| Notification permission request | (1485) on bootstrap | `POST_NOTIFICATIONS` retained in the manifest |
| Offline operation | everything is bundled | everything is bundled |
