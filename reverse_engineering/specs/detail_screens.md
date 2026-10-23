# Lahore Speedo Bus Guide — Detail Screens Implementation Spec

Decompiled source of truth (Hermes register-machine decompilations of Metro modules):

| Module | Contents |
|---|---|
| `m1021.js` | `StopCard` |
| `m1020.js` | `RouteDetailScreen`, `DepartureChip` (local copy), `InfoBox` (local copy) |
| `m1072.js` | `StopDetailScreen`, `DepartureChip` (local copy), `LineDepartureCard` |
| `m1073.js` | `StopPickerScreen`, `requestLocationPermission`, `choose`, `useCurrentLocation`, inline `haversine` |
| `m1075.js` | `JourneyResultsScreen`, `TransferRow` |
| `m1076.js` | `JourneyDetailScreen`, `Chip`, `StatBox`, `OutlineButton`, `TransferStep`, `RailIcon`, `LegCard`, `TIPS`, `shareRoute` |

---

## 0. GLOBAL DESIGN TOKENS (exact values, module 570 / 576)

### 0.1 `SPACING` (module 570)

| key | dp |
|---|---|
| `xs` | **4** |
| `sm` | **8** |
| `md` | **16** |
| `lg` | **24** |
| `xl` | **32** |
| `xxl` | **48** |

### 0.2 `FONT_SIZE` (module 570)

| key | value |
|---|---|
| `xs` | **10** |
| `sm` | **12** |
| `md` | **14** |
| `base` | **16** |
| `lg` | **18** |
| `xl` | **22** |
| `xxl` | **28** |
| `xxxl` | **36** |

### 0.3 `BORDER_RADIUS` (module 570)

| key | value |
|---|---|
| `sm` | **6** |
| `md` | **10** |
| `lg` | **16** |
| `xl` | **24** |
| `full` | **999** |

### 0.4 Theme colors (modules 571 / 576) — `useTheme()` returns `{ colors, isDark, toggleTheme, preference, setThemePreference }`

Light (`COLORS`):

```
primary        #fc3b38
background     #F5F7FA
card           #FFFFFF
border         #E0E0E0
text           #212121
textSecondary  #757575
white          #FFFFFF
black          #000000
overlay        rgba(0,0,0,0.5)
```

Dark (`DARK_COLORS`):

```
primary        #fc3b38
background     #121212
card           #2C2C2C
border         #333333
text           #EEEEEE
textSecondary  #AAAAAA
white          #FFFFFF
black          #000000
overlay        rgba(0,0,0,0.7)
```

**Alpha-suffix colour convention used throughout:** the app concatenates a 2-digit hex alpha suffix onto a 6-digit hex colour, e.g. `colors.primary + '20'`, `colors.primary + '15'`, `colors.primary + '30'`, `colors.primary + '50'`, `colors.primary + '70'`, `colors.primary + '10'`, `colors.text + '15'`, `colors.text + '20'`, `colors.white + '50'`, `routeColor + '15'/'20'/'30'/'50'/'70'`. These are 8-digit `#RRGGBBAA` strings (alpha 0x15 ≈ 8 %, 0x20 ≈ 12 %, 0x30 ≈ 19 %, 0x40 ≈ 25 %, 0x50 ≈ 31 %, 0x70 ≈ 44 %).

### 0.5 Hard-coded (non-theme) colours used by these screens

| Value | Where |
|---|---|
| `#fff` / `#FFF` | ALL icon tint colours and all text over coloured header/hero backgrounds; `DepartureChip` text when `isNext` |
| `#FFFFFF50`, `#FFFFFF40` | ripples on coloured backgrounds (RouteDetail share button `#FFFFFF50`, LegCard header `#FFFFFF40`, StopDetail/RouteDetail "View on Map" `#FFFFFF50`/`#FFFFFF40` variants) |
| `#ffffff30` | StopDetail "View on Map" ripple |
| `rgba(255,255,255,0.8)` | RouteDetail subtitle text; StopPicker search icon tint |
| `rgba(255,255,255,0.7)` | RouteDetail "Searched for:" text; StopPicker placeholder text colour |
| `rgba(255,255,255,0.85)` | LegCard "Tap for full route details"; JourneyResults header destination text |
| `rgba(255,255,255,0.3)` | HighlightedText match highlight background (RouteDetail) |
| `rgba(255,255,255,0.2)` | JourneyResults / JourneyDetail header count pill background; StopPicker search field background |
| `#2E7D32` | "Direct"/origin marker green (JourneyResults badge, JourneyDetail FROM dot) |
| `#C62828` | JourneyDetail TO dot (red) |
| `transparent` | StopCard border colour when not highlighted; direction-row background when not selected |

### 0.6 Icon libraries (all `react-native-vector-icons`)

| Module ID | Icon set | Font file | Font family |
|---|---|---|---|
| 558 | **MaterialCommunityIcons** | `MaterialCommunityIcons.ttf` | `Material Design Icons` |
| 727 | **Feather** | `Feather.ttf` | `Feather` |
| 1077 | **Entypo** | `Entypo.ttf` | `Entypo` |

### 0.7 Image assets (`registerAsset`, all `httpServerLocation: '/assets/src/assets/icons'`, `type: 'jpg'`, `scales: [1]`)

| Asset name | Module | width×height | src hash |
|---|---|---|---|
| `back` | 1026 | 48×48 | `73682352698c3e674f7f2140324ed848` |
| `share` | 1027 | 64×64 | `1ad6075e2637e3e7dda4c63b571fd114` |
| `clock-filled` | 1028 | 48×48 | `d76fecd08b167d32c272958d5d768be5` |
| `loop` | 1029 | 48×48 | `f4cd43702030ab867fe88773c1aee60f` |
| `clock` | 1030 | 48×48 | `1b2477c593df2fd07cda66f4edfef1c9` |
| `stop` | 1031 | 48×48 | `0eec8183804591ae684752dfd0f603b8` |
| `location-map` | 1032 | 64×64 | `bb50efe832f06884a3fd1179366267c5` |
| `arrow-right` | 721 | 64×64 | `443b47a1f55630746b4d954d4ae182c7` |
| `route` | 1022 | 48×48 | `7ba3309e06ceeab6d95e1dae061f6c92` |
| `search` | 720 | 48×48 | `5e7be62a3e2d5d941aa7acdbe3f97920` |
| `location-direction` | 1070 | 64×64 | `8520d1a8b6c22bbb62e48ab7d1a09cc9` |
| `bus` | 1074 | 96×96 | `e0277a6c1d13e67240cef150a43d8c66` |
| `bus2` | 717 | 96×96 | `f22457af1441a47c1aacb0710706c2e1` |
| `speedo` | 709 | — | bus icon for category `speedo` |
| `metro` | 711 | — | bus icon for category `metro` |
| `electric` | 712 | — | bus icon for category `electric` |
| `orange-line` | 713 | — | bus icon for category `orangeLine` |
| `filter` | 716 | — | bus icon for category `all` |

`renderBusIcon(category)` (module 715):
`'speedo'` → `speedo`; `'metro'` → `metro`; `'orangeLine'` → `orange-line`; `'electric'` → `electric`; `'all'` → `filter`; **default (anything else / undefined)** → `bus2`.

Route category colours (module 715): `speedo #e12221`, `metro #358437`, `orangeLine #e29109`, `electric #358437`, `all` → `COLORS.primary`.

### 0.8 Shared hooks / data helpers used by these screens

* **`useTheme()`** (module 571) → `{ colors, isDark, … }`.
* **`useRoutes()`** (module 1024) → `{ routes, getRouteById, searchRoutes, getRoutesByCategory, loading, error, getMaps, getRoutesForStop, getStopCoordinate }`.
  * `getRouteById(routeId)` → route object or `undefined`/`null`.
  * `getRoutesForStop(stopIdOrName)` → `Array<{ route, index }>` — matches `route.stopIds.indexOf(stopId)` else `route.stops.findIndex(s => s.trim().toLowerCase() === stopId.trim().toLowerCase())`, filtered to those with index ≥ 0, in `routes` data order.
* **`useStatusBarColor(color, barStyle = 'light-content', translucent = true)`** (module 577) — applied inside `useFocusEffect`, so the status bar colour is (re)applied on every screen focus.
* **`useNextDepartures(frequency, operatingHours, count = 5)`** (module 1025) — returns an array of departure objects, each `{ display: string, … }`; refreshed by `getNextDepartures(...)` every **30000 ms**. `frequency`/`operatingHours` may be `undefined`.
* **Route object shape** (module 718): `{ id, name (shortName), stationAddress (longName), frequency, operatingHours (scheduleDisplay), category, fare, color, stops: string[], stopIds: string[], coords }`.
* **`ALL_STOPS`** (module 734) — flattened, de-duplicated list of every stop name across `ROUTES`, sorted by `name.localeCompare(name)`. Item: `{ key ( = name.trim().toLowerCase() ), name, latitude, longitude, routes: Array<{ routeId, index }> }`.
* **`searchStops(query)`** (module 734) — if `!query?.trim()` returns `ALL_STOPS`; else `ALL_STOPS.filter(s => s.key.includes(norm(query)))` where `norm = s.trim().toLowerCase()`.
* **`getStopByKey(key)`** (module 734) — `ALL_STOPS.find(s => s.key === key)`.
* **`formatMinutes(mins)`** (module 734) — `mins < 60` → `` `${mins} min` ``; `mins >= 60` → `h = floor(mins/60)`, `rem = mins%60`; `rem === 0` → `` `${h}h` `` else `` `${h}h ${rem}m` ``.
* **`formatWalkDistance(metres)`** (module 734) — `< 1000` → `` `${Math.round(m)} m` ``; `>= 1000` → `` `${(m/1000).toFixed(1)} km` ``.
* **`findJourneys(fromKey, toKey)`** (module 734) — returns `Array<journey>`; each journey has `legs`, `transfers`, `totalStops`, `totalFare`, `totalWalkMinutes`, `estimatedMinutes` (`Math.max(1, Math.round((arrivalTime - startTime)/60000))`), `startTime` (Date), `arrivalTime` (Date), `startClock` (string, `formatClock(h*60+min)`), `arrivalClock` (string).
  * Each **leg** has: `routeId`, `routeName`, `color`, `category`, `fare`, `frequency`, `fromName`, `toName`, `reversed`, `stopsTravelled`, `stopNames: string[]`, `waitMinutes`, `departureClock`, `arrivalClock`, and optionally `transferWalk: { toName, minutes }` (present on a leg when the *next* leg is reached by walking).

---

## 1. `StopCard` (module 1021)

### 1.1 Props

| Prop | Type | Default | Notes |
|---|---|---|---|
| `stop` | string | — | stop name (a plain string, not an object) |
| `index` | number | — | 1-based position shown in the badge |
| `estimatedTime` | string | — | free-form text under the name (RouteDetailScreen passes `route.frequency`) |
| `routeColor` | string | — | route hex colour; falls back to `colors.primary` when falsy |
| `onPress` | function | — | whole-card press |
| `onMapPress` | function | optional | when absent the map button is **not rendered** |
| `isHighlighted` | boolean | `false` | highlight styling |

### 1.2 Exact UI structure

