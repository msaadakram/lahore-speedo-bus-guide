# Network & Backend (recovered, legitimately)

## Architecture summary
The app is **offline-first**: every route, stop, coordinate, schedule, frequency and fare is
**bundled inside the Hermes bytecode** (see `extracted_data/routes.json` – 28 routes / 601 stops).
There is no REST API, no GraphQL, no WebSocket and no hard-coded base URL in the bundle.

Network traffic is therefore limited to:

| Destination | Purpose | Evidence |
|---|---|---|
| `*.googleapis.com` (Firestore) | Feedback submissions | `@react-native-firebase/firestore` registers in the manifest; `FeedbackScreen` writes a document |
| `*.google-analytics.com` / `app-measurement.com` | Firebase Analytics collection (**on by default** via manifest metadata) | `firebase_analytics_collection_enabled=true`, `google_analytics_adid_collection_enabled=true` |
| `ssl.gstatic.com` / `play.googleapis.com` | Firebase Installations, Play services, Play Billing probes | `ComponentDiscoveryService` registrars, `com.android.vending.CHECK_LICENSE`, `org.chromium.intent.action.PAY` queries |
| Play Store / Play Integrity | In-app update check + Pairip attestation | `sp-react-native-in-app-update` (`IAUUpdateKind.IMMEDIATE`), `com.pairip.application.Application` |
| OSM tile servers | Map tiles (MapScreen) | `react-native-maps` provider selection; default provider is `google` when installed, otherwise the bundled tile source |

## String evidence collected from the bundle
No `http://` / base URLs appear in the recovered application modules. The only URLs are:
- `https://` links opened from the Settings/Credits screens (see `specs/settings_screens.md`),
- the Google Maps directions URL built on the Map/StopDetail screens (see
  `specs/map_search_journey.md` / `specs/detail_screens.md`),
- the Play Store `market://` / `https://play.google.com/store/apps/details?id=...` link used by
  `ForceUpdateModal`.

## Legal / security position
- The **Google Maps API key is not reused.** It is a platform key restricted by package name
  `com.codez.lahoreelectricbusguide` and SHA‑1 `f9:56:bf:83:…:9f:e6:8a:96`; using it elsewhere is
  both a ToS violation and technically impossible. The rebuild uses OpenStreetMap tiles.
- No authentication, DRM, certificate pinning or server-side authorisation is bypassed.
  The Pairip/Play-integrity wrapper is not removed or circumvented — it simply does not exist in
  the rebuild, which is a clean-room reimplementation of the *visible* behaviour.
- Firestore credentials are supplied at build time via `.env` (`FIRESTORE_PROJECT_ID` /
  `FIRESTORE_API_KEY`), never committed.

## Flutter equivalent
- `dio`/`http` is only pulled in for the optional feedback submission path.
- Map tiles via `flutter_map` + OSM (or `google_maps_flutter` if the operator supplies a key).
