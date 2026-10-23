# ScheduleScreen (the "Schedule" bottom tab) — Implementation Spec

Reverse-engineered from the Hermes/Metro module graph of **Lahore Speedo Bus Guide**
(`com.codez.lahoreelectricbusguide`, v2.1). Every number, colour, string and asset name below
is verbatim from the decompiled register machine — nothing is inferred except where explicitly
marked *[inferred]*.

Primary sources:

| Module ID | File | Role |
|---|---|---|
| **714** | `m714.js` | `ScheduleScreen` + local `CategoryTab` — **the Schedule tab screen** |
| **715** | `m715.js` | `CATEGORIES`, `CATEGORIES_FOR_SEARCH`, `getCategoryColor`, `renderBusIcon` |
| **735** | `m735.js` | `parseOperatingHours`, `parseFrequencyMinutes`, `formatClock`, `getNextDepartures` (+ internal `timeToMinutes`, `formatDeparture`) |
| **569** | `m569.js` | `RouteFinderScreen` — the *Home* tab; used here only for navigation context |
| 557 | `m557.js` | `BottomTabs` — registers the `Schedule` tab screen |
| 570 | `m570.js` | layout tokens: `SPACING`, `FONT_SIZE`, `BORDER_RADIUS` |
| 576 | `m576.js` | colour tokens: `COLORS`, `DARK_COLORS` |
| 571 | `m571.js` | `ThemeProvider` / `useTheme` |
| 577 | `m577.js` | `useStatusBarColor` |
| 700 | `m700.js` | `SafeAreaView` (react-native-safe-area-context) |
| 718 | `m718.js` | `ROUTES` (built from the bundled GTFS `lines` array) |
| 720 / 721 | `m720.js` / `m721.js` | image assets `search`, `arrow-right` |
| 1025 | `m1025.js` | `useNextDepartures` — the hook that consumes module 735 (NOT used by 714) |

---

## 0. Scope note

* The Schedule tab screen (**m714**) renders **only** a category chip strip + a list of routes
  (name / frequency / long address). It shows **no departure times**.
* The departure-time engine (**m735**) is **not imported by m714** (m714's deps are
  `[1, 32, 69, 2, 238, 570, 571, 715, 577, 700, 720, 721]` — no 735). It is consumed by
  `useNextDepartures` (m1025), used by `RouteDetailScreen` (m1020) and `StopDetailScreen`
  (m1072). It is documented in full in §7 because the Schedule tab is the screen the departure
  data is read *from* (route rows → RouteDetail → live departures).

---

## 1. Components & helper functions

### 1.1 `ScheduleScreen` (m714, default export)

**Signature:** `ScheduleScreen({ navigation })` — the only prop read from `a0` is
`navigation` (React Navigation screen props). No `route` prop is read.

**Behaviour:** renders a coloured header (title + search shortcut + horizontally laid-out
category chips), a "{n} Routes" count row, and a static-scrolling `FlatList` of route cards for
the currently selected category. Three pieces of local state mirror each other; tapping a chip
replaces all three.

**Dependencies (decoded — dep index is the position in `deps=[1, 32, 69, 2, 238, 570, 571, 715, 577, 700, 720, 721]`):**

| Dep index | Module | Module is | Binding used here | Used for |
|---|---|---|---|---|
| 0 | 1 | `@babel/runtime/helpers/interopRequireDefault` | the wrapper function itself | `interopRequireDefault(require(1))` → wraps a module so its default export is read as `.default` |
| 1 | 32 | `@babel/runtime/helpers/slicedToArray` | `interopRequireDefault(...).default` | `slicedToArray(tuple, 2)` — the `const [a, b] = useState(...)` array destructuring (appears 3×) |
| 2 | 69 | **react** | local `interopRequireWildcard(react)` | `React.useState` |
| 3 | 2 | **react-native** | direct export object | `Pressable`, `Image`, `Text`, `View`, `ScrollView`, `FlatList` |
| 4 | 238 | react/jsx-runtime (`m239` exports `jsx`, `jsxs`, `Fragment`) | direct export object | every JSX element |
| 5 | 570 | layout theme | direct export object | `SPACING`, `BORDER_RADIUS`, `FONT_SIZE` (19 accesses) |
| 6 | 571 | `ThemeProvider` / `useTheme` | named export | `useTheme()` |
| 7 | 715 | `categories.ts` | named export | `CATEGORIES` |
| 8 | 577 | status-bar hook | named export | `useStatusBarColor` |
| 9 | 700 | react-native-safe-area-context | named export | `SafeAreaView` |
| 10 | 720 | image asset | asset id (number) | `search` (header button + empty state) |
| 11 | 721 | image asset | asset id (number) | `arrow-right` (row chevron) |

Note on require plumbing: in these factories the parameter `a1` **is** Metro's `require` and
`a6` is the dependency-map array, so `r21[rN]` = "dependency at index N" and `r22(r21[rN])` =
`require(moduleId)`. ESM/NS modules are read directly (`require(M).named`), CJS-only modules go
through `interopRequireDefault` first (`interopRequireDefault(require(M)).default`), and asset
modules export the registered asset id directly.

**Hooks called (in this exact order):**

1. `const colors = useTheme().colors` — `colors` only (no `isDark`, no `toggleTheme`).
2. `const [selectedCategory, setSelectedCategory] = useState('speedo')`
3. `const [categoryData, setCategoryData] = useState(CATEGORIES[0].data)`
4. `const [category, setCategory] = useState(CATEGORIES[0])`
5. `useStatusBarColor(category ? category.color : colors.primary)` — single argument only
   (so the defaults of `useStatusBarColor` apply: `barStyle = 'light-content'`,
   `animated = true`).

No `useEffect`, no `useCallback`, no `useMemo`, no `useFocusEffect` in this module. The screen
is fully synchronous — all data is bundled at build time.

`useStatusBarColor` (m577) is itself:

```
useStatusBarColor(color, barStyle = 'light-content', animated = true):
    useFocusEffect(useCallback(() => {
        StatusBar.setBarStyle(barStyle, animated);
        StatusBar.setBackgroundColor(color, animated);
    }, [color, barStyle, animated]))
```

i.e. the bar is re-coloured only while the Schedule screen is focused.

### 1.2 `CategoryTab` (m714, local, **not exported**)