```
Pressable  (react-native <Pressable>)
  android_ripple = { color: routeColor + '30', foreground: true }
  onPress       = onPress
  style = {
    backgroundColor : isHighlighted ? routeColor + '15' : colors.card,
    borderWidth     : isHighlighted ? 1.5 : 0,
    borderColor     : isHighlighted ? routeColor : 'transparent',
    borderRadius    : BORDER_RADIUS.lg  (16),
    marginHorizontal: SPACING.md        (16),
    marginVertical  : SPACING.xs        (4),
    padding         : SPACING.md        (16),
    flexDirection   : 'row',
    alignItems      : 'flex-start',
    elevation       : isHighlighted ? 0 : 1,
    shadowColor     : colors.black,
    overflow        : 'hidden',
  }
  children:
  ① View   (sequence badge)
     style = { width: 32, height: 32, borderRadius: BORDER_RADIUS.md (10),
               backgroundColor: (routeColor || colors.primary) + '30',
               borderWidth: 1, borderColor: (routeColor || colors.primary) + '70',
               alignItems: 'center', justifyContent: 'center',
               marginRight: SPACING.sm (8), marginTop: 2 }
     child: Text  style = { color: routeColor || colors.primary,
                            fontSize: FONT_SIZE.sm (12), fontWeight: '700' }
             children = index
  ② View   (text block)
     style = { flex: 1 }
     children:
       Text  numberOfLines = 2
             style = { fontSize: FONT_SIZE.base (16), fontWeight: '700', color: colors.text }
             children = stop
       Text  style = { fontSize: FONT_SIZE.sm (12), color: colors.textSecondary, marginTop: 2 }
             children = estimatedTime
  ③ Pressable  (map button — ONLY if onMapPress is provided)
     hitSlop       = { top: 30, bottom: 30, left: 30, right: 30 }
     android_ripple= { color: colors.text + '50', foreground: true }
     onPress      = onMapPress
     style = { backgroundColor: routeColor, borderRadius: BORDER_RADIUS.md (10),
               padding: 11  (SPACING.sm 8 + 3), marginLeft: SPACING.sm (8), overflow: 'hidden' }
     child: Image  source = <asset route> (module 1022)
                   style = { height: 18, width: 18, tintColor: '#fff' }
```

### 1.3 Strings
None (all values come from props).

---

## 2. `RouteDetailScreen` (module 1020)

### 2.1 `route.params` read

| Param | Type | Use |
|---|---|---|
| `routeId` | string | `getRouteById(routeId)` → the route object; also pushed into `Map` / `StopDetail` navigations |
| `color` | string (hex) | header background, "View on Map" background, icon tints, chip/ripple colours |
| `searchQuery` | string, defaults to `''` | passed to `HighlightedText` as `searchQuery`; drives the extra italic line and the header highlight |
| `focusStopId` | string | stop to auto-scroll to + highlight in the list |

### 2.2 State / hooks

* `colors = useTheme().colors`
* `route = useRoutes().getRouteById(routeId)`
* `useStatusBarColor(color)` — uses the *param* colour, not a theme colour.
* `scrollRef = useRef(null)` (FlatList ref)
* `const [hasScrolled, setHasScrolled] = useState(false)`
* `const [dirIndex, setDirIndex] = useState(0)`
* `const [directionOpen, setDirectionOpen] = useState(false)`
* `directions = useMemo(..., [route])`:
  * `[]` if `!route`
  * `{ key: 'forward', label: `${stops[0]} to ${stops[stops.length-1]}`, stops: [...route.stops], stopIds: [...route.stopIds], reversed: false }`
  * `{ key: 'reverse', label: `${reversedStops[0]} to ${reversedStops[len-1]}`, stops: [...route.stops].reverse(), stopIds: [...route.stopIds].reverse(), reversed: true }`
* `direction = directions[dirIndex] || directions[0]`
* `departures = useNextDepartures(route ? route.frequency : undefined, route ? route.operatingHours : undefined, 5)`
* `useEffect(..., [focusStopId, route, direction, hasScrolled])`: if `focusStopId && scrollRef.current && route && !hasScrolled`, computes `idx = direction ? direction.stops.indexOf(focusStopId) : -1`; if `idx >= 0` → `setTimeout(…, 500)` → `scrollRef.current.scrollToIndex({ index: idx, animated: true, viewPosition: 0.3 })` and `setHasScrolled(true)`.
* `onScrollToIndexFailed`: `scrollRef.current?.scrollToOffset({ offset: info.averageItemLength * info.index, animated: true })`.

### 2.3 Early return (route not found)

```
View style = { flex: 1, alignItems: 'center', justifyContent: 'center', backgroundColor: colors.background }
  Text style = { color: colors.text }  children = 'Route not found'
```

### 2.4 Main UI structure (exact, in order)

```
SafeAreaView (react-native-safe-area-context)
  style = { flex: 1, backgroundColor: colors.background }
  edges = ['top']
│
├─ View  (header band, background = params.color)
│  style = { backgroundColor: color,
│            paddingHorizontal: SPACING.md (16),
│            paddingTop: SPACING.sm (8),
│            paddingBottom: SPACING.md (16) }
│  │
│  ├─ View  style = { flexDirection: 'row', alignItems: 'center' }
│  │  │
│  │  ├─ View  (back-button clip wrapper)
│  │  │    style = { borderRadius: BORDER_RADIUS.md (10), overflow: 'hidden', marginRight: SPACING.xs (4) }
│  │  │    └─ Pressable
│  │  │         android_ripple = { color: colors.white + '50' }
│  │  │         onPress = () => navigation.goBack()
│  │  │         style = { height: 35, width: 35, justifyContent: 'center', alignItems: 'center' }
│  │  │         └─ Image  source = <asset back> (1026)
│  │  │                   style = { height: 18, width: 18, tintColor: '#fff' }
│  │  │
│  │  ├─ View  style = { flex: 1 }
│  │  │    ├─ HighlightedText
│  │  │    │    text           = route.stationAddress
│  │  │    │    searchQuery    = params.searchQuery
│  │  │    │    style          = { fontSize: FONT_SIZE.lg (18), fontWeight: '700', color: '#fff' }
│  │  │    │    highlightStyle = { fontSize: FONT_SIZE.lg (18), fontWeight: '700', color: '#fff',
│  │  │    │                        backgroundColor: 'rgba(255,255,255,0.3)',
│  │  │    │                        paddingHorizontal: 2, borderRadius: 2 }
│  │  │    ├─ Text  style = { fontSize: FONT_SIZE.sm (12), color: 'rgba(255,255,255,0.8)', marginTop: 1 }
│  │  │    │        children = route.name
│  │  │    └─ Text  (ONLY when params.searchQuery is non-empty)
│  │  │         style = { fontSize: FONT_SIZE.xs (10), color: 'rgba(255,255,255,0.7)',
│  │  │                   marginTop: 3, fontStyle: 'italic' }
│  │  │         children = [ 'Searched for: "', searchQuery, '"' ]
│  │  │
│  │  └─ View  (share-button clip wrapper)
│  │       style = { borderRadius: BORDER_RADIUS.md (10), overflow: 'hidden', marginLeft: 4 }
│  │       └─ Pressable
│  │            android_ripple = { color: colors.white + '50' }
│  │            onPress = handleShare   (async, see §2.8)
│  │            style = { padding: 6 }
│  │            └─ Image  source = <asset share> (1027)
│  │                      style = { height: 22, width: 22, tintColor: '#FFF' }
│
└─ FlatList
   ref                     = scrollRef
   data                    = direction ? direction.stops : []
   keyExtractor            = (item, index) => `${direction ? direction.key : undefined}-${item}-${index}`
   contentContainerStyle   = { paddingTop: SPACING.md (16), paddingBottom: SPACING.lg (24) }
   showsVerticalScrollIndicator = false
   onScrollToIndexFailed   = see §2.2
   ListHeaderComponent     = (below)
   renderItem              = (below)

   ┌─ ListHeaderComponent ────────────────────────────────────────────────
   │ View   style = { paddingHorizontal: SPACING.md (16) }
   │ │
   │ ├─ ① View  (NEXT DEPARTURES card)
   │ │    style = { backgroundColor: colors.card, borderRadius: BORDER_RADIUS.lg (16),
   │ │              padding: SPACING.md (16), marginBottom: SPACING.md (16), elevation: 1 }
   │ │    ├─ View  style = { flexDirection: 'row', alignItems: 'center', marginBottom: SPACING.sm (8) }
   │ │    │    ├─ Image  source = <asset clock-filled> (1028)
   │ │    │    │          style = { height: 16, width: 16, tintColor: color, marginRight: SPACING.xs (4) }
   │ │    │    └─ Text   style = { fontSize: FONT_SIZE.sm (12), fontWeight: '800',
   │ │    │                     color: colors.text, letterSpacing: 0.4 }
   │ │    │              children = 'NEXT DEPARTURES'
   │ │    └─ (departures.length !== 0)
   │ │         View  style = { flexDirection: 'row', flexWrap: 'wrap' }
   │ │           children = departures.map((d, i) =>
   │ │             <DepartureChip  key = `${d.display}${i}`
   │ │                display = d.display   isNext = (i === 0)
   │ │                color = params.color   colors = colors />)
   │ │       (else)
   │ │         Text  style = { color: colors.textSecondary }  children = 'No more buses today'
   │ │
   │ ├─ ② Pressable  (DIRECTION selector)
   │ │    android_ripple = { color: color + '20', foreground: true }
   │ │    onPress = () => setDirectionOpen(!directionOpen)
   │ │    style = { backgroundColor: colors.card, borderRadius: BORDER_RADIUS.lg (16),
   │ │              padding: SPACING.md (16),
   │ │              marginBottom: directionOpen ? SPACING.md (16) : SPACING.xs (4),
   │ │              flexDirection: 'row', alignItems: 'center',
   │ │              elevation: 1, overflow: 'hidden' }
   │ │    ├─ Image  source = <asset loop> (1029)
   │ │    │          style = { height: 22, width: 22, tintColor: color, marginRight: SPACING.sm (8) }
   │ │    ├─ View   style = { flex: 1 }
   │ │    │    ├─ Text  style = { fontSize: FONT_SIZE.xs (10), fontWeight: '700',
   │ │    │    │                   color: colors.textSecondary, letterSpacing: 0.4 }
   │ │    │    │          children = 'DIRECTION'
   │ │    │    └─ Text  style = { fontSize: FONT_SIZE.base (16), fontWeight: '800',
   │ │    │    │                   color: colors.text, marginTop: 2 }
   │ │    │               children = direction ? direction.label : undefined
   │ │    └─ MaterialCommunityIcons  name = directionOpen ? 'chevron-up' : 'chevron-down'
   │ │                               size = 24  color = colors.text
   │ │
   │ ├─ ③ View  (direction dropdown — ONLY when directionOpen === true)
   │ │    style = { backgroundColor: colors.card, borderRadius: BORDER_RADIUS.lg (16),
   │ │              marginBottom: SPACING.md (16), overflow: 'hidden', elevation: 1 }
   │ │    children = directions.map((d, i) =>
   │ │      <Pressable key = d.key
   │ │        android_ripple = { color: color + '20', foreground: true }
   │ │        onPress = () => { setDirectionIndex(i); setDirectionOpen(false); }
   │ │        style = { flexDirection: 'row', justifyContent: 'space-between',
   │ │                  alignItems: 'center', padding: SPACING.md (16),
   │ │                  borderTopWidth: 1, borderTopColor: colors.border,
   │ │                  backgroundColor: i === dirIndex ? color + '15' : 'transparent' }>
   │ │        ├─ Text  style = { color: i === dirIndex ? color : colors.text,
   │ │        │                   fontWeight: i === dirIndex ? '800' : '600',
   │ │        │                   flex: 1, marginRight: SPACING.sm (8) }
   │ │        │          children = d.label
   │ │        └─ Feather  name = 'check'  size = 22  color = color      (ONLY when i === dirIndex)
   │ │      </Pressable>)
   │ │
   │ ├─ ④ View  (InfoBox grid — HOURS / FREQUENCY / FARE / TOTAL STOPS)
   │ │    style = { backgroundColor: colors.card, borderRadius: BORDER_RADIUS.lg (16),
   │ │              padding: SPACING.md (16), marginBottom: SPACING.md (16),
   │ │              flexDirection: 'row', flexWrap: 'wrap', elevation: 1 }
   │ │    children = [
   │ │      <InfoBox icon = <asset clock> (1030)  label = 'HOURS'       value = route.operatingHours colors = colors />,
   │ │      <InfoBox icon = <asset loop>  (1029)  label = 'FREQUENCY'   value = route.frequency      colors = colors />,
   │ │      <InfoBox icon = <asset route> (1022)  label = 'FARE'        value = `Rs. ${route.fare ?? '25'}` colors = colors />,
   │ │      <InfoBox icon = <asset stop>  (1031)  label = 'TOTAL STOPS' value = String(route.stops.length) colors = colors />,
   │ │    ]
   │ │
   │ ├─ ⑤ Pressable  ("View on Map")
   │ │    android_ripple = { color: '#FFFFFF50', foreground: true }
   │ │    onPress = () => navigation.navigate('Map',
   │ │                { routeId, color, reversed: direction ? direction.reversed : undefined })
   │ │    style = { flexDirection: 'row', alignItems: 'center',
   │ │              backgroundColor: color,
   │ │              paddingHorizontal: SPACING.md (16), paddingVertical: SPACING.md (16),
   │ │              borderRadius: BORDER_RADIUS.lg (16),
   │ │              overflow: 'hidden', marginBottom: SPACING.md (16) }
   │ │    ├─ Image  source = <asset location-map> (1032)
   │ │    │          style = { height: 18, width: 18, tintColor: '#FFF' }
   │ │    ├─ Text   style = { color: '#fff', fontWeight: '800',
   │ │    │                   fontSize: FONT_SIZE.base (16),
   │ │    │                   marginLeft: SPACING.sm (8), flex: 1 }
   │ │    │          children = 'View on Map'
   │ │    └─ Image  source = <asset arrow-right> (721)
   │ │               style = { height: 16, width: 16, tintColor: '#FFF' }
   │ │
   │ ├─ ⑥ Text  style = { fontSize: FONT_SIZE.xl (22), fontWeight: '800', color: colors.text }
   │ │        children = 'Stops'
   │ │
   │ └─ ⑦ Text  style = { fontSize: FONT_SIZE.sm (12), color: colors.textSecondary,
   │          │              marginBottom: SPACING.sm (8) }
   │          │        children = 'Stops along this route'
   └──────────────────────────────────────────────────────────────────────

   renderItem = ({ item, index }) =>
     <StopCard
        stop           = item
        index          = index + 1
        estimatedTime  = route.frequency
        routeColor     = params.color
        isHighlighted  = focusStopId ? (item === focusStopId) : false
        onPress        = () => navigation.navigate('StopDetail',
                             { stopId: direction ? direction.stopIds[index] : undefined,
                               stopName: item })
        onMapPress     = () => navigation.navigate('Map',
                             { routeId,
                               focusStopId: direction ? direction.stopIds[index] : undefined,
                               color: params.color,
                               reversed: direction ? direction.reversed : undefined })
     />
```

