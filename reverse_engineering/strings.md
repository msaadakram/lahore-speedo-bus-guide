# Strings (recovered)

The application is **English-only** (`locales: --_--` in the APK). All user-visible strings are
therefore literal JS strings inside the bundle. Complete per-screen lists live in `specs/*.md`;
this file covers the global/system strings and the data-derived strings.

## System strings (from `res/values/strings.xml` + bundle)
| Where | String |
|---|---|
| Launcher / app label | `Lahore Speedo Bus Guide` |
| `LahoreSpeedoBusGuide` | Metro component name (`app.json` → `{ "name": "LahoreSpeedoBusGuide", "displayName": "LahoreSpeedoBusGuide" }`) |

## Tab labels (module 557, verbatim)
`Home`, `Nearby`, `Schedule`, `Settings`

## Route/category labels (module 715, verbatim)
`Speedo`, `Metro`, `Orange Line`, `Electric`, `All`

## Route names (28, verbatim `shortName` / `longName`)
| id | name | longName |
|---|---|---|
| `pma-lahore-59` | Electric RT20 | Jinnah Bus Terminal to Raiwind |
| `pma-lahore-58` | Electric RT26 | Jinnah Bus Terminal  To BRB |
| `lahore-ptc-33` | EV03 | Depot Stop to Railway Station |
| `pma-lahore-2` | Metro Bus | Shahdara to Gajumata |
| `pma-lahore-1` | Orange Line | Ali Town to Dera Gujran |
| `pma-lahore-239` | Speedo RT-03 | Rana Town to Railway Station |
| `pma-lahore-240` | Speedo RT-04 | R.A. Bazar to Chungi Amar Sidhu |
| `pma-lahore-241` | Speedo RT-05 | Bhatti Chowk to Shadbagh Underpass |
| `pma-lahore-242` | Speedo RT-07 | Depot Chowk to Chungi Amer Sidhu |
| `pma-lahore-243` | Speedo RT-08 | Canal to Jinnah Terminal |
| `pma-lahore-244` | Speedo RT-09 | Railway Station to Gulshan Ravi OL Station |
| `pma-lahore-245` | Speedo RT-10 | Wahdat Road Station to Qartaba Chowk |
| `pma-lahore-246` | Speedo RT-11 | Main Market Gulberg to Babu Sabu |
| `pma-lahore-247` | Speedo RT-12 | R.A Bazar to Nasir Bagh |
| `pma-lahore-248` | Speedo RT-13 | Depot Chowk to Kalma Chowk |
| `pma-lahore-249` | Speedo RT-14 | Purana Kahna to R.A Bazar |
| `pma-lahore-250` | Speedo RT-15 | Bhatti to R.A Bazar |
| `pma-lahore-251` | Speedo RT-16 | Canal to Jinnah Terminal |
| `pma-lahore-252` | Speedo RT-17 | Gajjumata to Rangers Wing Headquarter |
| `pma-lahore-253` | Speedo RT-18 | Bhatti Chowk to Mandiali Toll Plaza |
| `pma-lahore-254` | Speedo RT-19 | Paragon City to Railway Station |
| `pma-lahore-260` | Speedo RT-20 | Mull Adda to Jinnah Bus Terminal |
| `pma-lahore-255` | Speedo RT-21 | Shalamar station to Khaira Pull |
| `pma-lahore-257` | Speedo RT-23 | Canal to Chung |
| `pma-lahore-258` | Speedo RT-24 | KSK to Railway Station |
| `pma-lahore-259` | Speedo RT-25 | Askari X to Airport |
| `pma-lahore-270` | Speedo RT-27 | Jinnah Bus Terminal to Bahria Town |
| `pma-lahore-272` | Speedo RT-28 | Samanabad to Gulshan Ravi Double Sarka |

## Agency / schedule / frequency strings (verbatim)
`PMA Lahore`, `06:00 AM - 10:00 PM`, `06:30 AM - 9:00 PM` (varies per route),
`Every 10-30 minutes`, `Every 10-20 minutes`, `Every 25 minutes`, etc.
—— all values are preserved in `extracted_data/routes.json`.

## Other global copy observed in the bundle
`Bus times may vary due to traffic conditions`, `No more buses today`,
`Bus stops close to you`, `Bus Schedule`, `All Bus Types`, `Find Routes`,
`Lahore`, `Lahore Zoo`, `Lahore PTC`, `Somi Center Bus Stop`, `Pulley Bus Stop`,
`Nursary Bus Stop`, `Mull Adda to Jinnah Bus Terminal`, `Raiwind to Jinnah Bus Terminal`,
`Jinnah Bus Terminal to Raiwind`, `Jinnah Bus Terminal to Bahria Town`,
`Jinnah Bus Terminal  To BRB`, `Bahria Town to Jinnah Bus Terminal`,
`City Bus Stand`, `Chungi Metro Station`, `Canal Metro Bus St`, `Shahdara Metro Station`,
`University of Lahore`, `Lahore College Women`.

> Screen-level strings are deliberately kept out of this file to avoid duplication; see
> `specs/home_screen.md`, `specs/schedule_screen.md`, `specs/nearby_screen.md`,
> `specs/settings_screens.md`, `specs/detail_screens.md`, `specs/map_search_journey.md`.