**Props (destructured in this order):** `category`, `isActive`, `onPress`.
`category` is an element of `CATEGORIES` → `{ data, key, label, icon, color }`.

**Behaviour:** one pressable chip. Active chip = white background with the category colour used
for the icon tint and the label colour, plus `elevation: 5`. Inactive chip =
`rgba(255,255,255,0.15)` background with white (`#FFF`) icon tint and white (`#fff`) label.
The whole row is `flex: 1` per chip, so four chips share the row equally.

Behaviour is stateless; `onPress` comes from the parent's map callback.

### 1.3 `renderBusIcon` (m715) — used by the route rows

`renderBusIcon(key)` → the RN image asset for a category key, used directly as an
`<Image source>` value (module `require()` result, i.e. the registered asset id):

| Input string | Returned asset (module) | Asset `name` field | File |
|---|---|---|---|
| `'speedo'` | 709 | `speedo` | `src/assets/icons/speedo.jpg` (96×96, jpg, hash `f22457af…`) |
| `'metro'` | 711 | `metro` | `src/assets/icons/metro.jpg` (96×96) |
| `'orangeLine'` | 713 | `orange-line` | `src/assets/icons/orangeline.jpg` (96×96) |
| `'electric'` | 712 | `electric` | `src/assets/icons/electric.jpg` (96×96) |
| `'all'` | 716 | `filter` | `src/assets/icons/filter.jpg` (64×64) |
| anything else (fallback) | 717 | `bus2` | `src/assets/icons/bus2.jpg` (96×96, same hash as `speedo`) |

All these assets are registered with `httpServerLocation: '/assets/src/assets/icons'`,
`scales: [1]`, `type: 'jpg'`, `__packager_asset: true`.

### 1.4 `CATEGORIES` (m715) — the chip strip data

```js
CATEGORIES = [
  { data: ROUTES.filter(r => r.category === 'speedo'),     key: 'speedo',     label: 'Speedo',      icon: require(709), color: '#e12221' },
  { data: ROUTES.filter(r => r.category === 'metro'),      key: 'metro',      label: 'Metro',       icon: require(711), color: '#358437' },
  { data: ROUTES.filter(r => r.category === 'orangeLine'), key: 'orangeLine', label: 'Orange Line', icon: require(713), color: '#e29109' },
  { data: ROUTES.filter(r => r.category === 'electric'),   key: 'electric',   label: 'Electric',    icon: require(712), color: '#358437' },
]
```

The Schedule tab maps **`CATEGORIES`** (4 chips, no "All"). `CATEGORIES_FOR_SEARCH` (which
prepends `{key:'all', label:'All', icon: require(716 /*filter*/), color: COLORS.primary}`) is
**not** used by this screen. `getCategoryColor(key)` (falls back to `COLORS.primary =
'#fc3b38'`) is **not** used by this screen either.

### 1.5 `ROUTES` (m718) — the list data shape

`ROUTES = gtfsData.lines.map(line => { … })` where each entry is:

```js
{
  id:              line.id,
  name:            line.shortName,
  stationAddress:  line.longName,
  frequency:       line.frequency,
  operatingHours:  line.scheduleDisplay,
  category:        categoryOf(line.shortName || ''),
  fare:            line.ticketCost == null ? '25' : String(line.ticketCost),
  color:           line.color,
  stops:           line.patterns[0].stops.map(s => s.name),
  stopIds:         line.patterns[0].stops.map(s => s.id),
  coords:          line.patterns[0].stops.map(s => ({latitude: s.lat, longitude: s.lng, name: s.name, id: s.id})),
}

categoryOf(shortName):
    if shortName.startsWith('Speedo') → 'speedo'
    else if shortName.startsWith('Metro') → 'metro'
    else if shortName.startsWith('Orange') → 'orangeLine'
    else → 'electric'          // fallback (every non-Speedo/Metro/Orange route)
```

The Schedule screen reads only `id`, `name`, `frequency`, `stationAddress` from each item.

---

## 2. Theme constants referenced (exact values)

From module 570 (layout) and 576 (colours) — **verbatim**:

```
SPACING      = { xs: 4, sm: 8, md: 16, lg: 24, xl: 32, xxl: 48 }
FONT_SIZE    = { xs: 10, sm: 12, md: 14, base: 16, lg: 18, xl: 22, xxl: 28, xxxl: 36 }
BORDER_RADIUS= { sm: 6, md: 10, lg: 16, xl: 24, full: 999 }

COLORS      = { primary: '#fc3b38', background: '#F5F7FA', card: '#FFFFFF', border: '#E0E0E0',
                text: '#212121', textSecondary: '#757575', white: '#FFFFFF', black: '#000000',
                overlay: 'rgba(0,0,0,0.5)' }
DARK_COLORS = { primary: '#fc3b38', background: '#121212', card: '#2C2C2C', border: '#333333',
                text: '#EEEEEE', textSecondary: '#AAAAAA', white: '#FFFFFF', black: '#000000',
                overlay: 'rgba(0,0,0,0.7)' }
```

Runtime colours used by the screen: `colors.background`, `colors.primary`, `colors.text`,
`colors.textSecondary`, `colors.card`. No custom font family — Roboto (Android default).
Weights used here: `600`, `700`, `800`.

---

## 3. Exact UI structure

Read as a tree; every style object lists its properties **in source order**. `→` marks the
resolved value.