### 2.5 `DepartureChip` (local copy in module 1020)

Props: `{ display: string, isNext: boolean, color: string, colors }`.

```
View style = {
  backgroundColor : isNext ? color : colors.background,
  borderWidth     : 1,
  borderColor     : isNext ? color : colors.border,
  paddingHorizontal: SPACING.md (16),
  paddingVertical  : SPACING.sm (8),
  borderRadius     : BORDER_RADIUS.full (999),
  marginRight      : SPACING.sm (8),
  marginBottom     : SPACING.sm (8),
}
  child: Text style = { color: isNext ? '#fff' : colors.text,
                        fontWeight: '700', fontSize: FONT_SIZE.sm (12) }
              children = display
```

### 2.6 `InfoBox` (local copy in module 1020)

Props: `{ icon (image asset), label: string, value: string, colors }`.

```
View  style = { width: '50%', paddingVertical: SPACING.sm (8),
                flexDirection: 'row', alignItems: 'center' }
 ├─ Image  source = icon
 │         style = { height: 20, width: 20, tintColor: colors.textSecondary,
 │                    marginRight: SPACING.sm (8) }
 └─ View
     ├─ Text  style = { fontSize: FONT_SIZE.xs (10), fontWeight: '700',
     │                  color: colors.textSecondary, letterSpacing: 0.4 }
     │          children = label
     └─ Text  style = { fontSize: FONT_SIZE.base (16), fontWeight: '800',
                        color: colors.text, marginTop: 2 }
                children = value
```

### 2.7 `HighlightedText` (module 1023) — behaviour

Props: `{ text = '', searchQuery = '', style = {}, highlightStyle = {} }`.

* If `!searchQuery || !text` → renders a single `<Text style={style}>{text}</Text>`.
* Otherwise splits `text` into segments matching `searchQuery.toLowerCase()` occurrences (case-insensitive, `indexOf` loop) and renders a `<Text style={style}>` whose children are `<Text style={highlightStyle}>matched</Text>` segments interleaved with `<Text style={style}>unmatched</Text>` segments.

### 2.8 Share behaviour (`handleShare`, async)

```js
await Share.share({ message: `${route.name} · ${route.frequency} | ${route.operatingHours}` });
```
* Library: **React Native core `Share.share({ message })`** (no `title`, no `url`).
* Message template: `<route.name> · <route.frequency> | <route.operatingHours>` — e.g. `Orange Line · Every 10 min | 6:00 AM - 11:00 PM`. Note: the literal separator between frequency and operating hours is **`' | '`** (space-pipe-space), and between name and frequency **`' · '`** (space-middot-space).
* Trigger: the share `Pressable` in the header (`onPress`).

---

## 3. `StopDetailScreen` (module 1072)

### 3.1 `route.params` read

| Param | Type | Use |
|---|---|---|
| `stopId` | string | primary lookup key for `getRoutesForStop`; also pushed as `focusStopId` to `Map` / `RouteDetail` |
| `stopName` | string | fallback for `getRoutesForStop` when `stopId` is falsy; fallback title |

```js
const routes = getRoutesForStop(stopId || stopName);        // Array<{route, index}>
const accent = routes.length ? (routes[0].route.color || colors.primary) : colors.primary;
const title  = routes.length ? routes[0].route.stops[routes[0].index] : (stopName || 'Stop');
useStatusBarColor(accent);
```

### 3.2 Exact UI structure

```
SafeAreaView  style = { flex: 1, backgroundColor: colors.background }   edges = ['top']
│
├─ View  (header band, background = accent)
│  style = { backgroundColor: accent,
│            paddingHorizontal: SPACING.md (16), paddingTop: SPACING.sm (8),
│            paddingBottom: SPACING.md (16),
│            flexDirection: 'row', alignItems: 'center' }
│  ├─ View  (back clip wrapper)
│  │    style = { borderRadius: BORDER_RADIUS.md (10), overflow: 'hidden', marginRight: SPACING.xs (4) }
│  │    └─ Pressable
│  │         android_ripple = { color: colors.white + '50' }
│  │         onPress = () => navigation.goBack()
│  │         style = { height: 35, width: 35, justifyContent: 'center', alignItems: 'center' }
│  │         └─ Image  source = <asset back> (1026)
│  │                   style = { height: 18, width: 18, tintColor: '#fff' }
│  └─ Text  numberOfLines = 2
│           style = { fontSize: FONT_SIZE.lg (18), fontWeight: '700', color: '#fff', flex: 1 }
│           children = title
│
└─ FlatList
   data                  = routes
   keyExtractor          = (item) => item.route.id
   contentContainerStyle = { padding: SPACING.md (16), paddingBottom: SPACING.xl (32) }
   ListHeaderComponent   = (below)
   ListEmptyComponent    = <Text style = { color: colors.textSecondary }>No lines found for this stop.</Text>
   renderItem            = (below)

   ┌─ ListHeaderComponent ───────────────────────────────────────────────
   │ Fragment
   │ │
   │ ├─ ① Pressable  ("View on Map")
   │ │    android_ripple = { color: '#ffffff30', foreground: true }
   │ │    onPress = () => navigation.navigate('Map',
   │ │               { routeId: routes[0] ? routes[0].route.id : undefined,
   │ │                 focusStopId: stopId || stopName,
   │ │                 color: accent })
   │ │    style = { flexDirection: 'row', alignItems: 'center',
   │ │              backgroundColor: accent, borderRadius: BORDER_RADIUS.lg (16),
   │ │              paddingVertical: SPACING.md (16), paddingHorizontal: SPACING.md (16),
   │ │              marginBottom: SPACING.md (16), overflow: 'hidden' }
   │ │    ├─ Image  source = <asset location-map> (1032)
   │ │    │          style = { height: 18, width: 18, tintColor: '#fff' }
   │ │    ├─ Text   style = { color: '#fff', fontWeight: '700',
   │ │    │                   fontSize: FONT_SIZE.base (16),
   │ │    │                   marginLeft: SPACING.sm (8), flex: 1 }
   │ │    │          children = 'View on Map'
   │ │    └─ Image  source = <asset arrow-right> (721)
   │ │               style = { height: 18, width: 18, tintColor: '#fff' }
   │ │
   │ ├─ ② Text  style = { color: colors.textSecondary, fontWeight: '600',
   │ │    │               marginBottom: SPACING.md (16) }
   │ │        children = [ routes.length, ' ', routes.length === 1 ? 'line' : 'lines',
   │ │                     ' serve this stop' ]
   │ │        → e.g. "3 lines serve this stop" / "1 line serve this stop"   (sic — always "serve")
   │ │
   │ ├─ ③ Text  style = { fontSize: FONT_SIZE.lg (18), fontWeight: '800',
   │ │    │               color: colors.text, marginBottom: SPACING.sm (8) }
   │ │        children = 'Lines serving this stop'
   │ │
   │ ├─ ④ View  (route chips)  style = { flexDirection: 'row', flexWrap: 'wrap',
   │ │    │                             marginBottom: SPACING.md (16) }
   │ │    children = routes.map(entry =>
   │ │      <View key = entry.route.id
   │ │        style = { flexDirection: 'row', alignItems: 'center',
   │ │                  backgroundColor: routeColor + '20', borderWidth: 1,
   │ │                  borderColor: routeColor + '50',
   │ │                  paddingHorizontal: SPACING.sm (8), paddingVertical: 4,
   │ │                  borderRadius: BORDER_RADIUS.full (999),
   │ │                  marginRight: SPACING.sm (8), marginBottom: SPACING.sm (8) }>
   │ │        ├─ Image  source = renderBusIcon(entry.route.category)
   │ │        │          style = { height: 13, width: 13, tintColor: routeColor, marginRight: 5 }
   │ │        └─ Text   style = { color: routeColor, fontWeight: '800',
   │ │                           fontSize: FONT_SIZE.md (14) }
   │ │                   children = entry.route.name
   │ │      </View>)
   │ │      (routeColor = entry.route.color || colors.primary)
   │ │
   │ └─ ⑤ Text  style = { fontSize: FONT_SIZE.lg (18), fontWeight: '800',
   │          │               color: colors.text, marginBottom: SPACING.sm (8) }
   │          │        children = 'Next departures'
   └──────────────────────────────────────────────────────────────────────

   renderItem = ({ item }) =>
     <LineDepartureCard item = item  colors = colors  onPress = () =>
        navigation.navigate('RouteDetail',
          { routeId: item.route.id,
            color: item.route.color || colors.primary,
            focusStopId: item.route.stops[item.index] }) />
```

