# Assets (recovered from the APK)

## Image assets — `/assets/src/assets/icons/*` (20 files)

All are **present in the APK** as Android drawables (`res/drawable-mdpi/src_assets_icons_*.jpg`
and `.png`), registered through Metro's `registerAsset`. Extracted to
`reverse_engineering/extracted_assets/icons/`.

| Metro name | File | Nominal size |
|---|---|---|
| `bus` | `src_assets_icons_bus.jpg` | 48×48 (@1x) |
| `bus2` | `src_assets_icons_bus2.jpg` | 48×48 |
| `speedo` | `src_assets_icons_speedo.jpg` | 48×48 |
| `metro` | `src_assets_icons_metro.jpg` | 48×48 |
| `electric` | `src_assets_icons_electric.jpg` | 48×48 |
| `orangeline` | `src_assets_icons_orangeline.jpg` | 48×48 |
| `filter` | `src_assets_icons_filter.jpg` | 48×48 |
| `search` | `src_assets_icons_search.jpg` | 48×48 |
| `search-icon` | `node_modules_reactnavigation_elements_lib_module_assets_searchicon.png` | — |
| `arrow-right` | `src_assets_icons_arrowright.jpg` | 64×64 |
| `location` | `src_assets_icons_location.jpg` | 48×48 |
| `location-map` | `src_assets_icons_locationmap.jpg` | 48×48 |
| `location-direction` | `src_assets_icons_locationdirection.jpg` | 48×48 |
| `route` | `src_assets_icons_route.jpg` | 48×48 |
| `back` | `src_assets_icons_back.jpg` | 48×48 |
| `back-icon` | `node_modules_reactnavigation_elements_lib_module_assets_backicon.png` | — |
| `back-icon-mask` | `node_modules_reactnavigation_elements_lib_module_assets_backiconmask.png` | — |
| `share` | `src_assets_icons_share.jpg` | 48×48 |
| `clock` | `src_assets_icons_clock.jpg` | 48×48 |
| `clock-filled` | `src_assets_icons_clockfilled.jpg` | 48×48 |
| `loop` | `src_assets_icons_loop.jpg` | 48×48 |
| `stop` | `src_assets_icons_stop.jpg` | 48×48 |
| `alert` | `src_assets_icons_alert.jpg` | 48×48 |
| `clear-icon` | `node_modules_reactnavigation_elements_lib_module_assets_clearicon.png` | — |
| `close-icon` | `node_modules_reactnavigation_elements_lib_module_assets_closeicon.png` | — |
| `close` | `node_modules_reactnativeelementdropdown_src_assets_close.png` | — |
| `down` | `node_modules_reactnativeelementdropdown_src_assets_down.png` | — |

> `res/raw/keep.xml` confirms the exact asset names the build keeps.

## Fonts — `assets/fonts/*.ttf` (19 files, all from `react-native-vector-icons`)
`AntDesign.ttf`, `Entypo.ttf`, `EvilIcons.ttf`, `Feather.ttf`, `FontAwesome.ttf`,
`FontAwesome5_Brands.ttf`, `FontAwesome5_Regular.ttf`, `FontAwesome5_Solid.ttf`,
`FontAwesome6_Brands.ttf`, `FontAwesome6_Regular.ttf`, `FontAwesome6_Solid.ttf`,
`Fontisto.ttf`, `Foundation.ttf`, `Ionicons.ttf`, `MaterialCommunityIcons.ttf`,
`MaterialIcons.ttf`, `Octicons.ttf`, `SimpleLineIcons.ttf`, `Zocial.ttf`.

The app itself only uses **MaterialCommunityIcons**, **Ionicons** and **MaterialIcons**
(the icon-name→glyph maps for all three are present in the bundle as module data).
Icon names actually used are listed in `specs/*.md` and the full glyph map was extracted to
`hermes/iconmaps/`.

## Launcher icon
`res/mipmap-{m,h,x,xx,xxx}hdpi/ic_launcher.png` and `ic_launcher_round.png`
(5 densities, all extracted to `reverse_engineering/extracted_assets/launcher/`).

## Data
`extracted_data/routes.json` — 28 routes, 601 unique stops, all coordinates/schedules/fares.

## No other assets
There are no Lottie files, no SVGs, no video/audio, no WebView HTML bundles. `res/anim`,
`res/animator`, `res/interpolator`, `res/drawable` entries are exclusively library resources
(React Native, AppCompat, Material).