```
SafeAreaView
├─ props (order): style, edges, children
├─ style        = { flex: 1, backgroundColor: colors.background }            // '#F5F7FA' | '#121212'
├─ edges        = ['top']
└─ ScrollView
   ├─ props (order): showsVerticalScrollIndicator, children
   ├─ showsVerticalScrollIndicator = false        // NO other ScrollView prop (no style, no contentContainerStyle)
   ├─ [0] View                                    // ── HEADER (coloured) ──
   │  ├─ props (order): style, children
   │  ├─ style = { backgroundColor: category ? category.color : colors.primary,   // e.g. '#e12221'
   │  │            paddingBottom: SPACING.md,      // 16
   │  │            elevation: 5 }                  // Android shadow
   │  ├─ [0] View                                  // ── HEADER ROW ──
   │  │  ├─ style = { flexDirection: 'row',
   │  │  │            justifyContent: 'space-between',
   │  │  │            alignItems: 'center',
   │  │  │            paddingHorizontal: SPACING.md,   // 16
   │  │  │            paddingTop: SPACING.md }         // 16
   │  │  ├─ [0] View                              // ── TITLE BLOCK (NO style prop) ──
   │  │  │  ├─ [0] Text 'Lahore'
   │  │  │  │     style = { fontSize: FONT_SIZE.xxl,   // 28
   │  │  │  │               fontWeight: '800',
   │  │  │  │               color: '#fff' }
   │  │  │  └─ [1] Text 'Bus Schedule'
   │  │  │        style = { fontSize: FONT_SIZE.lg,     // 18
   │  │  │                  fontWeight: '600',
   │  │  │                  color: 'rgba(255,255,255,0.9)' }
   │  │  └─ [1] Pressable                          // ── SEARCH SHORTCUT ──
   │  │     ├─ props (order): android_ripple, onPress, style, children
   │  │     ├─ android_ripple = { color: colors.text + '40', foreground: true }   // e.g. '#21212140'
   │  │     ├─ onPress        = () => navigation.navigate('Search')
   │  │     ├─ style = { backgroundColor: 'rgba(255,255,255,0.2)',
   │  │     │            borderRadius: BORDER_RADIUS.lg,    // 16
   │  │     │            padding: SPACING.sm,               // 8
   │  │     │            overflow: 'hidden' }
   │  │     └─ [0] Image (asset: search)
   │  │           source   = require(720)                     // src/assets/icons/search.jpg (48×48)
   │  │           style    = { height: 22, width: 22, resizeMode: 'contain', tintColor: '#FFF' }
   │  └─ [1] View                                  // ── CATEGORY CHIP ROW ──
   │     ├─ style = { flexDirection: 'row',
   │     │            marginTop: SPACING.lg,              // 24
   │     │            paddingHorizontal: SPACING.md,      // 16
   │     │            gap: 0 }                           // literal 0
   │     └─ children = CATEGORIES.map(cat => (
   │           <CategoryTab key={cat.key}
   │                         category={cat}
   │                         isActive={selectedCategory === cat.key}
   │                         onPress={() => {
   │                            setSelectedCategory(cat.key);
   │                            setCategoryData(cat.data);
   │                            setCategory(cat);
   │                         }} />
   │        ))                                        // 4 chips: Speedo, Metro, Orange Line, Electric
   │
   │   CategoryTab structure:
   │   Pressable
   │   ├─ android_ripple = { color: '#FFFFFF40', foreground: true }     // 25% white, constant
   │   ├─ onPress
   │   ├─ style = { flex: 1,
   │   │            alignItems: 'center',
   │   │            paddingVertical: SPACING.sm,          // 8
   │   │            borderRadius: BORDER_RADIUS.lg,       // 16
   │   │            backgroundColor: isActive ? '#fff' : 'rgba(255,255,255,0.15)',
   │   │            marginHorizontal: 3,                  // literal 3
   │   │            elevation: isActive ? 5 : 0,
   │   │            overflow: 'hidden' }
   │   ├─ [0] Image (asset: cat.icon)
   │   │     style = { height: 35, width: 35, tintColor: isActive ? cat.color : '#FFF' }
   │   │             // NOTE: no resizeMode on this Image
   │   └─ [1] Text (cat.label)
   │         style = { fontSize: FONT_SIZE.md,      // 14
   │                   fontWeight: '600',
   │                   color: isActive ? cat.color : '#fff',
   │                   marginTop: 3,                 // literal 3
   │                   textAlign: 'center' }
   │
   ├─ [1] View                                       // ── "N ROUTES" ROW ──
   │  ├─ style = { flexDirection: 'row',
   │  │            justifyContent: 'space-between',
   │  │            alignItems: 'center',
   │  │            marginTop: SPACING.md,        // 16
   │  │            marginHorizontal: SPACING.md }// 16
   │  └─ [0] View
   │     ├─ style = { flexDirection: 'row', alignItems: 'center', gap: 8 }   // literal 8
   │     └─ [0] Text (jsxs → two children: [count, ' Routes'])
   │           style = { fontSize: FONT_SIZE.base,   // 16
   │                     fontWeight: '700',
   │                     color: colors.text }        // '#212121' | '#EEEEEE'
   │
   └─ [2] FlatList
      ├─ props (order): scrollEnabled, data, keyExtractor, contentContainerStyle,
      │                 ListEmptyComponent, renderItem
      ├─ scrollEnabled       = false          // list is nested in the ScrollView; it never scrolls
      ├─ data                = categoryData    // array of ROUTES for the selected category
      ├─ keyExtractor        = (item, index) => item.id || String(index)
      ├─ contentContainerStyle = { paddingTop: SPACING.sm }        // 8
      ├─ ListEmptyComponent  = (see §11)
      └─ renderItem = ({ item }) => (
           Pressable
           ├─ props (order): android_ripple, onPress, style, children
           ├─ android_ripple = { color: colors.text + '40', foreground: true }
           ├─ onPress        = () => navigation.navigate('RouteDetail',
           │                     { routeId: item.id, color: category.color })
           ├─ style = { backgroundColor: colors.card,             // '#FFFFFF' | '#2C2C2C'
           │            borderRadius: BORDER_RADIUS.xl,           // 24
           │            marginHorizontal: SPACING.md,             // 16
           │            marginBottom: SPACING.sm,                 // 8
           │            flexDirection: 'row',
           │            alignItems: 'center',
           │            overflow: 'hidden',
           │            elevation: 1,
           │            paddingVertical: SPACING.md }              // 16
           ├─ [0] View                                    // ── ICON BADGE ──
           │  ├─ style = { width: 42, height: 42,
           │  │            borderRadius: BORDER_RADIUS.lg,            // 16
           │  │            backgroundColor: category.color + '20',    // e.g. '#e1222120' (12.5% alpha)
           │  │            borderWidth: 1,
           │  │            borderColor: category.color + '30',        // e.g. '#e1222130' (~19% alpha)
           │  │            alignItems: 'center',
           │  │            justifyContent: 'center',
           │  │            marginHorizontal: SPACING.md }             // 16
           │  └─ [0] Image (asset: renderBusIcon(selectedCategory))
           │        style = { height: 30, width: 30, resizeMode: 'contain',
           │                  tintColor: category.color }
           ├─ [1] View                                    // ── TEXT BLOCK ──
           │  ├─ style = { flex: 1, paddingRight: SPACING.md }        // 16
           │  ├─ [0] Text (item.name)
           │  │     props (order): style, numberOfLines, children
           │  │     numberOfLines = 1
           │  │     style = { fontSize: FONT_SIZE.md,     // 14
           │  │               fontWeight: '700',
           │  │               color: colors.text }
           │  ├─ [1] Text (item.frequency)
           │  │     style = { fontSize: FONT_SIZE.sm,     // 12
           │  │               color: colors.textSecondary,
           │  │               marginTop: 3 }
           │  └─ [2] Text (item.stationAddress)
           │        style = { fontSize: FONT_SIZE.md,     // 14
           │                  color: colors.textSecondary,
           │                  marginTop: 3 }
           └─ [2] Image (asset: arrow-right)
                 source = require(721)                     // src/assets/icons/arrowright.jpg (64×64)
                 style  = { height: 25, width: 25, resizeMode: 'contain',
                            tintColor: colors.text,
                            marginRight: SPACING.md,        // 16
                            alignSelf: 'center' }
```