### 3.3 `DepartureChip` (local copy in module 1072)

Identical to §2.5 **except** the non-highlighted background is `colors.card` (module-1020 copy uses `colors.background`). All other values identical: `borderWidth: 1`, `borderColor: isNext ? color : colors.border`, `paddingHorizontal: 16`, `paddingVertical: 8`, `borderRadius: 999`, `marginRight: 8`, `marginBottom: 8`, text `isNext ? '#fff' : colors.text`, `fontWeight: '700'`, `fontSize: 12`.

### 3.4 `LineDepartureCard` (module 1072)

Props: `{ item: { route, index }, colors, onPress }`.

```js
const routeColor = route.color || colors.primary;
const departures = useNextDepartures(route.frequency, route.operatingHours, 5);
const terminal   = index === route.stops.length - 1 ? route.stops[0]
                                                 : route.stops[route.stops.length - 1];
```

```
Pressable
  android_ripple = { color: routeColor + '30', foreground: true }
  onPress = onPress
  style = { backgroundColor: colors.card, borderRadius: BORDER_RADIUS.lg (16),
            padding: SPACING.md (16), marginBottom: SPACING.sm (8),
            elevation: 0.5, overflow: 'hidden' }
  │
  ├─ View  style = { flexDirection: 'row', alignItems: 'center', marginBottom: SPACING.sm (8) }
  │  ├─ View  (route badge)
  │  │    style = { flexDirection: 'row', alignItems: 'center',
  │  │              backgroundColor: routeColor + '20', borderWidth: 1,
  │  │              borderColor: routeColor + '50',
  │  │              paddingHorizontal: SPACING.sm (8), paddingVertical: 4,
  │  │              borderRadius: BORDER_RADIUS.md (10) }
  │  │    ├─ Image  source = renderBusIcon(route.category)
  │  │    │          style = { height: 13, width: 13, tintColor: routeColor, marginRight: 5 }
  │  │    └─ Text   style = { color: routeColor, fontWeight: '800', fontSize: FONT_SIZE.md (14) }
  │  │              children = route.name
  │  └─ View  style = { marginLeft: SPACING.sm (8), flex: 1, flexDirection: 'row', alignItems: 'center' }
  │     ├─ Feather  name = 'arrow-right'  size = 16
  │     └─ Text  numberOfLines = 1
  │              style = { marginLeft: SPACING.sm (8), flex: 1,
  │                        color: colors.textSecondary, fontWeight: '600' }
  │              children = terminal
  │
  └─ (departures.length !== 0)
       View  style = { flexDirection: 'row', flexWrap: 'wrap' }
         children = departures.map((d, i) =>
           <DepartureChip display = d.display  isNext = (i === 0)
                          color = routeColor   colors = colors />)   // NO React key
     (else)
       Text  style = { color: colors.textSecondary }  children = 'No more buses today'
```

### 3.5 Empty / error states
`ListEmptyComponent` = `'No lines found for this stop.'` (colour `colors.textSecondary`). No loading indicator (hook data may still be loading; the list simply renders empty).

---

## 4. `StopPickerScreen` (module 1073)

### 4.1 `route.params` read

```js
const params = route.params || {};
const mode  = params.mode || 'from';      // 'from' | anything else
const onSelect = params.onSelect;         // optional callback
const title    = params.title;            // optional custom header title
```

| Param | Type | Default | Use |
|---|---|---|---|
| `mode` | string | `'from'` | `'from'` ⇒ header title `'Select Departure Stop'` and the "Use current location" row is shown; any other value ⇒ `'Select Destination Stop'` and no location row |
| `onSelect` | `function(stop)` | — | called with the chosen stop object before `goBack()` |
| `title` | string | — | overrides the computed header title |

### 4.2 State

* `const [query, setQuery] = useState('')`
* `const [locating, setLocating] = useState(false)`
* `const results = useMemo(() => searchStops(query), [query])`
* `useStatusBarColor(colors.primary)`

### 4.3 `choose(stop)`

```js
function choose(stop) {
  if (route.params && route.params.onSelect) route.params.onSelect(stop);
  navigation.goBack();
}
```
(Called with the selected list item, or with the nearest stop from the location flow.)

### 4.4 `requestLocationPermission()`

`async` — `PermissionsAndroid.request(PermissionsAndroid.PERMISSIONS.ANDROID.ACCESS_FINE_LOCATION)` and returns `result === PermissionsAndroid.RESULTS.GRANTED`.

### 4.5 `useCurrentLocation` (the "Use current location" tap handler)

```js
setLocating(true);
requestLocationPermission().then((granted) => {
  if (!granted) { setLocating(false); return; }
  Geolocation.getCurrentPosition(
    { enableHighAccuracy: true, timeout: 15000 },
    (pos) => {
      const { latitude, longitude } = pos.coords;
      let nearest = null, best = Infinity;
      ALL_STOPS.forEach((st) => {
        if (st.latitude == null || st.longitude == null) return;
        const d = haversine(latitude, longitude, st.latitude, st.longitude);
        if (d < best) { best = d; nearest = st; }
      });
      setLocating(false);
      if (nearest) choose(nearest);   // → onSelect(nearest) + goBack()
      // if no coordinate-bearing stop exists: nothing happens (screen stays open)
    },
    (err) => { setLocating(false); }  // error path just re-enables the button
  );
});
```

Geolocation library: **`react-native-geolocation-service`** (module 729, default export) — `getCurrentPosition(options, success, error)`.

Inline `haversine(lat1, lon1, lat2, lon2)` (metres): standard spherical formula with `R = 6371000` (const `12742000 = 2*R`), `atan2(sqrt(a), sqrt(1-a))`.

### 4.6 Search / filter behaviour

* Filtering is done by **`searchStops(query)`**: trimmed, lower-cased substring match against the normalised stop **key** (`name.trim().toLowerCase()`), i.e. match is on the *normalised name* only (not route names).
* Empty / whitespace-only query ⇒ returns the full `ALL_STOPS` list.
* **Sort order:** `ALL_STOPS` is pre-sorted by `name.localeCompare(name)` (alphabetical, locale-aware). Filtering preserves that order; results are **not** re-sorted by relevance/distance.
* The `TextInput` has `autoFocus = true`; the list has `keyboardShouldPersistTaps: 'handled'`.

### 4.7 Exact UI structure

```
SafeAreaView  style = { flex: 1, backgroundColor: colors.background }   edges = ['top']
│
├─ View  (header band, background = colors.primary)
│  style = { backgroundColor: colors.primary,
│            paddingHorizontal: SPACING.md (16),
│            paddingTop: SPACING.sm (8),
│            paddingBottom: SPACING.sm (8) }
│  │
│  ├─ View  style = { flexDirection: 'row', alignItems: 'center',
│  │    │               marginBottom: SPACING.md (16) }
│  │  ├─ Pressable   (back)
│  │  │    android_ripple = { color: colors.white + '50', foreground: true }
│  │  │    onPress = () => navigation.goBack()
│  │  │    style = { height: 35, width: 35, justifyContent: 'center', alignItems: 'center',
│  │  │              borderRadius: BORDER_RADIUS.md (10), overflow: 'hidden',
│  │  │              marginRight: SPACING.xs (4) }
│  │  │    └─ Image  source = <asset back> (1026)
│  │  │              style = { height: 18, width: 18, tintColor: '#fff' }
│  │  └─ Text  style = { fontSize: FONT_SIZE.xl (22), fontWeight: '700', color: '#fff' }
│  │           children = title || (mode === 'from' ? 'Select Departure Stop'
│  │                                                : 'Select Destination Stop')
│  │
│  └─ View  (search field)
│       style = { flexDirection: 'row', alignItems: 'center',
│                 backgroundColor: 'rgba(255,255,255,0.2)',
│                 borderRadius: BORDER_RADIUS.md (10),
│                 paddingHorizontal: SPACING.md (16) }
│       ├─ Image  source = <asset search> (720)
│       │          style = { height: FONT_SIZE.base (16), width: FONT_SIZE.base (16),
│       │                    tintColor: 'rgba(255,255,255,0.8)', marginRight: SPACING.sm (8) }
│       └─ TextInput
│            value               = query
│            onChangeText        = setQuery
│            placeholder         = 'Type stop name...'
│            placeholderTextColor= 'rgba(255,255,255,0.7)'
│            autoFocus           = true
│            style               = { flex: 1, color: '#fff',
│                                    paddingVertical: 11 (SPACING.sm 8 + 3),
│                                    fontSize: FONT_SIZE.base (16) }
│
└─ FlatList
   data                        = results
   keyboardShouldPersistTaps   = 'handled'
   keyExtractor                = (item) => item.key
   contentContainerStyle       = { paddingBottom: SPACING.xl (32) }
   showsVerticalScrollIndicator= false
   ListHeaderComponent         = (below)
   ListEmptyComponent          = (below)
   renderItem                  = (below)

   ┌─ ListHeaderComponent ───────────────────────────────────────────────
   │ Fragment
   │ ├─ Pressable  ("Use current location")     ONLY when mode === 'from'
   │ │    android_ripple = { color: colors.primary + '20', foreground: true }
   │ │    onPress = useCurrentLocation
   │ │    style = { flexDirection: 'row', alignItems: 'center',
   │ │              paddingHorizontal: SPACING.md (16), paddingVertical: SPACING.md (16),
   │ │              backgroundColor: colors.card, overflow: 'hidden' }
   │ │    ├─ View  style = { width: 36, height: 36,
   │ │    │                  borderRadius: BORDER_RADIUS.md (10),
   │ │    │                  backgroundColor: colors.primary + '20',
   │ │    │                  alignItems: 'center', justifyContent: 'center',
   │ │    │                  marginRight: SPACING.md (16) }
   │ │    │    └─ Image  source = <asset location-direction> (1070)
   │ │    │              style = { height: 20, width: 20, tintColor: colors.primary }
   │ │    └─ Text  style = { flex: 1, fontSize: FONT_SIZE.base (16),
   │ │                     fontWeight: '700', color: colors.primary }
   │ │              children = locating ? 'Finding your location…' : 'Use current location'
   │ │
   │ └─ Text  (count header)
   │      style = { paddingHorizontal: SPACING.md (16), paddingVertical: SPACING.sm (8),
   │                color: colors.textSecondary, fontWeight: '600' }
   │      children = [ results.length, ' All Stops' ]
   └──────────────────────────────────────────────────────────────────────

   ListEmptyComponent:
     View  style = { alignItems: 'center', marginTop: SPACING.xl (32) }
       └─ Text  style = { color: colors.textSecondary }  children = 'No stops found'

   renderItem = ({ item }) =>
     <Pressable
        android_ripple = { color: colors.text + '20', foreground: true }
        onPress = () => choose(item)
        style = { flexDirection: 'row', alignItems: 'center',
                  paddingHorizontal: SPACING.md (16), paddingVertical: SPACING.md (16),
                  borderBottomWidth: 1, borderBottomColor: colors.border }>
       ├─ View  (leading icon)
       │    style = { width: 40, height: 40, borderRadius: BORDER_RADIUS.md (10),
       │              backgroundColor: colors.primary + '15',
       │              borderWidth: 1, borderColor: colors.primary + '30',
       │              alignItems: 'center', justifyContent: 'center',
       │              marginRight: SPACING.md (16) }
       │    └─ Image  source = <asset bus> (1074)
       │              style = { height: 22, width: 22, tintColor: colors.primary }
       ├─ View  style = { flex: 1 }
       │    ├─ Text  numberOfLines = 1
       │    │    style = { fontSize: FONT_SIZE.base (16), fontWeight: '700',
       │    │               color: colors.text }
       │    │    children = item.name
       │    └─ Text  numberOfLines = 1
       │         style = { fontSize: FONT_SIZE.sm (12), color: colors.textSecondary,
       │                   marginTop: 2 }
       │         children = [ item.routes.length, ' ',
       │                      item.routes.length === 1 ? 'line' : 'lines' ]
       └─ Image  source = <asset arrow-right> (721)
                 style = { height: 20, width: 20, tintColor: colors.textSecondary }
     </Pressable>
```

