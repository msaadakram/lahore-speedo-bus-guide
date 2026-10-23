# Reverse-engineering workspace — Lahore Speedo Bus Guide

Analysis of `pC5WZ8Hc.apk` (`com.codez.lahoreelectricbusguide`, v2.1 / vc 12)
performed to enable a faithful Flutter rebuild in `../flutter_project/`.

> All content here is **data recovered from the supplied APK**. Nothing is
> invented; where something is inferred it is marked as such.

## Index

| Document | Contents |
|---|---|
| `app_structure.md` | identity, framework proof (React Native + Hermes), method, entry chain, module inventory |
| `screens.md` | screen inventory with route, purpose, entry/exit |
| `features.md` | feature inventory and where each is implemented |
| `navigation.md` | stack + bottom-tab graphs and every navigation call with params |
| `design_system.md` | colours, theme mechanism, typography, layout metrics, components |
| `dependencies.md` | native libraries, JS packages, and the Flutter replacements |
| `permissions.md` | permissions, providers, services, receivers, manifest metadata |
| `manifest_analysis.md` | manifest walk-through |
| `network_analysis.md` | what the app talks to and the legal position |
| `storage_analysis.md` | AsyncStorage usage (`themePreference`) |
| `strings.md` | system and data strings |
| `api_analysis.md` | data sources: bundled GTFS vs network |
| `assets.md` | extracted assets, sizes and tints |
| `behavior_notes.md` | cross-cutting behaviour (theme, status bar, back handling) |
| `unknowns.md` | open questions and inferred items |
| `test_matrix.md` | parity checklist |
| `REVERSE_ENGINEERING_REPORT.md` | honest final report: recovered / inferred / recreated / unrecoverable |

## `specs/` — per-screen implementation specs

| Spec | Screen | Metro module |
|---|---|---|
| `home_screen.md` | RouteFinderScreen (Home tab) | 569 |
| `schedule_screen.md` | ScheduleScreen + the departure engine | 714 / 735 |
| `nearby_screen.md` | NearbyScreen | 722 / 729 |
| `settings_screens.md` | Settings, Credits, Feedback, ForceUpdate | 737 / 1081 / 1082 / 1079 |
| `detail_screens.md` | RouteDetail, StopDetail, StopPicker, StopCard | 1020 / 1072 / 1073 / 1021 |
| `map_search_journey.md` | Map, Search, JourneyResults, JourneyDetail | 1033 / 1071 / 1075 / 1076 |

`App.tsx` (495), `BottomTabs.tsx` (557), `theme.ts` (576), `theme/tokens.ts`
(570), `categories.ts` (715), `routes.ts` (718), `gtfsData` (719) and
`stops.ts` (734) are documented inline in `app_structure.md`,
`navigation.md` and `design_system.md`.

## `extracted_data/`

`routes.json` — 28 routes, 601 stops, every coordinate/schedule/fare, plus the
five categories. Consumed by the Flutter app as `assets/data/routes.json`.

## `extracted_assets/`

`icons/` — 28 files (20 app icons + 5 library icons + 3 navigation-element
icons). `launcher/{mdpi…xxxhdpi}/` — the original launcher icons.

## `hermes/` — the working pipeline

```
hermes/
├── decompiled.js        20 MB register-machine dump from hermes-dec
├── graph.json           Metro __d graph: 1383 modules {deps, factory span}
├── module_map.json      module id -> source span
├── jsvalue.py           symbolic evaluator for literal data modules
├── graph.py             builds graph.json
├── modmap.py            module-id -> span
├── dump_module.py       dump a module by id / grep across modules
├── find_mod.py          find modules containing a literal string
├── pretty.py            boilerplate-free view of a module
├── appgraph.py          reachable-module closure from App.tsx
├── extract_data.py      GTFS extraction
├── extract_all_data.py  final dataset export
└── iconmaps/            materialcommunityicons.json (6596 entries),
                         ionicons.json (1338), other.json (286)
```

Regenerate with:

```bash
export PYTHONPATH=/path/to/hermes-dec/src
python3 graph.py            # rebuilds graph.json
python3 extract_all_data.py # rebuilds extracted_data/routes.json
```