### 3.1 Numeric summary (all values, dp-exact)

| Element | padding / margin | radius | size | elevation | colours |
|---|---|---|---|---|---|
| Screen root | — | — | flex: 1 | — | bg `colors.background` |
| Header block | paddingBottom 16 | — | — | 5 | bg `category.color` |
| Header row | paddingHorizontal 16, paddingTop 16 | — | — | — | — |
| "Lahore" | — | — | fontSize 28 | — | `#fff`, weight 800 |
| "Bus Schedule" | — | — | fontSize 18 | — | `rgba(255,255,255,0.9)`, weight 600 |
| Search button | padding 8 | 16 | 22×22 icon | — | bg `rgba(255,255,255,0.2)`, ripple `colors.text+'40'`, icon tint `#FFF` |
| Chip row | paddingHorizontal 16, marginTop 24 | — | — | — | `gap: 0` |
| Chip | paddingVertical 8, marginHorizontal 3 | 16 | icon 35×35, text 14 | active 5 / inactive 0 | bg active `#fff` / inactive `rgba(255,255,255,0.15)`; icon+label active `cat.color` / inactive `#FFF`/`#fff`; `marginTop: 3`, `textAlign: 'center'` |
| Count row | marginTop 16, marginHorizontal 16 | — | text 16 | — | `colors.text`, weight 700; inner `gap: 8` |
| Route card | marginHorizontal 16, marginBottom 8, paddingVertical 16 | 24 | — | 1 | bg `colors.card`, ripple `colors.text+'40'` |
| Icon badge | marginHorizontal 16 | 16 | 42×42 box, icon 30×30 | — | bg `cat.color+'20'`, border 1 `cat.color+'30'` |
| Route name | — | — | 14, `numberOfLines: 1` | — | `colors.text`, weight 700 |
| Frequency | `marginTop: 3` | — | 12 | — | `colors.textSecondary` |
| Address | `marginTop: 3` | — | 14 | — | `colors.textSecondary` |
| Chevron | `marginRight: 16` | — | 25×25 | — | tint `colors.text`, `alignSelf: 'center'` |
| List content | paddingTop 8 | — | — | — | — |
| Empty state | paddingVertical 32, marginHorizontal 16 | — | icon 18×18 | — | icon tint `colors.textSecondary`, text 16 `colors.textSecondary`, `marginTop: 8`, `textAlign: 'center'` |

---

## 4. Literal strings shown to the user (verbatim)

User-visible strings rendered by the Schedule screen:

| String | Where |
|---|---|
| `Lahore` | header title, fontSize 28 / weight 800 / `#fff` |
| `Bus Schedule` | header subtitle, fontSize 18 / weight 600 / `rgba(255,255,255,0.9)` |
| ` Routes` | appended to the route count (jsxs: `[count, ' Routes']`) → e.g. `23 Routes` |
| `No routes found in this category` | FlatList empty state, fontSize 16 / `colors.textSecondary` / marginTop 8 / `textAlign: 'center'` |

Category labels (from `CATEGORIES`, rendered inside chips):
`Speedo`, `Metro`, `Orange Line`, `Electric`.

Route names and addresses are data-driven (see §12 for the complete verbatim inventory of all
28 routes: `name` + `stationAddress` + `frequency`).

Internal strings (not user-visible in this screen): prop names (`android_ripple`, `onPress`,
`style`, `children`, `source`, `edges`, `showsVerticalScrollIndicator`, `scrollEnabled`,
`data`, `keyExtractor`, `contentContainerStyle`, `ListEmptyComponent`, `renderItem`,
`numberOfLines`), style keys, and navigation route names `'Search'`, `'RouteDetail'`.

---

## 5. Icons

**The Schedule screen itself renders no vector icons.** m714 does not depend on the icon library
(module 558 / react-native-vector-icons is absent from its dep list) — every icon-looking element
on this screen is a **JPG image asset** (§6).

For completeness, the tab-bar entry that hosts the screen (m557 `BottomTabs`) uses:

| Place | Icon set | name | focused | size |
|---|---|---|---|---|
| "Schedule" tab bar icon | **react-native-vector-icons `MaterialCommunityIcons`** | `bus-side` → `bus` | yes | 24 |

(Other tabs use `home`/`home-outline`, `map-marker`/`map-marker-outline`, `cog`/`cog-outline`.)

No MaterialIcons and no Ionicons are used anywhere in this screen or its tab entry.

---

## 6. Image assets referenced