### 4.8 Strings (verbatim)
`'Select Departure Stop'`, `'Select Destination Stop'`, `'Type stop name...'`, `'Use current location'`, `'Finding your location…'` (U+2026 horizontal ellipsis), `' All Stops'` (leading space, concatenated to the count), `'line'` / `'lines'` / `' '`, `'No stops found'`.

---

## 5. `JourneyResultsScreen` (module 1075)

### 5.1 `route.params` read

| Param | Type | Use |
|---|---|---|
| `fromKey` | string | first argument of `findJourneys` |
| `toKey` | string | second argument of `findJourneys` |
| `fromName` | string | header title |
| `toName` | string | header subtitle (after the arrow icon) |

```js
const journeys = useMemo(() => findJourneys(fromKey, toKey), [fromKey, toKey]);
useStatusBarColor(colors.primary);
```

### 5.2 Exact UI structure

```
SafeAreaView  style = { flex: 1, backgroundColor: colors.background }   edges = ['top']
│
├─ View  (header band, background = colors.primary)
│  style = { backgroundColor: colors.primary,
│            paddingHorizontal: SPACING.md (16), paddingTop: SPACING.sm (8),
│            paddingBottom: SPACING.md (16),
│            flexDirection: 'row', alignItems: 'center' }
│  ├─ View  (back clip wrapper)
│  │    style = { borderRadius: BORDER_RADIUS.md (10), overflow: 'hidden', marginRight: SPACING.xs (4) }
│  │    └─ Pressable
│  │         android_ripple = { color: colors.white + '50', foreground: true }
│  │         onPress = () => navigation.goBack()
│  │         style = { height: 35, width: 35, justifyContent: 'center', alignItems: 'center',
│  │                   borderRadius: BORDER_RADIUS.md (10), overflow: 'hidden',
│  │                   marginRight: SPACING.xs (4) }
│  │         └─ Image  source = <asset back> (1026)
│  │                   style = { height: 18, width: 18, tintColor: '#fff' }
│  ├─ View  style = { flex: 1 }
│  │    ├─ Text  numberOfLines = 1
│  │    │    style = { fontSize: FONT_SIZE.lg (18), color: '#fff' }
│  │    │    children = fromName
│  │    └─ View  style = { flexDirection: 'row', alignItems: 'center' }
│  │         └─ Text  numberOfLines = 1
│  │              style = { fontSize: FONT_SIZE.sm (12), color: 'rgba(255,255,255,0.85)' }
│  │              children = [ <Feather name='arrow-right' size={15} />, toName ]
│  └─ View  (options pill)
│       style = { backgroundColor: 'rgba(255,255,255,0.2)',
│                 paddingHorizontal: SPACING.sm (8), paddingVertical: 6,
│                 borderRadius: BORDER_RADIUS.full (999) }
│       └─ Text  style = { color: '#fff', fontWeight: '700', fontSize: FONT_SIZE.sm (12) }
│                 children = [ journeys.length, ' Options' ]
│
└─ FlatList
   data                 = journeys
   keyExtractor         = (item, index) => `${index}-${item.legs.map(l => l.routeId).join('-')}`
   contentContainerStyle= { padding: SPACING.md (16), paddingBottom: SPACING.xl (32) }
   ListEmptyComponent   = (below)
   renderItem           = (below)

   ListEmptyComponent:
     View  style = { alignItems: 'center', marginTop: SPACING.xl (32),
                     paddingHorizontal: SPACING.lg (24) }
       ├─ Image  source = <asset search> (720)
       │          style = { height: 32, width: 32, tintColor: colors.textSecondary }
       └─ Text   style = { color: colors.textSecondary, marginTop: SPACING.sm (8),
                           textAlign: 'center' }
                 children = 'No bus route found between these stops, even with a walking transfer.'

   renderItem = ({ item }) =>
     <Pressable
        android_ripple = { color: colors.text + '15', foreground: true }
        onPress = () => navigation.navigate('JourneyDetail',
                      { journey: item, fromName, toName })
        style = { backgroundColor: colors.card, borderRadius: BORDER_RADIUS.lg (16),
                  padding: SPACING.md (16), marginBottom: SPACING.md (16),
                  elevation: 0.5, overflow: 'hidden' }>

       ├─ View  style = { flexDirection: 'row', alignItems: 'center', marginBottom: 6 }
       │  ├─ View  (transfers badge)
       │  │    style = { backgroundColor: (item.transfers === 0 ? '#2E7D32' : colors.primary) + '18',
       │  │              paddingHorizontal: SPACING.sm (8), paddingVertical: 4,
       │  │              borderRadius: BORDER_RADIUS.md (10), marginRight: SPACING.sm (8) }
       │  │    └─ Text  style = { color: item.transfers === 0 ? '#2E7D32' : colors.primary,
       │  │                     fontWeight: '800', fontSize: FONT_SIZE.sm (12) }
       │  │              children = item.transfers === 0 ? 'Direct'
       │  │                        : `${item.transfers} transfer${item.transfers > 1 ? 's' : ''}`
       │  ├─ Text  style = { color: colors.textSecondary, fontSize: FONT_SIZE.sm (12) }
       │  │        children = [ item.totalStops, ' stops' ]
       │  └─ Text  style = { color: colors.textSecondary, fontSize: FONT_SIZE.sm (12),
       │                    marginLeft: 'auto' }
       │           children = [ '~', formatMinutes(item.estimatedMinutes) ]
       │
       ├─ Text  style = { color: colors.text, fontSize: FONT_SIZE.md (14),
       │                  marginBottom: SPACING.sm (8) }
       │        children = [ item.legs[0].waitMinutes > 0
       │                        ? `Leave in ${item.legs[0].waitMinutes} min · ` : '',
       │                     item.startClock,
       │                     <Feather name='arrow-right' size={15} />,
       │                     item.arrivalClock ]
       │
       └─ item.legs.map((leg, i) =>
           <View key = {i}>
             <View style = { flexDirection: 'row', alignItems: 'center', marginBottom: 6 }>
               ├─ View  (route pill)
               │    style = { flexDirection: 'row', alignItems: 'center',
               │              backgroundColor: leg.color || colors.primary,
               │              paddingHorizontal: SPACING.sm (8), paddingVertical: 4,
               │              borderRadius: BORDER_RADIUS.sm (6),
               │              marginRight: SPACING.sm (8) }
               │    ├─ Image  source = renderBusIcon(leg.category)
               │    │          style = { height: 13, width: 13, tintColor: '#fff', marginRight: 4 }
               │    └─ Text   style = { color: '#fff', fontWeight: '600',
               │                       fontSize: FONT_SIZE.xs (10) }
               │              children = leg.routeName
               ├─ Image  source = <asset bus2> (717)
               │          style = { height: 15, width: 15, tintColor: leg.color, marginRight: 6 }
               └─ Text  numberOfLines = 1
                        style = { flex: 1, color: colors.text, fontSize: FONT_SIZE.sm (12) }
                        children = [ leg.fromName, ' ',
                                     <Feather name='arrow-right' size={15} />, ' ', leg.toName ]
             </View>
             { i < item.legs.length - 1 &&
                 <TransferRow leg = leg  nextLeg = item.legs[i + 1]  colors = colors /> }
           </View>)
```

### 5.3 `TransferRow` (module 1075)

Props: `{ leg, nextLeg, colors }`.

```
View  style = { flexDirection: 'row', alignItems: 'center',
                marginBottom: SPACING.xs (4), marginLeft: 2 }
│
├─ if (leg.transferWalk)   ── walking transfer:
│  ├─ MaterialCommunityIcons  name = 'walk'  size = 13  color = colors.textSecondary
│  │                          style = { marginRight: 5 }
│  └─ Text  style = { color: colors.textSecondary, fontSize: FONT_SIZE.xs (10) }
│           children = [ 'Transfer walk to ', leg.transferWalk.toName, ' · ',
│                        leg.transferWalk.minutes, ' min' ]
│           → "Transfer walk to Mall 1 · 4 min"
│
└─ else  ── same-station change:
   ├─ MaterialCommunityIcons  name = 'swap-horizontal'  size = 16  color = colors.textSecondary
   │                          style = { marginRight: 5 }
   └─ Text  style = { color: colors.textSecondary, fontSize: FONT_SIZE.md (14) }
            children = [ 'Change to', ' ',
                         <Text style = { fontWeight: '700', color: colors.text }>
                           {nextLeg.routeName}</Text>,
                         ' at ',
                         <Text style = { fontWeight: '700', color: colors.text }>
                           {leg.toName}</Text> ]
            → "Change to Orange Line at Central Terminal"
```

### 5.4 Strings
`' Options'` (leading space), `'Direct'`, `' transfer'`, `'s'`, `' stops'`, `'~'`, `'Leave in '`, `' min · '`, `'No bus route found between these stops, even with a walking transfer.'`, `'Transfer walk to '`, `' · '`, `' min'`, `'Change to'`, `' '`, `' at '`.

---

## 6. `JourneyDetailScreen` (module 1076)

### 6.1 `route.params` read

| Param | Type | Use |
|---|---|---|
| `journey` | object | the journey selected in `JourneyResultsScreen` (see §0.8 shape) |
| `fromName` | string | "FROM" block text |
| `toName` | string | "TO" block text |

```js
const colors = useTheme().colors;
useStatusBarColor(colors.primary);
```

### 6.2 Exact UI structure

