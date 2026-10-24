# Play Store listing copy — Lahore Speedo Bus Guide

Package: `com.lahorebus` · Version: `2.1.0` (`versionCode 12`)
Privacy policy: <https://policy.msaadakram.me/> · Support: <https://policy.msaadakram.me/support>
Contact: <msaadakram786@gmail.com>

---

## App name (max 30)

Lahore Speedo Bus Guide

## Short description (max 80)

Offline Lahore bus routes, stops, schedules and journey planning.

## Full description (max 4000)

Lahore Speedo Bus Guide is a fast, offline-first guide to Lahore's bus network — Speedo, Metro, Orange Line and Electric buses. Browse routes and stops, check schedules, plan a journey and find the stops nearest to you. No ads, no account, no tracking.

FEATURES

• Complete route guide — every route with its stops in order, fare, frequency and operating hours.
• Stop search — find any stop by name.
• Journey planner — pick a starting stop and a destination to see the routes that connect them, including one-transfer trips.
• Schedules — first and last bus times and how often each route runs.
• Nearby stops — see the stops closest to your current location (optional; the app works without it).
• Works offline — route, stop and schedule data is bundled in the app. No signal needed for planning.
• Light and dark themes.
• No ads, no sign-in, no analytics.

ABOUT THE DATA

Route, stop and timetable information is compiled from publicly available bus-service information and is provided for guidance only. Services and timings can change without notice; always check official notices and on-ground information before travelling.

PRIVACY

The app does not collect, store or share personal information. Location is used only on your device to show nearby stops and is never sent to the developer. Read the full policy: https://policy.msaadakram.me/

FEEDBACK

Found a wrong stop, route or timing? Send a note from Settings → Send Feedback or email msaadakram786@gmail.com. Reports help keep the guide accurate.

## Release notes — 2.1.0 (12)

First release of the rebuilt app: a fresh design, faster startup, offline route and schedule data, journey planning, nearby stops and dark mode. No ads and no tracking.

---

# Store settings

| Field | Value |
|---|---|
| App category | Maps & Navigation |
| Tags | bus, Lahore, transit, timetable (as offered by Console) |
| Contact email | msaadakram786@gmail.com |
| Website | https://github.com/msaadakram/lahore-speedo-bus-guide |
| Privacy policy | https://policy.msaadakram.me/ |
| Ads | No ads |
| App access | All functionality available without login or special access |
| Target audience | 13+ (not designed for children) |
| Content rating | Utility / Productivity / Communication / Other → all answers **No** → Everyone |
| Government app | No |
| News app | No |
| COVID-19 app | No |
| Financial features | No |
| Health features | No |

If the apex-domain migration completes before submission, use
`https://msaadakram.me/` instead of the `policy.` URL (both are the same site).

# Data safety answers

| Question | Answer |
|---|---|
| Does the app collect or share any required user data? | **No** |
| Data types collected | None |
| Data types shared | None |
| Analytics / crash reporting | None |
| Advertising | None |
| Location | Accessed on-device only, with runtime permission, to sort stops by distance. Denying it leaves every other feature working. Not stored, logged or sent to the developer. |
| Map tiles | Map screens request imagery directly from OpenStreetMap / Esri; those providers see the device IP and requested map area under their own policies. No account or identifier is attached. |
| Data deletion | No server-side data exists; app preferences stay on the device and are removed by uninstalling. |

If the Console asks for a Data safety justification, the text above matches the
published policy (sections 2–4).

# Graphics

| Asset | File | Spec |
|---|---|---|
| App icon | `graphics/icon-512.png` | 512×512, 32-bit PNG, no alpha |
| Feature graphic | `graphics/feature-graphic-1024x500.png` | 1024×500 |
| Phone screenshots | `screenshots/01_home.png`, `02_schedule.png`, `03_home_filled.png` | 1080×1920 (9:16) |

Screenshots were captured from the signed release build (`com.lahorebus`)
on a 1080×1920 emulator at 420 dpi. Play accepts 2–8 phone screenshots; more can
be added later (journey results, route detail, privacy page, credits).

# Upload checklist

1. Play Console → **Create app** → name “Lahore Speedo Bus Guide”, default language
   English (United States), type **App**, **Free**.
2. **App integrity → Play App Signing**: enroll the upload key
   (`android/app/keystore/lahore-bus-release.jks`, alias `lahore-speedo-bus`).
   Certificate SHA-256:
   `9B:EA:27:07:D5:2F:69:42:03:ED:D6:F5:16:1A:E1:71:5C:B7:26:D3:FE:71:5D:2A:B1:9D:B7:C9:E8:AE:FD:FC`
3. **Production → Create new release** → upload
   `lahorebus-2.1.0-12.aab` (SHA-256
   `9074ea9a61dfe953a17eb11d4d1164cfc5847fa2b2af53d0bb028ba0f204e237`).
4. **Store listing** → paste the title, short and full descriptions above, upload
   icon, feature graphic and screenshots, set contact details and privacy URL.
5. **Data safety** → No data collected or shared (see table).
6. **Content rating** → complete questionnaire (no to every content question).
7. **Target audience** → 13+; **Ads** → No.
8. **Countries/regions** → Pakistan first (widen later if desired).
9. **Review and roll out** to production. Keep the signed AAB and this kit with
   the release record.

Upload key: back up `lahore-bus-release.jks` and `key.properties` somewhere safe.
Losing the key blocks every future update unless Play App Signing key reset is
approved.