| Asset (app name) | File in APK | Module | Size (registered) | Used by | Render size / tint |
|---|---|---|---|---|---|
| `search` | `src/assets/icons/search.jpg` | 720 | 48×48, jpg, hash `5e7be62a…` | header search button | 22×22, `resizeMode: 'contain'`, tint `#FFF` |
| `search` | ″ | 720 | ″ | FlatList `ListEmptyComponent` | 18×18 (`FONT_SIZE.lg`), `resizeMode: 'contain'`, tint `colors.textSecondary` |
| `speedo` | `src/assets/icons/speedo.jpg` | 709 | 96×96, jpg, hash `f22457af…` | `renderBusIcon('speedo')` → route-row badge | 30×30, `resizeMode: 'contain'`, tint `category.color` |
| `metro` | `src/assets/icons/metro.jpg` | 711 | 96×96, jpg | `renderBusIcon('metro')` | 30×30, contain, `cat.color` |
| `orange-line` | `src/assets/icons/orangeline.jpg` | 713 | 96×96, jpg | `renderBusIcon('orangeLine')` | 30×30, contain, `cat.color` |
| `electric` | `src/assets/icons/electric.jpg` | 712 | 96×96, jpg | `renderBusIcon('electric')` | 30×30, contain, `cat.color` |
| `filter` | `src/assets/icons/filter.jpg` | 716 | 64×64, jpg | `renderBusIcon('all')` — **not reachable from this screen** (CATEGORIES has no `all` entry) | — |
| `bus2` | `src/assets/icons/bus2.jpg` | 717 | 96×96, jpg (identical bytes to `speedo`) | `renderBusIcon(<anything else>)` — fallback, **not reachable from this screen** | — |
| `arrow-right` | `src/assets/icons/arrowright.jpg` | 721 | 64×64, jpg, hash `443b47a1…` | route-row chevron | 25×25, contain, tint `colors.text` |

All images are `<Image>` elements with `resizeMode: 'contain'` (except the chip icon, which has
no `resizeMode` and is square 35×35). The chip icon uses the category's own `icon` field
(`renderBusIcon` result) — same asset set as above, tinted `cat.color` when active.

**Assets of the app that this screen does NOT reference at all:** `filter` and `bus2` (only
reachable through `renderBusIcon('all')` / the `bus2` fallback, neither of which this screen can
trigger), and `alert`, `arrowright` (used — see table), `back`, `bus`, `clock`,
`clockfilled`, `location`, `locationdirection`, `locationmap`, `loop`, `route`, `share`,
`stop` (used by RouteDetail / StopDetail / Map screens instead).

---

## 7. The COMPLETE departure-time algorithm (module 735)

`m735` exports exactly four bindings: `parseOperatingHours`, `parseFrequencyMinutes`,
`formatClock`, `getNextDepartures`. Two further functions exist but are **not exported**:
`timeToMinutes` and `formatDeparture` (their bodies were not recovered by the decompiler — see
§7.6/§7.7).

### 7.1 `parseOperatingHours(hours: string) → { start, end }`

```
FUNCTION parseOperatingHours(hours):
    raw  ← String(hours OR '6:00 AM - 10:00 PM')
           # i.e. if hours is falsy (null/undefined/'' /0) the default literal is used
    parts← raw.split(/-|to/i)                  # split on '-' OR the word 'to', case-insensitive
    parts← parts.map(s => s.trim())            # trim whitespace on every part
    [startRaw, endRaw] ← parts                 # slicedToArray(parts, 2): endRaw = undefined if absent

    startMatch ← String(startRaw).trim().match(/(\d{1,2}):(\d{2})\s*(AM|PM)/i)
    start ← null
    IF startMatch != null:
        h   ← parseInt(startMatch[1], 10)      # 1–2 digit hour
        m   ← parseInt(startMatch[2], 10)      # exactly 2-digit minutes
        mer ← startMatch[3]                    # 'AM' | 'PM' (any case, optional leading spaces)
        hh  ← h
        IF /pm/i.test(mer) AND h != 12:  hh ← h + 12
        IF /am/i.test(mer) AND h == 12:  hh ← 0
        start ← hh * 60 + m
    END
    IF start == null: start ← 0                # unparseable start ⇒ midnight

    endMatch ← String(endRaw).trim().match(/(\d{1,2}):(\d{2})\s*(AM|PM)/i)
    end ← null
    IF endMatch != null:
        h   ← parseInt(endMatch[1], 10)
        m   ← parseInt(endMatch[2], 10)
        mer ← endMatch[3]
        hh  ← h
        IF /pm/i.test(mer) AND h != 12:  hh ← h + 12
        IF /am/i.test(mer) AND h == 12:  hh ← 0
        end ← hh * 60 + m
    END
    IF end == null: end ← 1439                 # unparseable end ⇒ 23:59

    RETURN { start: start, end: end }          # minutes since midnight
```

**Worked examples (real `operatingHours` values from the bundled GTFS):**

| Input | start | end |
|---|---|---|
| `'06:00 AM - 10:00 PM'` | 360 | 1320 |
| `'6:00 AM - 10:00 PM'` | 360 | 1320 |
| `'7:00 AM - 9:15 PM'` | 420 | 1305 |
| `''` / `null` / `undefined` → default `'6:00 AM - 10:00 PM'` | 360 | 1320 |
| `'06:00 to 22:00'` (word "to", 24-h) | `null→0` (regex needs AM/PM) | `null→1439` |
| `'Closed'` | 0 | 1439 |
| `'12:00 AM - 12:00 PM'` | 0 | 720 |

Note the split regex `/-|to/i` matches a bare hyphen **or** the letters `to` anywhere
(e.g. `"6:00 AM to 10:00 PM"` works; `"6:00 AM–10:00 PM"` does not).

### 7.2 `parseFrequencyMinutes(frequency: string) → number`

```
FUNCTION parseFrequencyMinutes(frequency):
    raw      ← String(frequency OR '15')                    # falsy ⇒ '15'
    matches  ← raw.match(/\d+/g)                            # ALL digit runs, or null
    numbers  ← matches == null ? undefined : matches.map(Number)
    IF numbers is falsy: numbers ← [15]                     # only when match returned null
    n0 ← numbers[0]
    n1 ← numbers[1]
    IF n1 == null: n1 ← n0                                  # single number ⇒ use it twice
    RETURN Math.round((n0 + n1) / 2)                        # average of the two
```

| Input | Result |
|---|---|
| `'Every 9 minutes'` | 9 |
| `'Every 5-15 minutes'` | round((5+15)/2) = **10** |
| `'Every 10-30 minutes'` | 20 |
| `'Every 8-15 minutes'` | round(23/2) = **12** |
| `'Every 20 minutes'` | 20 |
| `'abc'` / `''` / null → `'15'` → no digits | **15** |
| `'1 2 3 4'` | round((1+2)/2) = 2 (only first two numbers used) |
| `'Every   minutes'` (digits absent) | 15 |

### 7.3 `formatClock(minutes: number) → string`

```
FUNCTION formatClock(minutes):
    hours ← Math.floor(minutes / 60) % 24
    mins  ← minutes % 60                                   # NOTE: no normalisation for negatives
    meridiem ← (12 <= hours) ? 'PM' : 'AM'
    hours ← hours % 12
    IF hours == 0: hours ← 12                              # midnight/noon shown as 12
    RETURN '' + hours + ':' + String(mins).padStart(2, '0') + ' ' + meridiem
```