```
SafeAreaView  style = { flex: 1, backgroundColor: colors.background }   edges = ['top']
│
├─ View  (header band, background = colors.primary)
│  style = { backgroundColor: colors.primary,
│            paddingHorizontal: SPACING.md (16), paddingTop: SPACING.sm (8),
│            paddingBottom: SPACING.md (16),
│            flexDirection: 'row', alignItems: 'center' }
│  ├─ View  (back clip wrapper)
│  │    style = { borderRadius: BORDER_RADIUS.md (10), overflow: 'hidden', marginRight: SPACING.xs (4) }
│  │    └─ Pressable
│  │         android_ripple = { color: colors.white + '50', foreground: true }
│  │         onPress = () => navigation.goBack()
│  │         style = { height: 35, width: 35, justifyContent: 'center', alignItems: 'center',
│  │                   borderRadius: BORDER_RADIUS.md (10), overflow: 'hidden',
│  │                   marginRight: SPACING.xs (4) }
│  │         └─ Image  source = <asset back> (1026)
│  │                   style = { height: 18, width: 18, tintColor: '#fff' }
│  ├─ Text  style = { fontSize: FONT_SIZE.xl (22), fontWeight: '700', color: '#fff', flex: 1 }
│  │        children = 'Journey'
│  └─ View  (transfers pill)
│       style = { backgroundColor: 'rgba(255,255,255,0.2)',
│                 paddingHorizontal: SPACING.sm (8), paddingVertical: 6,
│                 borderRadius: BORDER_RADIUS.full (999) }
│       └─ Text  style = { color: '#fff', fontWeight: '700', fontSize: FONT_SIZE.sm (12) }
│                 children = journey.transfers === 0 ? 'Direct'
│                           : `${journey.transfers} transfer${journey.transfers > 1 ? 's' : ''}`
│
└─ ScrollView
   contentContainerStyle       = { padding: SPACING.md (16), paddingBottom: SPACING.xl (32) }
   showsVerticalScrollIndicator = false

   ① View  (FROM / TO card)
      style = { backgroundColor: colors.card, borderRadius: BORDER_RADIUS.lg (16),
                padding: SPACING.md (16), marginBottom: SPACING.md (16), elevation: 1 }
      ├─ View  style = { flexDirection: 'row', alignItems: 'center', paddingVertical: SPACING.xs (4) }
      │  ├─ View  style = { width: 10, height: 10, borderRadius: 5,
      │  │                 backgroundColor: '#2E7D32', marginRight: SPACING.md (16) }
      │  └─ View
      │     ├─ Text  style = { fontSize: FONT_SIZE.xs (10), fontWeight: '700',
      │     │                   color: colors.textSecondary, letterSpacing: 0.5 }
      │     │          children = 'FROM'
      │     └─ Text  style = { fontSize: FONT_SIZE.base (16), fontWeight: '700',
      │                        color: colors.text, marginTop: 2 }
      │               children = fromName
      ├─ View  (divider)
      │    style = { height: 1, backgroundColor: colors.border,
      │              marginVertical: SPACING.sm (8), marginLeft: 18 }
      └─ View  style = { flexDirection: 'row', alignItems: 'center', paddingVertical: SPACING.xs (4) }
         ├─ View  style = { width: 10, height: 10, borderRadius: 3,
         │                 backgroundColor: '#C62828', marginRight: SPACING.md (16) }
         └─ View
            ├─ Text  style = { fontSize: FONT_SIZE.xs (10), fontWeight: '700',
            │                   color: colors.textSecondary, letterSpacing: 0.5 }
            │          children = 'TO'
            └─ Text  style = { fontSize: FONT_SIZE.base (16), fontWeight: '700',
                               color: colors.text, marginTop: 2 }
                      children = toName

   ② View  (clock strip)
      style = { backgroundColor: colors.card, borderRadius: BORDER_RADIUS.lg (16),
                padding: SPACING.md (16), marginBottom: SPACING.md (16),
                flexDirection: 'row', alignItems: 'center', elevation: 1 }
      ├─ Feather  name = 'clock'  size = 20  color = colors.primary
      │           style = { marginRight: SPACING.sm (8) }
      ├─ Text  style = { fontSize: FONT_SIZE.lg (18), fontWeight: '600',
                          color: colors.text, flex: 1 }
      │        children = [ journey.startClock, ' ',
      │                     <Feather name='arrow-right' size={20} />, '  ',
      │                     journey.arrivalClock ]
      └─ View  (Scheduled pill)
           style = { backgroundColor: colors.primary + '15',
                     paddingHorizontal: SPACING.sm (8), paddingVertical: 4,
                     borderRadius: BORDER_RADIUS.full (999) }
           └─ Text  style = { color: colors.primary, fontWeight: '700',
                              fontSize: FONT_SIZE.xs (10) }
                     children = 'Scheduled'

   ③ View  (stat row — 3 StatBoxes side by side)
      style = { backgroundColor: colors.card, borderRadius: BORDER_RADIUS.lg (16),
                marginBottom: SPACING.md (16), flexDirection: 'row', elevation: 1 }
      ├─ <StatBox icon='clock-outline'       label='DURATION'
      │            value = formatMinutes(journey.estimatedMinutes) colors={colors} />
      ├─ <StatBox icon='cash'                label='FARE'
      │            value = `Rs. ${journey.totalFare}`            colors={colors} />
      └─ <StatBox icon='swap-horizontal-bold' label='CHANGES'
                   value = String(journey.transfers)             colors={colors} last />

   ④ View  (action buttons)
      style = { flexDirection: 'row', marginBottom: SPACING.lg (24),
                gap: SPACING.sm (8) }
      ├─ <OutlineButton icon='map'   label='View on Map'   colors={colors}
      │     onPress = () => navigation.navigate('Map',
      │                 { routeId: journey.legs[0].routeId,
      │                   color:   journey.legs[0].color,
      │                   reversed: journey.legs[0].reversed }) />
      └─ <OutlineButton icon='share' label='Share Route'   colors={colors}
                        onPress = shareRoute />

   ⑤ Text  style = { fontSize: FONT_SIZE.xl (22), fontWeight: '800', color: colors.text }
              children = 'Step-by-step directions'

   ⑥ Text  style = { fontSize: FONT_SIZE.sm (12), color: colors.textSecondary,
                     marginBottom: SPACING.md (16) }
              children = [ (journey.legs.length * 2 - 1), ' step',
                           (journey.legs.length * 2 - 1) > 1 ? 's' : '', ' · ',
                           journey.totalStops, ' stops' ]

   ⑦ journey.legs.map((leg, i) => {
        const isLast  = i < journey.legs.length - 1;
        const hasWalk = isLast && !!leg.transferWalk;
        return (
        <View key = {i}>
          <View style = { flexDirection: 'row' }>
            <RailIcon icon='bus' color = leg.color || colors.primary
                      colors = colors  showLine = isLast />
            <View style = { flex: 1 }><LegCard leg leg colors navigation /></View>
          </View>
          { isLast &&
            <View style = { flexDirection: 'row', alignItems: 'center' }>
              <RailIcon icon = hasWalk ? 'walk' : 'swap-horizontal'
                        color = colors.textSecondary colors = colors showLine = true />
              <View style = { flex: 1 }>
                <TransferStep leg nextLeg = journey.legs[i+1] colors />
              </View>
            </View> }
        </View>);
      })

   ⑧ View  (Estimated Time card)
      style = { backgroundColor: colors.card, borderRadius: BORDER_RADIUS.lg (16),
                padding: SPACING.md (16), marginTop: SPACING.sm (8),
                marginBottom: SPACING.md (16), flexDirection: 'row',
                alignItems: 'center', elevation: 0.5 }
      ├─ Image  source = <asset route> (1022)
      │          style = { height: 20, width: 20, tintColor: colors.primary,
      │                    marginRight: SPACING.sm (8) }
      ├─ View  style = { flex: 1 }
      │  ├─ Text  style = { fontSize: FONT_SIZE.sm (12), fontWeight: '700',
      │  │                   color: colors.textSecondary }
      │  │          children = 'Estimated Time'
      │  └─ Text  style = { fontSize: FONT_SIZE.xl (22), fontWeight: '800',
      │                     color: colors.text }
      │            children = formatMinutes(journey.estimatedMinutes)
      └─ Text  style = { color: colors.textSecondary, fontStyle: 'italic',
                         fontSize: FONT_SIZE.md (14) }
                 children = 'estimate only'

   ⑨ View  (Travel Tips card)
      style = { backgroundColor: colors.primary + '10',
                borderRadius: BORDER_RADIUS.lg (16), padding: SPACING.md (16) }
      ├─ View  style = { flexDirection: 'row', alignItems: 'center',
                          marginBottom: SPACING.sm (8) }
      │  ├─ Text  style = { fontSize: FONT_SIZE.base (16) }  children = '💡'
      │  └─ Text  style = { fontSize: FONT_SIZE.base (16), fontWeight: '800',
      │                    color: colors.text, marginLeft: SPACING.xs (4) }
      │            children = 'Travel Tips'
      └─ TIPS.map((tip, i) =>
           <Text key={i} style = { color: colors.textSecondary,
                                   fontSize: FONT_SIZE.sm (12), marginBottom: 4 }>
             { [ '• ', tip ] }       // rendered as an array, no nested Text
           </Text>)
```

`TIPS` (exact array, module 1076):
```
1. 'Times are estimates — allow extra time for connections'
2. 'Bus times may vary due to traffic conditions'
3. 'Fares shown are per leg — confirm with the conductor'
```

### 6.3 `Chip` (module 1076)

Props: `{ icon (image asset), text: string, colors }`.

```
View  style = { flexDirection: 'row', alignItems: 'center',
                backgroundColor: colors.background, borderWidth: 1,
                borderColor: colors.border,
                paddingHorizontal: SPACING.sm (8), paddingVertical: 6,
                borderRadius: BORDER_RADIUS.full (999),
                marginRight: SPACING.sm (8), marginBottom: SPACING.sm (8) }
 ├─ Image  source = icon
 │         style = { height: 16, width: 16, tintColor: colors.textSecondary, marginRight: 5 }
 └─ Text  style = { color: colors.text, fontSize: FONT_SIZE.sm (12), fontWeight: '600' }
           children = text
```

### 6.4 `StatBox` (module 1076)

Props: `{ icon (icon name), label, value, colors, last = false }`.

```
View  style = { flex: 1, alignItems: 'center',
                paddingVertical: SPACING.sm (8),
                borderRightWidth: last ? 0 : 1,
                borderRightColor: colors.border }
 ├─ MaterialCommunityIcons  name = icon  size = 18  color = colors.primary
 │                           style = { marginBottom: 4 }
 ├─ Text  style = { fontSize: FONT_SIZE.xs (10), fontWeight: '700',
 │                  color: colors.textSecondary, letterSpacing: 0.4 }
 │          children = label
 └─ Text  style = { fontSize: FONT_SIZE.lg (18), fontWeight: '800',
                    color: colors.text, marginTop: 4 }
            children = value
```

### 6.5 `OutlineButton` (module 1076)

Props: `{ icon (icon name), label: string, onPress, colors }`.

```
Pressable
  android_ripple = { color: colors.primary + '20', foreground: true }
  onPress = onPress
  style = { flex: 1, flexDirection: 'row', alignItems: 'center',
            justifyContent: 'center', borderWidth: 1,
            borderColor: colors.primary, borderRadius: BORDER_RADIUS.full (999),
            paddingVertical: SPACING.sm (8), overflow: 'hidden' }
  ├─ Feather  name = icon  size = 17  color = colors.primary
  │          style = { marginRight: SPACING.xs (4) }
  └─ Text  style = { color: colors.primary, fontWeight: '700',
                     fontSize: FONT_SIZE.md (14) }
            children = label
```

### 6.6 `TransferStep` (module 1076)

Props: `{ leg, nextLeg, colors }`.

