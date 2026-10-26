# Lahore Speedo Bus Guide

An offline companion app for the Lahore bus network — every route, stop and
schedule in one place, with journey planning, live-style stop browsing, a
nearby-stops finder and an offline map.

Built with **Flutter 3.47** (Riverpod + a typed custom navigator), package
`com.lahorebus`, version 2.1 (build 13).

## Features

- **Home** — search routes/stops, jump straight into journey planning
- **Nearby** — stops around you (on-device distance calc, optional location)
- **Schedule** — per-category timetables for every bus line
- **Route & journey details** — full stop sequences, timelines and running times
- **Offline map** — OpenStreetMap tiles with every stop pinned
- **Settings / Credits / Privacy** — theme control, feedback form, full in-app privacy policy

## Repository layout

```
flutter_project/         # the complete Flutter app (run `flutter run` here)
  android/ ios/          # platform shells
  assets/dataset/        # bundled Lahore bus dataset (routes, stops, times)
  lib/                   # Dart source: features/, app/, core/, shared/
  tool/                  # dev-only scripts (golden screenshot generator, etc.)
  web/site/              # static support site (landing + privacy policy)
reverse_engineering/     # RE notes, UI audit, on-device test report, screenshots
```

## Build

```bash
cd flutter_project
flutter pub get
flutter run                 # debug
flutter build apk --release # signed release (needs your own keystore + key.properties)
```

The release signing credentials are **not** in the repo — drop your
`android/key.properties` and keystore file in place, or build a debug signed APK.

## Privacy

The app collects **no personal data** — no accounts, no analytics, no ads.
Full policy: <https://lahore-speedo-bus-guide.pages.dev/privacy>
(also readable offline inside the app under *Settings → Privacy Policy*).

## Credits

Designed, rebuilt and maintained by **Muhammad Saad** —
[msaadakram.me](https://msaadakram.me) ·
[msaadakram786@gmail.com](mailto:msaadakram786@gmail.com)

More projects on the website.

## Data source

Routes, stops and timetables reference the public network of the **Punjab
Mass Transit Authority** ([etransit.punjab.gov.pk](https://etransit.punjab.gov.pk)).
Map imagery © [OpenStreetMap](https://www.openstreetmap.org/copyright) contributors.

## License

[MIT](LICENSE) © 2026 Muhammad Saad