| minutes | Output |
|---|---|
| 360 | `6:00 AM` |
| 1320 | `10:00 PM` |
| 0 | `12:00 AM` |
| 720 | `12:00 PM` |
| 765 | `12:45 PM` |
| 1385 | `11:05 PM` |
| 1500 (> 24h, wraps) | `1:00 AM` |

Format = **`h:mm AM` / `h:mm PM`** (no leading zero on the hour, two-digit minutes, single
space, uppercase meridiem).

### 7.4 `getNextDepartures(frequency, operatingHours, count = 5, now = new Date())`

Arguments 3 and 4 are defaulted by `arguments.length` checks (`=== undefined`), so they may be
omitted but not passed as `undefined` explicitly… in practice: omitted → default.

```
FUNCTION getNextDepartures(frequency, operatingHours, count = 5, now = new Date()):
    # 1. headway — inlined copy of parseFrequencyMinutes (NOT a call to it)
    matches  ← String(frequency OR '15').match(/\d+/g)
    numbers  ← matches == null ? undefined : matches.map(Number)
    IF numbers is falsy: numbers ← [15]
    n0 ← numbers[0]; n1 ← numbers[1] == null ? numbers[0] : numbers[1]
    interval ← Math.round((n0 + n1) / 2)

    # 2. service window
    {start, end} ← parseOperatingHours(operatingHours)

    # 3. "now" in minutes since midnight
    nowMinutes ← now.getHours() * 60 + now.getMinutes()

    # 4. after the last bus ⇒ nothing at all
    IF nowMinutes > end: RETURN []

    # 5. first candidate departure
    next ← start
    IF NOT (nowMinutes < start):                     # i.e. nowMinutes >= start
        next ← start + Math.ceil((nowMinutes - start) / interval) * interval
    END

    # 6. walk forward
    results ← []
    WHILE next <= end AND results.length < count:
        minutesAway ← Math.max(0, next - nowMinutes)
        IF minutesAway <= 0:      display ← 'Due'
        ELSE IF minutesAway < 60: display ← formatClock(next)      # e.g. '10:05 PM'
        ELSE:                     display ← '' + minutesAway + ' min'   # e.g. '75 min'
        results.push({ display: display, minutesAway: minutesAway })
        next ← next + interval
    END
    RETURN results
```

**Result shape:** `Array<{ display: string, minutesAway: number }>` — `display` is one of
`'Due'`, `'h:mm AM/PM'` (when < 60 min away) or `'N min'`.

**Edge cases:**

| Situation | Result |
|---|---|
| `nowMinutes > end` (after 22:00 for `06:00–22:00`) | `[]` |
| `nowMinutes < start` (before 06:00) | first entry `minutesAway = start - nowMinutes`, `display = formatClock(start)` (e.g. `'6:00 AM'`) unless it is < 60 min away |
| `nowMinutes == start` | `Math.ceil(0/interval) = 0` → `next = start` → `minutesAway = 0` → `display = 'Due'` |
| mid-interval (e.g. 13:07 with start 06:00, interval 9) | next = 06:00 + ceil(427/9)·9 = 06:00 + 432 = 13:12 → `5 min` |
| computed `next > end` on the first iteration | `[]` (service window exhausted) |
| `count` reached before `end` | stops early — array length == `count` (default 5) |
| `interval = 0` (frequency string with a lone `0`) | produces `minutesAway` steps of 0 → repeated `'Due'` entries up to `count` (loop terminates because `results.length < count`) |

### 7.5 Consumer contract — `useNextDepartures` (m1025)

This is how the array above reaches the UI (RouteDetail / StopDetail):

```
useNextDepartures(frequency, operatingHours, count = 5):
    const [list, setList] = useState(() => getNextDepartures(frequency, operatingHours, count))
    useEffect(() => {
        setList(getNextDepartures(frequency, operatingHours, count))
        const id = setInterval(() =>
            setList(getNextDepartures(frequency, operatingHours, count)), 30000)
        return () => clearInterval(id)
    }, [frequency, operatingHours, count])
    return list
```

When the returned array is empty the caller renders the literal text
**`No more buses today`** (verbatim, module 1020 line 1119 and module 1072 line 325) — this
string does **not** exist in module 735.

### 7.6 `timeToMinutes(time)` — exported? NO (internal, body not recovered)

Declared as `function(a0) { }` with an empty body in the decompilation (module 735 line 23),
stored in `_closure0_slot1`. It is loaded as a callee inside `parseOperatingHours` but the
call is not performed — the 12-hour → minutes conversion is inlined there instead (§7.1).
*[inferred semantics]*: converts a `'h:mm AM'/'h:mm PM'` string to minutes since midnight with
exactly the logic of §7.1 (`/pm/` → +12 unless 12, `/am/` → 12 becomes 0).

### 7.7 `formatDeparture(minutes, minutesAway)` — exported? NO (internal, body not recovered)

Declared as `function(a0, a1) { }` with an empty body (module 735 line 270), stored in
`_closure0_slot5`. It is loaded (with `minutes` as an argument) inside `getNextDepartures` but
the display computation is inlined at the call site (§7.4). *[inferred semantics]*: returns
`'Due'` when `minutesAway <= 0`, `formatClock(minutes)` when `minutesAway < 60`, else
`minutesAway + ' min'`.

---

## 8. State, effects, filters, sorting

### 8.1 State

| # | Declaration | Initial value | Purpose |
|---|---|---|---|
| 1 | `const [selectedCategory, setSelectedCategory] = useState('speedo')` | `'speedo'` (string key) | drives `isActive` on chips and which icon `renderBusIcon` returns |
| 2 | `const [categoryData, setCategoryData] = useState(CATEGORIES[0].data)` | all 23 Speedo routes | `FlatList.data` and the route count |
| 3 | `const [category, setCategory] = useState(CATEGORIES[0])` | the Speedo category object | header background colour, status-bar colour, badge colours, chevron/route tint, `RouteDetail` `color` param |

`CATEGORIES[0]` is the **Speedo** category, so **the Schedule tab always opens on Speedo**
(23 routes, header `#e12221`, status bar `#e12221`).

### 8.2 Effects