```
View  style = { flexDirection: 'row', alignItems: 'center',
                minHeight: 26, marginBottom: SPACING.sm (8), marginLeft: 5 }
 └─ Text  style = { color: colors.text, fontSize: FONT_SIZE.md (14), flex: 1 }
           children (nested <Text> children):
             no transferWalk  →  [ 'Change to', ' ',
                                   <Text style = { fontWeight: '800', fontSize: 14 }>
                                     {nextLeg.routeName}</Text>,
                                   ' at ',
                                   <Text style = { fontWeight: '800', fontSize: 14 }>
                                     {leg.toName}</Text> ]
             with transferWalk → [ 'Transfer walk to', ' ',
                                   <Text style = { fontWeight: '800', fontSize: 14 }>
                                     {leg.transferWalk.toName}</Text>, ' · ',
                                   <Text style = { fontWeight: '800', fontSize: 14 }>
                                     {[ leg.transferWalk.minutes, ' min' ]}</Text> ]
```

### 6.7 `RailIcon` (module 1076)

Props: `{ icon (icon name), color, colors, showLine }`.

```
View  style = { width: 40, alignItems: 'center' }
 ├─ View  style = { width: 40, height: 40, borderRadius: 50,
                    backgroundColor: color + '15',
                    alignItems: 'center', justifyContent: 'center' }
 │    └─ MaterialCommunityIcons  name = icon  size = 25  color = color
 └─ (if showLine) View  style = { flex: 1, width: 2,
                                  backgroundColor: colors.border,
                                  marginTop: 2, marginBottom: 2 }
```

### 6.8 `LegCard` (module 1076)

Props: `{ leg, colors, navigation }`.

```js
const legColor = leg.color || colors.primary;
const [expanded, setExpanded] = useState(false);
```

```
View  style = { backgroundColor: colors.card, borderRadius: BORDER_RADIUS.lg (16),
                marginBottom: SPACING.sm (8), overflow: 'hidden',
                marginLeft: 5, elevation: 0.5 }
│
├─ Pressable  (coloured header — tap = full route details)
│    android_ripple = { color: '#FFFFFF40', foreground: true }
│    onPress = () => navigation.navigate('RouteDetail',
│                   { routeId: leg.routeId, color: legColor })
│    style = { backgroundColor: legColor,
│              paddingHorizontal: SPACING.md (16), paddingVertical: SPACING.md (16),
│              flexDirection: 'row', alignItems: 'center' }
│    ├─ Image  source = renderBusIcon(leg.category)
│    │          style = { height: 26, width: 26, tintColor: '#fff',
│    │                    marginRight: SPACING.sm (8) }
│    ├─ View  style = { flex: 1 }
│    │    ├─ Text  style = { color: colors.white, fontWeight: '800',
│    │    │                   fontSize: FONT_SIZE.lg (18) }
│    │    │          children = [ 'Take ', leg.routeName ]
│    │    └─ Text  style = { color: 'rgba(255,255,255,0.85)',
│    │                       fontSize: FONT_SIZE.md (14), marginTop: 2 }
│    │              children = 'Tap for full route details'
│    └─ Text  style = { color: colors.white, fontSize: 18 }
│              children = '›'          (U+203A single right-pointing angle quotation mark)
│
└─ View  style = { padding: SPACING.md (16) }
   │
   ├─ View  (departure → arrival)
   │    style = { flexDirection: 'row', alignItems: 'center', marginBottom: SPACING.sm (8) }
   │    ├─ Text  style = { color: colors.text, fontWeight: '800',
   │    │                   fontSize: FONT_SIZE.base (16) }
   │    │          children = leg.departureClock
   │    ├─ Text  style = { color: colors.textSecondary, marginHorizontal: SPACING.sm (8) }
   │    │          children = [ <Feather name='arrow-right' size={18} /> ]
   │    └─ Text  style = { color: colors.text, fontWeight: '800',
   │                       fontSize: FONT_SIZE.base (16) }
   │              children = leg.arrivalClock
   │
   ├─ Text  numberOfLines = 2
   │    style = { color: colors.text, fontWeight: '700',
   │               marginBottom: SPACING.sm (8) }
   │    children = [ leg.fromName,
   │                 <Text style = { color: colors.textSecondary,
   │                                 marginHorizontal: SPACING.sm (8) }>
   │                   <Feather name='arrow-right' size={18} /></Text>,
   │                 leg.toName ]
   │
   ├─ View  (chip row)
   │    style = { flexDirection: 'row', flexWrap: 'wrap' }
   │    ├─ <Chip icon = <asset route> (1022)
   │    │        text = `Rs. ${leg.fare}`  colors = colors />
   │    └─ <Chip icon = <asset loop> (1029)
   │             text = leg.frequency       colors = colors />
   │
   ├─ Pressable  ("View on Map" for this leg)
   │    android_ripple = { color: '#FFFFFF50', foreground: true }
   │    onPress = () => navigation.navigate('Map',
   │                   { routeId: leg.routeId, color: legColor, reversed: leg.reversed })
   │    style = { flexDirection: 'row', alignItems: 'center',
   │              justifyContent: 'center', backgroundColor: legColor,
   │              borderRadius: BORDER_RADIUS.md (10),
   │              paddingVertical: SPACING.sm (8),
   │              marginTop: SPACING.xs (4), marginBottom: SPACING.sm (8),
   │              overflow: 'hidden' }
   │    ├─ Image  source = <asset location-map> (1032)
   │    │          style = { height: 22, width: 22, tintColor: '#fff',
   │    │                    marginRight: SPACING.xs (4) }
   │    └─ Text   style = { color: '#fff', fontWeight: '700',
   │                       fontSize: FONT_SIZE.md (14) }
   │              children = 'View on Map'
   │
   ├─ Pressable  (expand / collapse stop list)
   │    android_ripple = { color: colors.text + '15', foreground: true }
   │    onPress = () => setExpanded(!expanded)
   │    style = { flexDirection: 'row', alignItems: 'center',
   │              paddingVertical: SPACING.xs (4), justifyContent: 'center' }
   │    ├─ Entypo  name = expanded ? 'chevron-small-up' : 'chevron-small-down'
   │    │          size = 20  color = legColor      (Entypo is used ONLY for this chevron)
   │    └─ Text  style = { color: legColor, fontWeight: '700',
   │                       fontSize: FONT_SIZE.md (14) }
   │              children = [ leg.stopsTravelled, ' stops' ]
   │
   └─ (if expanded) View  style = { marginTop: SPACING.xs (4) }
        children = leg.stopNames.map((name, i) =>
          <View key = {i} style = { flexDirection: 'row', alignItems: 'center',
                                    paddingVertical: 4 }>
            ├─ View  style = { width: 6, height: 6, borderRadius: 3,
                              backgroundColor: legColor, marginRight: SPACING.sm (8) }
            └─ Text  style = { color: colors.text, fontSize: FONT_SIZE.md (14) }
                      children = name
          </View>)
```

### 6.9 Share behaviour (`shareRoute`)

Library: **React Native core `Share.share({ message })`** (no `title`/`url`).

Per-leg line format:
```
`${leg.routeName}: ${leg.fromName} → ${leg.toName} (${leg.departureClock} → ${leg.arrivalClock})`
```

Full message (legs joined by `'\n'`):
```
`${fromName} → ${toName}`
'\n'
`${journey.startClock} → ${journey.arrivalClock} · ~${formatMinutes(journey.estimatedMinutes)}`
'\n\n'
`${lines.join('\n')}`
```
i.e.:

```
<fromName> → <toName>
<startClock> → <arrivalClock> · ~<formatMinutes(estimatedMinutes)>
<blank line>
<leg1 routeName>: <leg1 fromName> → <leg1 toName> (<leg1 departureClock> → <leg1 arrivalClock>)
<leg2 routeName>: ...
```

Trigger: the `Share Route` `OutlineButton` (§6.5, `icon='share'`).

---

## 7. Cross-screen navigation table

| From screen | Trigger | Target route | Exact params |
|---|---|---|---|
| `RouteDetailScreen` | back button | — (pop) | `navigation.goBack()` |
| `RouteDetailScreen` | share button | native share sheet | `Share.share({ message })` |
| `RouteDetailScreen` | "View on Map" (header card) | `'Map'` | `{ routeId, color, reversed }` |
| `RouteDetailScreen` | direction row (any item) | — | sets `dirIndex`, closes dropdown (no navigation) |
| `RouteDetailScreen` | StopCard press | `'StopDetail'` | `{ stopId: direction.stopIds[index], stopName: item }` |
| `RouteDetailScreen` | StopCard map button | `'Map'` | `{ routeId, focusStopId: direction.stopIds[index], color, reversed }` |
| `StopDetailScreen` | back button | — (pop) | `navigation.goBack()` |
| `StopDetailScreen` | "View on Map" | `'Map'` | `{ routeId: routes[0]?.route.id, focusStopId: stopId \|\| stopName, color }` |
| `StopDetailScreen` | `LineDepartureCard` press | `'RouteDetail'` | `{ routeId, color: route.color \|\| colors.primary, focusStopId: route.stops[index] }` |
| `StopPickerScreen` | back button | — (pop) | `navigation.goBack()` |
| `StopPickerScreen` | stop row press | — (pop) | `choose(item)` → `onSelect(item)` then `goBack()` |
| `StopPickerScreen` | "Use current location" | — (pop) | `choose(nearestStop)` → `onSelect(nearestStop)` then `goBack()` |
| `JourneyResultsScreen` | back button | — (pop) | `navigation.goBack()` |
| `JourneyResultsScreen` | result card press | `'JourneyDetail'` | `{ journey: item, fromName, toName }` |
| `JourneyDetailScreen` | back button | — (pop) | `navigation.goBack()` |
| `JourneyDetailScreen` | `LegCard` header press | `'RouteDetail'` | `{ routeId: leg.routeId, color: legColor }` |
| `JourneyDetailScreen` | LegCard "View on Map" | `'Map'` | `{ routeId: leg.routeId, color: legColor, reversed: leg.reversed }` |
| `JourneyDetailScreen` | "View on Map" OutlineButton | `'Map'` | `{ routeId: journey.legs[0].routeId, color: journey.legs[0].color, reversed: journey.legs[0].reversed }` |
| `JourneyDetailScreen` | "Share Route" OutlineButton | native share sheet | `Share.share({ message })` |
| `JourneyDetailScreen` | LegCard expand row | — | toggles `expanded` (no navigation) |

---

## 8. All literal user-visible strings (verbatim)

**RouteDetailScreen:** `'Route not found'`, `'Searched for: "'` + query + `'"'`, `'NEXT DEPARTURES'`, `'No more buses today'`, `'DIRECTION'`, `'HOURS'`, `'FREQUENCY'`, `'FARE'`, `'TOTAL STOPS'`, `'Rs. '` (fare, e.g. `Rs. 25`), `'View on Map'`, `'Stops'`, `'Stops along this route'`.

**StopDetailScreen:** `'Stop'` (fallback title), `'View on Map'`, `' '`, `'line'`, `'lines'`, `' serve this stop'`, `'Lines serving this stop'`, `'Next departures'`, `'No lines found for this stop.'`, `'No more buses today'`.

**StopPickerScreen:** `'from'` (default mode), `'Select Departure Stop'`, `'Select Destination Stop'`, `'Type stop name...'`, `'Use current location'`, `'Finding your location…'`, `' All Stops'`, `' '`, `'line'`, `'lines'`, `'No stops found'`.