None in the screen itself. The only side effect is `useStatusBarColor(...)` which internally
registers a `useFocusEffect` (react-navigation) that sets
`StatusBar.setBarStyle('light-content', true)` and
`StatusBar.setBackgroundColor(color, true)` on focus.

### 8.3 Filtering

Filtering is **not** done at render time. It is precomputed once at module load in m715
(`ROUTES.filter(r => r.category === key)`) and swapped wholesale when a chip is pressed
(`setCategoryData(cat.data)`). There is no search box, no sort control, no fare filter and no
alphabetical/numeric sorting on this screen — list order is the GTFS `lines` array order
(verbatim order in §12).

### 8.4 Derived values

* Route count: `categoryData.length` (rendered as `{count} Routes`).
* Header colour: `category ? category.color : colors.primary` (the `colors.primary` branch is
  dead code in practice, since `category` is never null).
* Status bar colour: same expression, passed to `useStatusBarColor`.
* Badge background / border: `category.color + '20'` / `category.color + '30'`
  (8-digit hex with alpha 0x20/0x30).
* Route key: `item.id || String(index)`.

---

## 9. Navigation calls (exact names & params)

| Trigger | Call |
|---|---|
| Header search shortcut `Pressable.onPress` | `navigation.navigate('Search')` — **no params** |
| Route card `Pressable.onPress` | `navigation.navigate('RouteDetail', { routeId: item.id, color: category.color })` — params in this key order: `routeId` (the route's `id`, e.g. `'pma-lahore-239'`), `color` (the **category** colour, not the route colour, e.g. `'#e12221'`) |

Both are stack routes declared by `App.tsx` (module 495) as
`Search → SearchScreen (1071)` and `RouteDetail → RouteDetailScreen (1020)`, reached from
inside the `MainTabs` bottom-tab navigator.

**How the screen is entered:** it is *not* pushed by name from anywhere. `BottomTabs` (m557)
declares it as one of four `BottomTab.Screen`s:

```
<Screen name='Schedule' component={ScheduleScreen}   // m714 default export
        options={{ tabBarLabel: 'Schedule',
                   tabBarIcon: ({color, focused}) =>
                       <MaterialCommunityIcons name={focused ? 'bus' : 'bus-side'}
                                               color={color} size={24} /> }} />
```

Tab order in the navigator: `Home` (RouteFinderScreen, m569), `Nearby`, `Schedule`,
`Settings`. Navigator options: `{ headerShown: false, animation: 'shift' }`, custom `tabBar`
rendered as a react-native-paper `BottomNavigation.Bar` (`compact: true`, active colour
`colors.primary`, inactive `colors.textSecondary`, bar `colors.card` + `borderTopWidth: 1`).

For reference, `RouteFinderScreen` (m569 — the Home tab) navigates to `'Search'`,
`'StopPicker'` (params `{mode: 'from'|'to', onSelect}`) and `'JourneyResults'`
(params `{fromKey, toKey, fromName, toName}`); it never navigates to `'Schedule'` because the
Schedule tab is a sibling tab.

---

## 10. User interactions

| Interaction | Target | Effect |
|---|---|---|
| Tap a category chip (`Speedo` / `Metro` / `Orange Line` / `Electric`) | `CategoryTab` `Pressable` | Sets all three states in one handler: `setSelectedCategory(cat.key)`, `setCategoryData(cat.data)`, `setCategory(cat)`. Visible changes: chip becomes white with tinted icon/label and `elevation: 5`; header + status bar recolour to `cat.color`; route list + count replace; badge icon becomes `renderBusIcon(cat.key)` and badge tint/bg/border recolour to `cat.color`. |
| Tap the header search button | `Pressable` (22×22 `search` icon) | `navigation.navigate('Search')`; ripple `colors.text + '40'` |
| Tap a route card | `Pressable` (whole card) | `navigation.navigate('RouteDetail', {routeId: item.id, color: category.color})`; ripple `colors.text + '40'` |
| Scroll the screen | `ScrollView` | normal vertical scroll (`showsVerticalScrollIndicator: false`); the inner `FlatList` has `scrollEnabled: false` so it never scrolls independently and is never pulled-to-refresh |
| Android hardware back | — | leaves the tab / pops the stack (default) |

There are **no** long-press actions, no pull-to-refresh (`RefreshControl` absent), no text
inputs, no modals, no toasts on this screen.

---

## 11. Empty / loading / error states

| State | Behaviour |
|---|---|
| **Empty** (`categoryData.length === 0`) | `FlatList.ListEmptyComponent` renders a centred block: `<View style={{alignItems:'center', paddingVertical: SPACING.xl (32), marginHorizontal: SPACING.md (16)}}>` containing the **`search` asset** at 18×18 (`FONT_SIZE.lg`), `resizeMode: 'contain'`, tint `colors.textSecondary`, then `<Text style={{fontSize: FONT_SIZE.base (16), color: colors.textSecondary, marginTop: SPACING.sm (8), textAlign: 'center'}}>No routes found in this category</Text>`. With the shipped data no category is empty (Speedo 23, Metro 1, Orange Line 1, Electric 3), so this is only reachable with modified data. |
| **Loading** | **None.** No `ActivityIndicator`, no skeleton, no async fetch — the data is a static import. The first render already contains all 28 routes. |
| **Error** | **None.** No try/catch, no error boundary, no fallback UI. A malformed route object would simply render `undefined` in the text fields. |
| **Per-row overflow** | Route name uses `numberOfLines: 1` (single line, ellipsised). Frequency and address wrap freely (no `numberOfLines`). |

---

## 12. Route inventory rendered by this screen (verbatim, GTFS order)

Order is `ROUTES` order (GTFS `lines` array), filtered by category. `frequency` and
`stationAddress` are shown exactly as below.

### Speedo (`#e12221`) — **23 routes** (default tab)

| # | `name` | `stationAddress` | `frequency` |
|---|---|---|---|
| 1 | Speedo RT-03 | Rana Town to Railway Station | Every 9 minutes |
| 2 | Speedo RT-04 | R.A. Bazar to Chungi Amar Sidhu | Every 20 minutes |
| 3 | Speedo RT-05 | Bhatti Chowk to Shadbagh Underpass | Every 15 minutes |
| 4 | Speedo RT-07 | Depot Chowk to Chungi Amer Sidhu | Every 20 minutes |
| 5 | Speedo RT-08 | Canal to Jinnah Terminal | Every 20 minutes |
| 6 | Speedo RT-09 | Railway Station to Gulshan Ravi OL Station | Every 7 minutes |
| 7 | Speedo RT-10 | Wahdat Road Station to Qartaba Chowk | Every 12 minutes |
| 8 | Speedo RT-11 | Main Market Gulberg to Babu Sabu | Every 20 minutes |
| 9 | Speedo RT-12 | R.A Bazar to Nasir Bagh | Every 10 minutes |
| 10 | Speedo RT-13 | Depot Chowk to Kalma Chowk | Every 20 minutes |
| 11 | Speedo RT-14 | Purana Kahna to R.A Bazar | Every 8 minutes |
| 12 | Speedo RT-15 | Bhatti to R.A Bazar | Every 7 minutes |
| 13 | Speedo RT-16 | Canal to Jinnah Terminal | Every 20 minutes |
| 14 | Speedo RT-17 | Gajjumata to Rangers Wing Headquarter | Every 25 minutes |
| 15 | Speedo RT-18 | Bhatti Chowk to Mandiali Toll Plaza | Every 20 minutes |
| 16 | Speedo RT-19 | Paragon City to Railway Station | Every 20 minutes |
| 17 | Speedo RT-20 | Mull Adda to Jinnah Bus Terminal | Every 20 minutes |
| 18 | Speedo RT-21 | Shalamar station to Khaira Pull | Every 15 minutes |
| 19 | Speedo RT-23 | Canal to Chung | Every 8 minutes |
| 20 | Speedo RT-24 | KSK to Railway Station | Every 10-30 minutes |
| 21 | Speedo RT-25 | Askari X to Airport | Every 15 minutes |
| 22 | Speedo RT-27 | Jinnah Bus Terminal to Bahria Town | Every 10-20 minutes |
| 23 | Speedo RT-28 | Samanabad to Gulshan Ravi Double Sarka | Every 25 minutes |

### Metro (`#358437`) — **1 route**

| # | `name` | `stationAddress` | `frequency` |
|---|---|---|---|
| 1 | Metro Bus | Shahdara to Gajumata | Every 5-15 minutes |

### Orange Line (`#e29109`) — **1 route**

| # | `name` | `stationAddress` | `frequency` |
|---|---|---|---|
| 1 | Orange Line | Ali Town to Dera Gujran | Every 5 minutes |

### Electric (`#358437`) — **3 routes**

| # | `name` | `stationAddress` | `frequency` |
|---|---|---|---|
| 1 | Electric RT20 | Jinnah Bus Terminal to Raiwind | Every 10-30 minutes |
| 2 | Electric RT26 | Jinnah Bus Terminal  To BRB | Every 15-20 minutes |
| 3 | EV03 | Depot Stop to Railway Station | Every 8-15 minutes |

Each route's `operatingHours` (used by the RouteDetail screen's departure engine) is either
`'06:00 AM - 10:00 PM'` or `'6:00 AM - 10:00 PM'`, except **Speedo RT-25** which is
`'7:00 AM - 9:15 PM'`. Fares: `'25'` for all routes except **Speedo RT-14** (`'50'`) and
**Metro Bus** (`'30'`).

---

## 13. Notes for a faithful reimplementation

* No Dart/Flutter code here — behavioural notes only.
* The screen is a **static** screen: no network, no persistence, no async. Reproduce by
  embedding the same 28 route objects and filtering by category at load time.
* The three states must be updated **together** (key, data, whole category object) from a
  single tap handler; keeping only one of them will desynchronise the icon tint, header colour
  and list.
* Header colour and status-bar colour both follow `category.color` (not `colors.primary`), and
  the alpha-suffixed badge colours (`+'20'`, `+'30'`) require 8-digit hex-with-alpha support.
* `gap: 0` on the chip row and `marginHorizontal: 3` on each chip combine to the visual chip
  separation; the `gap: 8` on the count row is a literal, not a token.
* Elevation values are Android-only shadows (`elevation: 5` header, `elevation: 1` cards) and
  should be ignored/emulated on iOS.
* The empty-state illustration reuses the **`search`** icon at a smaller size with the
  secondary-text tint.
* The `FlatList` must be non-scrollable and nested inside a single `ScrollView`; do not make it
  independently scrollable (`scrollEnabled: false`) and do not add a `RefreshControl`.
* The departure engine (§7) belongs to the **RouteDetail/StopDetail** screens, driven by
  `useNextDepartures` with a 30-second interval refresh; the Schedule tab only needs
  `frequency` + `operatingHours` to be present on the route object to hand them on.

---

## 14. How the numbers above were obtained (decompiler conventions)

Verification notes, so the implementer can re-check anything:

* `mNNN.js` bodies are hermes-dec register-machine dumps. Object literals print as
  `rN = {'a': 1, 'b': null}` where a `null` value is a slot filled by a later `rX[i] = …`
  assignment; the printed key order is the **source property order** (this is why the style
  objects above list keys in a meaningful order).
* `rX.bind(rY)(args)` = `rX.call(rY, args)`; `rN[rM]` with `rM` a small constant register = a
  Metro dependency-map lookup, i.e. `require(moduleId)` for the M-th entry of the module's
  `deps=[…]` list.
* Dependency indices for m714 were each verified against a known export: dep 6 → `useTheme`,
  dep 7 → `CATEGORIES`, dep 8 → `useStatusBarColor`, dep 9 → `SafeAreaView`, dep 10 → the
  `search` asset (registerAsset `name: 'search'`), dep 11 → `arrow-right`, dep 5 → the module
  exporting `SPACING`/`BORDER_RADIUS`/`FONT_SIZE`, dep 4 → the module exporting `jsx`/`jsxs`.
* Colour/size tokens resolve through modules 570 (`SPACING`, `FONT_SIZE`, `BORDER_RADIUS`) and
  576 (`COLORS`, `DARK_COLORS`), both printed verbatim in §2.
* `formatClock`'s return is produced by `HermesInternal.concat('', hours, ':', mins, ' ',
  meridiem)` in the bytecode — i.e. the string template `'' + h + ':' + mm + ' ' + AM/PM`.
* `getNextDepartures` derives its headway from an **inlined copy** of `parseFrequencyMinutes`
  (same formula, re-typed at the call site) — behaviourally identical.