**JourneyResultsScreen:** `' Options'`, `'Direct'`, `' transfer'`, `'s'`, `' stops'`, `'~'`, `'Leave in '`, `' min · '`, `'No bus route found between these stops, even with a walking transfer.'`, `'Change to'`, `' '`, `' at '`, `'Transfer walk to '`, `' · '`, `' min'`.

**JourneyDetailScreen:** `'Journey'`, `'Direct'`, `' transfer'`, `'s'`, `'FROM'`, `'TO'`, `'Scheduled'`, `'DURATION'`, `'FARE'`, `'CHANGES'`, `'Rs. '`, `'View on Map'`, `'Share Route'`, `'Step-by-step directions'`, `' step'`, `'s'`, `' · '`, `' stops'`, `'Take '`, `'Tap for full route details'`, `'›'`, `'Estimated Time'`, `'estimate only'`, `'💡'`, `'Travel Tips'`, `'• '`, plus the 3 tips listed in §6.2.

**Navigation strings used:** `'Map'`, `'StopDetail'`, `'RouteDetail'`, `'JourneyDetail'`.

---

## 9. Icon inventory

| Screen / component | Icon set | Name | size | colour |
|---|---|---|---|---|
| RouteDetail direction selector | **MaterialCommunityIcons** | `chevron-down` / `chevron-up` | 24 | `colors.text` |
| RouteDetail direction row (selected) | **Feather** | `check` | 22 | `color` (param) |
| StopDetail / LineDepartureCard arrow | **Feather** | `arrow-right` | 16 | default (inherited) |
| JourneyResults `TransferRow` (walk) | **MaterialCommunityIcons** | `walk` | 13 | `colors.textSecondary` |
| JourneyResults `TransferRow` (change) | **MaterialCommunityIcons** | `swap-horizontal` | 16 | `colors.textSecondary` |
| JourneyResults header + leg arrows | **Feather** | `arrow-right` | 15 | default |
| JourneyDetail clock strip | **Feather** | `clock` | 20 | `colors.primary` |
| JourneyDetail clock strip arrow | **Feather** | `arrow-right` | 20 | default |
| JourneyDetail `StatBox` icons | **MaterialCommunityIcons** | `clock-outline`, `cash`, `swap-horizontal-bold` | 18 | `colors.primary` |
| JourneyDetail `OutlineButton` icons | **Feather** | `map`, `share` | 17 | `colors.primary` |
| JourneyDetail `RailIcon` (leg) | **MaterialCommunityIcons** | `bus` | 25 | `leg.color \|\| colors.primary` |
| JourneyDetail `RailIcon` (transfer) | **MaterialCommunityIcons** | `walk` (walk transfer) / `swap-horizontal` (change) | 25 | `colors.textSecondary` |
| JourneyDetail LegCard arrows | **Feather** | `arrow-right` | 18 | default |
| JourneyDetail LegCard expand chevron | **Entypo** | `chevron-small-down` / `chevron-small-up` | 20 | `legColor` |

---

## 10. Image-asset inventory (per screen)

| Screen | Asset | Rendered size | tint |
|---|---|---|---|
| RouteDetail | `back` (1026) | 18×18 | `#fff` |
| RouteDetail | `share` (1027) | 22×22 | `#FFF` |
| RouteDetail | `clock-filled` (1028) | 16×16 | route `color` |
| RouteDetail | `loop` (1029) | 22×22 | route `color` |
| RouteDetail | `clock` (1030) | 20×20 | `colors.textSecondary` (InfoBox) |
| RouteDetail | `route` (1022) | 20×20 | `colors.textSecondary` (InfoBox FARE) |
| RouteDetail | `stop` (1031) | 20×20 | `colors.textSecondary` (InfoBox TOTAL STOPS) |
| RouteDetail | `location-map` (1032) | 18×18 | `#FFF` |
| RouteDetail | `arrow-right` (721) | 16×16 | `#FFF` |
| RouteDetail → StopCard | `route` (1022) | 18×18 | `#fff` |
| StopDetail | `back` (1026) | 18×18 | `#fff` |
| StopDetail | `location-map` (1032) | 18×18 | `#fff` |
| StopDetail | `arrow-right` (721) | 18×18 | `#fff` |
| StopDetail chips | `renderBusIcon(category)` | 13×13 | route colour |
| StopPicker | `back` (1026) | 18×18 | `#fff` |
| StopPicker | `search` (720) | 16×16 | `rgba(255,255,255,0.8)` |
| StopPicker | `location-direction` (1070) | 20×20 | `colors.primary` |
| StopPicker rows | `bus` (1074) | 22×22 | `colors.primary` |
| StopPicker rows | `arrow-right` (721) | 20×20 | `colors.textSecondary` |
| JourneyResults | `back` (1026) | 18×18 | `#fff` |
| JourneyResults empty | `search` (720) | 32×32 | `colors.textSecondary` |
| JourneyResults legs | `renderBusIcon(category)` | 13×13 | `#fff` |
| JourneyResults legs | `bus2` (717) | 15×15 | `leg.color` |
| JourneyDetail | `back` (1026) | 18×18 | `#fff` |
| JourneyDetail LegCard header | `renderBusIcon(category)` | 26×26 | `#fff` |
| JourneyDetail LegCard chips | `route` (1022), `loop` (1029) | 16×16 | `colors.textSecondary` |
| JourneyDetail LegCard map | `location-map` (1032) | 22×22 | `#fff` |
| JourneyDetail Estimated Time | `route` (1022) | 20×20 | `colors.primary` |

---

## 11. Loading / empty / error states

| Screen | State | Behaviour |
|---|---|---|
| `RouteDetailScreen` | route not found (`getRouteById` returns falsy) | Full-screen centred `View` with `'Route not found'` (no FlatList) |
| `RouteDetailScreen` | no departures | `'No more buses today'` inside the NEXT DEPARTURES card |
| `RouteDetailScreen` | direction dropdown closed | only the summary `Pressable` renders (the panel `View` is omitted) |
| `RouteDetailScreen` | `searchQuery` empty/undefined | no "Searched for:" line; `HighlightedText` renders plain text |
| `RouteDetailScreen` | `stopName`/`stopId` fallback | `StopDetail` screen handles a missing stop (see below) |
| `RouteDetailScreen` | `data` when `direction` is undefined | FlatList `data = []` |
| `StopDetailScreen` | no lines for the stop | `ListEmptyComponent` = `'No lines found for this stop.'`; the header still renders "0 lines serve this stop", "Lines serving this stop" with an empty chip row, and "Next departures" with an empty list |
| `StopPickerScreen` | no matches for query | `ListEmptyComponent` = `'No stops found'` |
| `StopPickerScreen` | query empty | full `ALL_STOPS` list (alphabetical) under header `'<n> All Stops'` |
| `StopPickerScreen` | permission denied | `requestLocationPermission()` resolves `false` → `setLocating(false)` and nothing else happens (stays on screen) |
| `StopPickerScreen` | geolocation error | error callback → `setLocating(false)` only |
| `StopPickerScreen` | nearest stop not found (no stop has coordinates) | no navigation; screen stays open |
| `StopPickerScreen` | locating | "Use current location" label switches to `'Finding your location…'` |
| `JourneyResultsScreen` | 0 journeys | image + `'No bus route found between these stops, even with a walking transfer.'`; header pill shows `'0 Options'` |
| `JourneyDetailScreen` | no loading/empty state | journey object is always present (pushed from the results list) |
| All screens | theme | colours come from the light/dark theme; no explicit loading spinners anywhere in these modules |

---

## 12. User-interaction summary

| Interaction | Result |
|---|---|
| Back button (all 4 screens) | `navigation.goBack()` |
| RouteDetail share icon | async `Share.share({ message: '<name> · <frequency> \| <operatingHours>' })` |
| RouteDetail direction row | toggles the direction dropdown open/closed |
| RouteDetail direction option tap | sets the direction index (forward/reverse), closes the dropdown, FlatList re-renders with reversed `stops`/`stopIds` |
| RouteDetail "View on Map" | `navigate('Map', { routeId, color, reversed })` |
| RouteDetail StopCard tap | `navigate('StopDetail', { stopId, stopName })` |
| RouteDetail StopCard map button | `navigate('Map', { routeId, focusStopId, color, reversed })` |
| StopDetail "View on Map" | `navigate('Map', { routeId, focusStopId, color })` |
| StopDetail line card tap | `navigate('RouteDetail', { routeId, color, focusStopId })` |
| StopPicker text input | live filter via `searchStops` (normalised substring on stop key), alphabetical order preserved |
| StopPicker stop row tap | `onSelect(stop)` (if provided) then `goBack()` |
| StopPicker "Use current location" | permission request → geolocation → nearest `ALL_STOPS` entry by haversine → `choose(nearest)` |
| JourneyResults result card tap | `navigate('JourneyDetail', { journey, fromName, toName })` |
| JourneyDetail "View on Map" | `navigate('Map', { routeId: legs[0].routeId, color, reversed })` |
| JourneyDetail "Share Route" | `Share.share({ message })` with the multi-line itinerary (§6.9) |
| JourneyDetail LegCard header tap | `navigate('RouteDetail', { routeId, color })` |
| JourneyDetail LegCard "View on Map" | `navigate('Map', { routeId, color, reversed })` |
| JourneyDetail LegCard expand row | toggles the readable stop list (`leg.stopNames`) |
| Departure chips (RouteDetail / StopDetail) | non-interactive (informational only) |

---

## 13. Implementation notes / faithful-behaviour checklist

1. All four top-level screens use `SafeAreaView` from `react-native-safe-area-context` with `edges={['top']}` and `style={{ flex: 1, backgroundColor: colors.background }}`.
2. Status bar colour per screen: RouteDetail → `params.color`; StopDetail → accent colour; StopPicker / JourneyResults / JourneyDetail → `colors.primary`. Bar style defaults to `'light-content'`, translucent `true`.
3. `useNextDepartures` polls every 30 s — departure chips update while the screen is open.
4. RouteDetail auto-scroll: after mount, if `focusStopId` is set and not yet scrolled, a 500 ms `setTimeout` calls `scrollToIndex({ index, animated: true, viewPosition: 0.3 })`; the "failed" fallback uses `scrollToOffset({ offset: averageItemLength * index, animated: true })`.
5. Fare text everywhere is the literal prefix **`'Rs. '`** (capital R, lowercase s, **period**, single space) concatenated with the numeric value — e.g. `Rs. 25`. It is used in three places: RouteDetail `InfoBox` FARE (`route.fare || '25'` → `Rs. 25` when fare is null/0/undefined), JourneyDetail `StatBox` FARE (`Rs. ${journey.totalFare}`) and JourneyDetail `LegCard` Chip (`Rs. ${leg.fare}`). It is **not** `'Rs '`.
6. `StopCard` map-button `padding` is **11** (`SPACING.sm` 8 + literal 3) — the only style value in these modules that is not a token.
7. `JourneyResults` leg-pill `borderRadius` is `BORDER_RADIUS.sm` (6) while its transfers badge uses `BORDER_RADIUS.md` (10).
8. Ripple `foreground: true` on every `Pressable`; `android_ripple.color` uses the alpha-suffix pattern.
9. `LegCard` card has `marginLeft: 5` so the rail gutter (`RailIcon`, width 40) is respected.
10. `JourneyDetail` step count = `journey.legs.length * 2 - 1` (each leg is one step, each transfer is one step), pluralised with `'s'` when > 1.
