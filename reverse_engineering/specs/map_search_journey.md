# Lahore Speedo Bus Guide — Map / Search / Journey screens spec

Source: hermes-dec register-machine decompilation of the Metro bundle.

Modules covered:

| Module | File | Contents |
|---|---|---|
| 1033 | `app_graph_src/m1033.js` | `MapScreen` (+ `onMapReady`, `handleMarkerPress`, `openSheet`, `closeSheet`, `openDirections`, `openLocation`) |
| 1071 | `app_graph_src/m1071.js` | `SearchScreen` (+ `findMatchedStops`, `getFocusStop`, `searchInRoute`, `keyExtractor`, `renderItem`) |
| 1075 | `app_graph_src/m1075.js` | `JourneyResultsScreen` (+ `TransferRow`) |
| 1076 | `app_graph_src/m1076.js` | `JourneyDetailScreen` (+ `Chip`, `StatBox`, `OutlineButton`, `TransferStep`, `RailIcon`, `LegCard`, `shareRoute`) |

Supporting modules that these screens depend on (read in full, summarised in §0):

| Module | File | Exports |
|---|---|---|
| 570 | `m570.js` | `SPACING`, `FONT_SIZE`, `BORDER_RADIUS` (theme constants) |
| 576 | `m576.js` | `COLORS`, `DARK_COLORS` |
| 571 | `m571.js` | `ThemeProvider`, `useTheme` |
| 577 | `m577.js` | `useStatusBarColor(color, barStyle='light-content', animated=true)` |
| 1024 | `m1024.js` | `useRoutes()` |
| 1025 | `m1025.js` | `useNextDepartures(frequency, operatingHours, limit=5)` |
| 735 | `m735.js` | `timeToMinutes`, `parseOperatingHours`, `parseFrequencyMinutes`, `formatClock`, `formatDeparture`, `getNextDepartures` |
| 715 | `m715.js` | `CATEGORIES`, `CATEGORIES_FOR_SEARCH`, `getCategoryColor`, `renderBusIcon` |
| 718 | `m718.js` | `ROUTES` (data) + internal `categoryOf` |
| 719 | `m719.js` | raw GTFS |
| 734 | `m734.js` | `ALL_STOPS`, `searchStops`, `getStopByKey`, `findJourneys`, `formatMinutes`, `formatWalkDistance`, + internals `norm`, `routeById`, `haversine`, `walkMinutesFor`, `waitMinutesFrom`, `addMinutes`, `minutesOfDay`, `estimateTravelMinutes`, `buildLeg`, `findBestTransfer`, `legsSignature` |
| 1069 | `m1069.js` | `MAP_INITIAL_REGION` |
| 239/238 | `m239.js`, `m238.js` | `react/jsx-runtime` production shim (`jsx`, `jsxs`, `Fragment`) |
| 700 / 2 / 69 | — | `react-native` entry modules / `react` (`useState`, `useRef`, `useEffect`, `useMemo`, `useCallback`, `useContext`) |
| 558 | `m558.js` | `react-native-vector-icons/MaterialCommunityIcons` (default = icon component) |
| 727 | `m727.js` | `react-native-vector-icons/Feather` (default = icon component) |
| 1077 | `m1077.js` | `react-native-vector-icons/Entypo` (default = icon component) |
| 1034 | `m1034.js` | `react-native-maps` (default = `MapView`, plus `PROVIDER_GOOGLE`, `Polyline`, `Marker`) |

**Decompilation note.** Several small helpers (`openSheet`, `handleMarkerPress`, `openDirections`, `openLocation`, `findMatchedStops`, `getFocusStop`, `norm`, `routeById`, `haversine`, `walkMinutesFor`, `waitMinutesFrom`, `addMinutes`, `minutesOfDay`, `estimateTravelMinutes`, `findBestTransfer`, `legsSignature`) were **inlined by Hermes**, so the decompiler emits an empty body at the declaration and the real body at the single call site. Where that happened, this spec says so explicitly and transcribes the inlined body (marked *body inlined*). There is no `formatDistance` or `formatWalkTime` function anywhere in these modules.

---

## 0. Shared foundations

### 0.1 Theme constants (module 570)

```
SPACING      = { xs: 4,  sm: 8,  md: 16, lg: 24, xl: 32, xxl: 48 }
FONT_SIZE    = { xs: 10, sm: 12, md: 14, base: 16, lg: 18, xl: 22, xxl: 28, xxxl: 36 }
BORDER_RADIUS= { sm: 6,  md: 10, lg: 16, xl: 24, full: 999 }
```

### 0.2 Colors (module 576, delivered through `useTheme()`)

`useTheme()` returns `{ colors, isDark, toggleTheme, preference, setThemePreference }`.
`colors` = `preference === 'system' ? (Appearance.getColorScheme()==='dark' ? DARK : LIGHT) : (preference==='dark' ? DARK : LIGHT)` (ThemeProvider, module 571).

```
COLORS (light) = {
  primary: '#fc3b38', background: '#F5F7FA', card: '#FFFFFF', border: '#E0E0E0',
  text: '#212121', textSecondary: '#757575', white: '#FFFFFF', black: '#000000',
  overlay: 'rgba(0,0,0,0.5)'
}
DARK_COLORS = {
  primary: '#fc3b38', background: '#121212', card: '#2C2C2C', border: '#333333',
  text: '#EEEEEE', textSecondary: '#AAAAAA', white: '#FFFFFF', black: '#000000',
  overlay: 'rgba(0,0,0,0.7)'
}
```

### 0.3 `useStatusBarColor` (module 577)

`useStatusBarColor(color, barStyle = 'light-content', animated = true)`
→ inside `useFocusEffect(useCallback(() => { StatusBar.setBarStyle(barStyle, animated); StatusBar.setBackgroundColor(color, animated); }, [color, barStyle, animated]))`.
All four screens call it with a single argument: `useStatusBarColor(colors.primary)`.

### 0.4 Data model — `ROUTES` (module 718)

`ROUTES = gtfs.lines.map(line => {...})` where `line.patterns[0].stops` is the stop list. Each route object has, in key order:

```
{
  id:             line.id,                 // e.g. 'pma-lahore-59'
  name:           line.shortName,          // e.g. 'Electric RT20'
  stationAddress: line.longName,           // e.g. 'Jinnah Bus Terminal to Raiwind'
  frequency:      line.frequency,          // e.g. 'Every 10-30 minutes'
  operatingHours: line.scheduleDisplay,    // e.g. '06:00 AM - 10:00 PM'
  category:       categoryOf(shortName),
  fare:           String(line.ticketCost ?? '25'),
  color:          line.color,              // GTFS color, e.g. '#D6298E'
  stops:          pattern[0].stops.map(s => s.name),   // string[]
  stopIds:        pattern[0].stops.map(s => s.id),     // string[]
  coords:         pattern[0].stops.map(s => ({latitude: s.lat, longitude: s.lng, name: s.name, id: s.id}))
}
```

`categoryOf(name)` `[inlined body]`:

```
if (!name) name = ''
if (name.startsWith('Speedo')) return 'speedo'
if (name.startsWith('Metro'))   return 'metro'
if (name.startsWith('Orange'))  return 'orangeLine'
return 'electric'
```

### 0.5 `useRoutes()` (module 1024)

State initialised with `routes = []`, `loading = true`, `error = null`. `useEffect(..., [])` on mount:

```
try { setRoutes(ROUTES); setLoading(false) }
catch (e) { setError('Failed to load routes'); setLoading(false) }
```

Returns (key order): `{ routes, getRouteById, searchRoutes, getRoutesByCategory, loading, error, getMaps, getRoutesForStop, getStopCoordinate }`.

* `getRouteById(id)` → `ROUTES.find(r => r.id === id) ? {...route} : null`
* `searchRoutes(q)` → `ROUTES.filter(r => r.name.toLowerCase().includes(q) || r.id.toLowerCase().includes(q))`
* `getRoutesByCategory(category)` → `(category && category !== 'all') ? ROUTES.filter(r => r.category === category) : ROUTES`
* `getMaps(routeId)` → **`route.coords`** (array of `{latitude, longitude, name, id}`) or `[]` if the route id is unknown
* `getRoutesForStop(stopKey)` → for every route: `let i = route.stopIds.indexOf(stopKey); if (i === -1) i = route.stops.findIndex(s => norm(s) === norm(stopKey))`; collects `{route, index: i}` for all routes where `i >= 0` (note: the first lookup uses the **raw** key, the fallback normalises it)
* `getStopCoordinate(routeId, index)` → `route ? (route.coords[index] ?? null) : null`
* `searchRoutes` / `getRouteById` etc. are `useCallback(..., [])`

### 0.6 Departure helpers (module 735, consumed via `useNextDepartures`, module 1025)

`useNextDepartures(frequency, operatingHours, limit = 5)`:
state is initialised from `getNextDepartures(frequency, operatingHours, limit)`; a `useEffect` on `[frequency, operatingHours, limit]` re-computes the value and starts `setInterval(update, 30000)` (30 s), cleared on unmount/dep change.

`parseOperatingHours(s)`:

```
s = String(s ?? '6:00 AM - 10:00 PM')
[start, end] = s.split(/-|to/i).map(x => x.trim())
parse 'H:MM AM|PM'  (regex /(\d{1,2}):(\d{2})\s*(AM|PM)/i)
  h = parseInt(hh,10); m = parseInt(mm,10)
  if /pm/i.test(ap) && h !== 12 → h += 12
  if /am/i.test(ap) && h === 12 → h = 0
  minutes = h*60 + m ; if no match → 0
start = start ?? 0 ; end = end ?? 1439
return { start, end }
```

`parseFrequencyMinutes(s)`:

```
nums = String(s ?? '15').match(/\d+/g)?.map(Number) ?? [15]
return Math.round((nums[0] + (nums[1] ?? nums[0])) / 2)
```

`formatClock(minutesOfDay)`:

```
h = Math.floor(m/60) % 24 ; mm = m % 60
ap = h >= 12 ? 'PM' : 'AM'
h12 = h % 12 || 12
return `${h12}:${String(mm).padStart(2,'0')} ${ap}`
```

`getNextDepartures(frequency, operatingHours, limit = 5, now = new Date())`:

```
freq   = parseFrequencyMinutes(frequency ?? '15')
hours  = parseOperatingHours(operatingHours)
nowMin = now.getHours()*60 + now.getMinutes()
if (nowMin > hours.end) return []
t = nowMin < hours.start ? hours.start
                        : hours.start + Math.ceil((nowMin - hours.start)/freq)*freq
out = []
while (t <= hours.end && out.length < limit) {
  away = Math.max(0, t - nowMin)
  display = away <= 0 ? 'Due' : (away < 60 ? `${away} min` : formatClock(t))
  out.push({ display, minutesAway: away })
  t += freq
}
return out
```

`formatDeparture(minutesAway)` is declared but not used by these four screens.

### 0.7 Category constants (module 715)

`renderBusIcon(category)` (switch) → the image asset:
`'speedo' → speedo`, `'metro' → metro`, `'orangeLine' → orange-line`, `'electric' → electric`, `'all' → filter`, **default → bus2**.

`CATEGORIES_FOR_SEARCH` = (key order, first element is the "All" chip, then `...CATEGORIES`):

| key | label | icon asset | color | data |
|---|---|---|---|---|
| `all` | `'All'` | `filter` | `COLORS.primary` (`#fc3b38`) | — |
| `speedo` | `'Speedo'` | `speedo` | `#e12221` | `ROUTES.filter(r => r.category==='speedo')` |
| `metro` | `'Metro'` | `metro` | `#358437` | `ROUTES.filter(r => r.category==='metro')` |
| `orangeLine` | `'Orange Line'` | `orange-line` | `#e29109` | `ROUTES.filter(r => r.category==='orangeLine')` |
| `electric` | `'Electric'` | `electric` | `#358437` | `ROUTES.filter(r => r.category==='electric')` |

`getCategoryColor(key)` → matching `CATEGORIES` entry color, else `COLORS.primary`.

### 0.8 Image assets used by these screens

All are registered Metro assets: `httpServerLocation: '/assets/src/assets/icons'`, `scales: [1]`, `type: 'jpg'`.

| Module id | asset name | intrinsic px |
|---|---|---|
| 709 | `speedo` | 96×96 |
| 711 | `metro` | 96×96 |
| 712 | `electric` | 96×96 |
| 713 | `orange-line` | 96×96 |
| 716 | `filter` | 64×64 |
| 717 | `bus2` | 96×96 |
| 720 | `search` | 48×48 |
| 721 | `arrow-right` | 64×64 |
| 736 | `location` | 48×48 |
| 1022 | `route` | 48×48 |
| 1026 | `back` | 48×48 |
| 1028 | `clock-filled` | 48×48 |
| 1029 | `loop` | 48×48 |
| 1032 | `location-map` | 64×64 |
| 1070 | `location-direction` | 64×64 |

### 0.9 Icon sets and every icon glyph used

**`react-native-vector-icons/MaterialCommunityIcons`** (module 558) — default export used as `<Icon name=… size=… color=… style=…/>`:

| glyph | size | where |
|---|---|---|
| `swap-horizontal` | 16 | JourneyResults `TransferRow` (no walk transfer) |
| `walk` | 13 | JourneyResults `TransferRow` (walk transfer) |
| `clock-outline` | 18 | JourneyDetail `StatBox` "DURATION" |
| `cash` | 18 | JourneyDetail `StatBox` "FARE" |
| `swap-horizontal-bold` | 18 | JourneyDetail `StatBox` "CHANGES" |
| `bus` | 25 | JourneyDetail `RailIcon` (ride leg) |
| `walk` / `swap-horizontal` | 25 | JourneyDetail `RailIcon` (transfer leg) |

**`react-native-vector-icons/Feather`** (module 727):

| glyph | size | where |
|---|---|---|
| `arrow-right` | 15 | MapScreen route card (`stops[0] → stops[last]`), JourneyResults header sub-title, JourneyResults leg rows, JourneyResults "Leave in …" row |
| `clock` | 20 | JourneyDetail schedule card (color `colors.primary`) |
| `arrow-right` | 20 | JourneyDetail schedule card (`startClock → arrivalClock`) |
| `arrow-right` | 18 | JourneyDetail `LegCard` (`departureClock → arrivalClock`, `fromName → toName`) |
| `map` | 17 | JourneyDetail `OutlineButton` "View on Map" |
| `share` | 17 | JourneyDetail `OutlineButton` "Share Route" |

**`react-native-vector-icons/Entypo`** (module 1077):

| glyph | size | where |
|---|---|---|
| `chevron-small-down` | 20 | JourneyDetail `LegCard` expand toggle (collapsed) |
| `chevron-small-up` | 20 | JourneyDetail `LegCard` expand toggle (expanded) |

---

# 1. MapScreen — module 1033

## 1.1 Props and route params

```js
MapScreen({ navigation, route })
const { routeId, focusStopId, color, reversed } = (route == null ? {} : (route.params ?? {}));
```

| param | meaning |
|---|---|
| `routeId` | id of the route to draw; may be undefined (then no markers/polyline) |
| `focusStopId` | stop **id or stop name** to auto-select after the map is ready |
| `color` | route colour override; falls back to `colors.primary` |
| `reversed` | when true the stop order is reversed (dest-to-origin direction) |

## 1.2 State and derived values

| variable | source |
|---|---|
| `colors` | `useTheme().colors` |
| `{ getRouteById, getMaps }` | `useRoutes()` |
| `mapRef` | `useRef(null)` (attached to `MapView`) |
| `slideAnim` | `useRef(new Animated.Value(0)).current` |
| `[isMapReady, setIsMapReady]` | `useState(false)` |
| `[mapType, setMapType]` | `useState('standard')` |
| `[selected, setSelected]` | `useState(null)` — normalised stop `{id,name,latitude,longitude}` |
| `[sheetVisible, setSheetVisible]` | `useState(false)` |
| `route` | `routeId ? getRouteById(routeId) : null` |
| `stops` | `route ? (reversed ? [...route.stops].reverse() : route.stops) : []` |
| `routeColor` | `color ?? colors.primary` |
| `maps` | `reversed ? [...getMaps(routeId)].reverse() : getMaps(routeId)` |
| `departures` | `useNextDepartures(route?.frequency, route?.operatingHours, 3)` — **limit 3** |
| `stopsWithCoords` | `useMemo(() => maps.map((m, i) => ({ id: m.id, name: m.name, lat: m.latitude, lng: m.longitude, idx: i + 1 })), [maps])` |
| `initialRegion` | `stopsWithCoords.length > 0 ? { latitude: stopsWithCoords[3].lat, longitude: stopsWithCoords[3].lng, latitudeDelta: 0.05, longitudeDelta: 0.05 } : MAP_INITIAL_REGION` (index 3 is a literal in the shipped bundle) |
| `translateY` | `slideAnim.interpolate({ inputRange: [0,1], outputRange: [300,0] })` |

`MAP_INITIAL_REGION` (module 1069) = `{ latitude: 31.5204, longitude: 74.3587, latitudeDelta: 0.2, longitudeDelta: 0.2 }` (Lahore).

## 1.3 Helper functions

* **`onMapReady()`** — `setIsMapReady(true)`.
* **`openSheet(stop)`** `[body inlined at call sites]` — sets the selected stop, opens the sheet and springs the sheet in:
  ```
  openSheet(stop) {
    setSelected({ id: stop.id, name: stop.name, latitude: stop.lat, longitude: stop.lng });
    setSheetVisible(true);
    Animated.spring(slideAnim, { toValue: 1, useNativeDriver: true, tension: 60, friction: 10 }).start();
  }
  ```
* **`handleMarkerPress(stop)`** — *body inlined at the marker `onPress`* — recentres the map on the marker (400 ms) then opens the sheet:
  ```
  handleMarkerPress(stop) {
    mapRef.current?.animateToRegion({ latitude: stop.lat, longitude: stop.lng,
                                      latitudeDelta: 0.01, longitudeDelta: 0.01 }, 400);
    openSheet({ id: stop.id, name: stop.name, latitude: stop.lat, longitude: stop.lng });
  }
  ```
* **`closeSheet()`** — `Animated.timing(slideAnim, { toValue: 0, duration: 250, useNativeDriver: true }).start(() => { setSheetVisible(false); setSelected(null); })`.
* **`openDirections(lat, lng)`** `[body inlined at the "Get Direction" press]`:
  `Linking.openURL('https://www.google.com/maps/dir/?api=1&destination=' + lat + ',' + lng + '&travelmode=transit')`
* **`openLocation(lat, lng)`** `[body inlined at the "View on Map" press]`:
  `Linking.openURL('geo:' + lat + ',' + lng + '?q=' + lat + ',' + lng + '(' + encodeURIComponent('') + ')')`
  i.e. `geo:<lat>,<lng>?q=<lat>,<lng>()` — the URI-encoded label is an empty string.

## 1.4 Effects

1. `useEffect(..., [isMapReady, stopsWithCoords])`:
   ```
   if (!isMapReady) return
   if (stopsWithCoords.length <= 1) return
   if (!mapRef.current) return
   mapRef.current.fitToCoordinates(stopsWithCoords.map(s => ({latitude: s.lat, longitude: s.lng})),
     { edgePadding: { top: 100, right: 60, bottom: 60, left: 60 }, animated: false })
   ```
2. `useEffect(..., [isMapReady, focusStopId, stopsWithCoords])`:
   ```
   if (!isMapReady || !focusStopId) return
   const target = stopsWithCoords.find(s => s.id === focusStopId || s.name === focusStopId)
   if (!target) return
   const t = setTimeout(() => {
     mapRef.current?.animateToRegion({ latitude: target.lat, longitude: target.lng,
                                       latitudeDelta: 0.01, longitudeDelta: 0.01 }, 500)
     openSheet({ id: target.id, name: target.name, latitude: target.lat, longitude: target.lng })
   }, 400)
   return () => clearTimeout(t)
   ```
   (the timeout body also performs `setSheetVisible(true)` + the spring — see `openSheet` above.)
3. `useStatusBarColor(routeColor)` — on mount/focus.

## 1.5 Exact UI structure

Root: `jsxs(View, { style: { flex: 1, backgroundColor: colors.background } }, [ A, B, C, D, E ])`

**A. Map view** — `jsxs(MapView, {...}, [ polyline?, ...markers ])`

```
<MapView
  ref={mapRef}
  provider={MapView.PROVIDER_GOOGLE}          // react-native-maps, Google provider
  style={{ flex: 1 }}
  initialRegion={initialRegion}
  mapType={mapType}                            // 'standard' | 'satellite'
  onMapReady={() => setIsMapReady(true)}
>
```
* Polyline — rendered when `stopsWithCoords.length > 1`:
  `jsx(Polyline, { coordinates: stopsWithCoords.map(s => ({latitude: s.lat, longitude: s.lng})), strokeColor: routeColor, strokeWidth: 5 })`
* Markers — `stopsWithCoords.map(stop => …)`, key = `stop.id || stop.name`:
  ```
  <Marker
    coordinate={{ latitude: stop.lat, longitude: stop.lng }}
    onPress={ () => { handleMarkerPress(stop) ; <inline recentre + openSheet sequences of §1.3> } }
    anchor={{ x: 0.5, y: 0.5 }}
    tracksViewChanges={false}
  >
    <View style={{
      width:        isSelected ? 22 : 14,
      height:       isSelected ? 22 : 14,
      borderRadius: 11,                    // literal, same for both states
      backgroundColor: isSelected ? routeColor : '#F00',
      borderWidth:  isSelected ? 3 : 2,
      borderColor:  '#fff'
    }} />
  </Marker>
  ```
  `isSelected = selected && (selected.id === stop.id || selected.name === stop.name)`.

**B. Map-type toggle** (absolute, top of map):
```
<Pressable onPress={() => setMapType(p => p === 'standard' ? 'satellite' : 'standard')}
          style={{ position:'absolute', top:100, right:16, backgroundColor:'#fff',
                   paddingHorizontal:16, paddingVertical:8, borderRadius:10, elevation:4 }}>
  <Text style={{ fontWeight:'700', fontSize:12, color:'#111' }}>
    {mapType === 'standard' ? 'Satellite' : 'Street'}
  </Text>
</Pressable>
```
(SPACING.md/SPACING.sm, BORDER_RADIUS.md, FONT_SIZE.sm expanded.)

**C. Header overlay** — `jsx(SafeAreaView, { edges:['top'], style:{ position:'absolute', top:0, left:0, right:0, zIndex:10 } }, [ … ])`
```
<SafeAreaView edges={['top']}
             style={{ position:'absolute', top:0, left:0, right:0, zIndex:10 }}>
  <View style={{ backgroundColor: routeColor, flexDirection:'row', alignItems:'center',
                 paddingHorizontal:16, paddingVertical:8 }}>
    <View style={{ borderRadius:10, overflow:'hidden', marginRight:8 }}>
      <Pressable android_ripple={{ color: '#fff' + '50' }}     // => color:'#fff50'
                 onPress={() => navigation.goBack()}
                 style={{ height:35, width:35, justifyContent:'center', alignItems:'center' }}>
        <Image source={back} style={{ height:18, width:18, tintColor:'#fff' }} />
      </Pressable>
    </View>
    <View style={{ flex:1 }}>
      <Text numberOfLines={1} style={{ fontSize:18, fontWeight:'700', color:'#fff' }}>
        {route ? route.stationAddress : 'Map'}
      </Text>
      {stops.length > 0 && (
        <Text style={{ fontSize:14, color:'rgba(255,255,255,0.8)' }}>
          {[stops.length, ' stops on route']}
        </Text>)}
    </View>
  </View>
</SafeAreaView>
```
(SPACING.xs=8 marginRight, BORDER_RADIUS.md=10, FONT_SIZE.lg=18, FONT_SIZE.md=14.)

**D. Bottom sheet** — rendered when `sheetVisible && selected`:
```
<Animated.View style={{ position:'absolute', bottom:20, left:20, right:20,
                         backgroundColor: colors.card, borderRadius:16, padding:16,
                         elevation:10, transform:[{ translateY }] }}>
  <View style={{ flexDirection:'row', justifyContent:'space-between',
                 alignItems:'flex-start', position:'relative' }}>
    <View style={{ flex:1 }}>
      <Text numberOfLines={2} style={{ fontSize:22, fontWeight:'800', color: colors.text }}>
        {selected.name}
      </Text>
      <View style={{ marginTop:16, flexDirection:'row', gap:8 }}>
        <Pressable android_ripple={{ color:'#FFFFFF40', foreground:true }}
                   onPress={() => openDirections(selected.latitude, selected.longitude)}
                   style={{ flexDirection:'row', paddingVertical:16, overflow:'hidden',
                            backgroundColor: routeColor, borderRadius:999,
                            justifyContent:'center', alignItems:'center', flex:1 }}>
          <Image source={location-direction} style={{ height:17, width:17, tintColor:'#FFF', marginRight:4 }} />
          <Text style={{ fontSize:18, color:'#FFF' }}>Get Direction</Text>
        </Pressable>
        <Pressable android_ripple={{ color:'#FFFFFF40', foreground:true }}
                   onPress={() => openLocation(selected.latitude, selected.longitude)}
                   style={{ flexDirection:'row', paddingVertical:16, overflow:'hidden',
                            backgroundColor: routeColor, borderRadius:999,
                            justifyContent:'center', alignItems:'center', flex:1 }}>
          <Image source={location-map} style={{ height:17, width:17, tintColor:'#FFF', marginRight:4 }} />
          <Text style={{ fontSize:18, color:'#FFF' }}>View on Map</Text>
        </Pressable>
      </View>
    </View>
    <Pressable hitSlop={{ top:20, bottom:20, left:20, right:20 }}
               android_ripple={{ color: colors.text + '15' }}
               onPress={closeSheet}
               style={{ position:'absolute', top:-5, right:0, height:40, width:40,
                        overflow:'hidden', backgroundColor: colors.background,
                        borderRadius:999, justifyContent:'center', alignItems:'center' }}>
      <Text style={{ fontSize:18, color: colors.textSecondary }}>✕</Text>
    </Pressable>
  </View>
</Animated.View>
```

**E. Route summary card** — rendered when `!sheetVisible && route && stops.length > 0`:
```
<View style={{ position:'absolute', bottom:20, left:20, right:20,
               backgroundColor: colors.card, borderRadius:16, padding:16, elevation:10 }}>
  <View style={{ flexDirection:'row', alignItems:'center' }}>
    <View style={{ width:10, height:10, borderRadius:5,
                   backgroundColor: routeColor, marginRight:8 }} />
    <Text numberOfLines={1} style={{ flex:1, fontSize:16, fontWeight:'800', color: colors.text }}>
      {[ stops[0], '  ', <FeatherIcon name="arrow-right" size={15} />, ' ', stops[stops.length-1] ]}
    </Text>
  </View>
  <Text style={{ fontSize:12, color: colors.textSecondary, marginTop:4, marginLeft:18 }}>
    {[ (route.frequency ? 'Every ' + String(route.frequency).replace(/^every\s*/i, '') : ''),
       ' · ', stops.length, ' stops' ]}
  </Text>
  {departures.length > 0 && (
    <View style={{ flexDirection:'row', flexWrap:'wrap', marginTop:8 }}>
      {departures.map((d, i) =>
        <View key={`${d.display}${i}`}
              style={{ backgroundColor: i === 0 ? routeColor : colors.background,
                       borderWidth:1,
                       borderColor: i === 0 ? routeColor : colors.border,
                       paddingHorizontal:10,           // SPACING.sm + 2
                       paddingVertical:6,
                       borderRadius:999,               // BORDER_RADIUS.full
                       marginRight:8, marginBottom:8 }}>
          <Text style={{ color: i === 0 ? '#fff' : colors.text,
                         fontWeight:'700', fontSize:12 }}>{d.display}</Text>
        </View>)}
    </View>)}
</View>
```

## 1.6 Map library specifics

* **Library**: `react-native-maps` (default export `MapView`), Google provider (`MapView.PROVIDER_GOOGLE`).
* `mapType`: `'standard'` | `'satellite'` (local state, toggled by the absolute button; **not** persisted).
* `initialRegion`: `{lat,lng}` of `stopsWithCoords[3]` with `latitudeDelta = longitudeDelta = 0.05`, or `MAP_INITIAL_REGION`.
* `onMapReady` only flips `isMapReady`; both camera effects are gated on it.
* `fitToCoordinates` with `edgePadding {top:100,right:60,bottom:60,left:60}`, `animated:false`.
* `animateToRegion` always uses `latitudeDelta = longitudeDelta = 0.01`; duration **400 ms** from a marker press, **500 ms** from the `focusStopId` effect.
* Markers are plain dot `View`s (no custom image), `tracksViewChanges={false}`, anchor centre.
* Polyline: `strokeWidth: 5`, `strokeColor` = route colour.

## 1.7 Literal strings (verbatim)

`'Map'`, `' stops on route'`, `'Satellite'`, `'Street'`, `'Get Direction'`, `'View on Map'`, `'✕'`, `'Every '`, `' · '`, `' stops'`, `'  '`, `' '`, `'/^every\s*/i'` (regex source), `'#F00'`, `'#fff'`, `'#111'`, `'#FFF'`, `'#FFFFFF40'`, `'rgba(255,255,255,0.8)'`, `'https://www.google.com/maps/dir/?api=1&destination='`, `'&travelmode=transit'`, `','`, `'geo:'`, `'?q='`, `'('`, `')'`.

## 1.8 Navigation

None (MapScreen only calls `navigation.goBack()`).

## 1.9 Interactions

| interaction | effect |
|---|---|
| tap map-type button | toggles `mapType` between `standard` and `satellite`; label flips |
| tap marker | recentre (400 ms) → `setSelected` → `setSheetVisible(true)` → spring `slideAnim` 0→1 (tension 60, friction 10) |
| tap "Get Direction" | `Linking.openURL` Google Maps directions URL, `travelmode=transit` |
| tap "View on Map" | `Linking.openURL` `geo:` URI with the stop's coordinates |
| tap "✕" | `Animated.timing(slideAnim, {toValue:0,duration:250})` then hide + clear selection |
| open via params with `focusStopId` | after the map is ready, 400 ms later the camera animates and the sheet opens on that stop |
| back arrow | `navigation.goBack()` |

## 1.10 States

* **No `routeId` / unknown route**: no markers, no polyline, header shows `'Map'` on `colors.primary`, no summary card, no sheet. Map still panned/zoomed freely with the default Lahore region.
* **Route with a single coordinate**: no polyline and no `fitToCoordinates`; summary card still rendered (condition is `stops.length > 0`).
* **Empty departures** (`nowMin > operatingHours.end`, or no frequency): the chips row is omitted.
* No loading spinner and no error UI: `useRoutes()` already resolved `ROUTES` synchronously at first render.

---

# 2. SearchScreen — module 1071

## 2.1 Props / params

```js
SearchScreen({ navigation })     // route.params are NOT read
```

## 2.2 State and derived values

| variable | source |
|---|---|
| `colors` | `useTheme().colors` |
| `{ getRoutesByCategory }` | `useRoutes()` |
| `[query, setQuery]` | `useState('')` |
| `[category, setCategory]` | `useState('all')` |
| `results` | `useMemo(…, [query, category])` (see §2.3) |
| `accent` | `CATEGORIES_FOR_SEARCH.find(c => c.key === category)?.color ?? colors.primary` |

## 2.3 Search / filter algorithm (`searchInRoute`, `findMatchedStops`, `getFocusStop`)

All three are closures created **inside** the `useMemo`, so `q` is captured:

```js
const results = useMemo(() => {
  const q = query.toLowerCase();                      // NOTE: no trim

  const searchInRoute = (route) => {
    if (!q) return true
    if (route.name           && route.name.toLowerCase().includes(q))           return true
    if (route.stationAddress && route.stationAddress.toLowerCase().includes(q)) return true
    if (route.id             && route.id.toLowerCase().includes(q))             return true
    if (route.stops          && route.stops.some(s => s.toLowerCase().includes(q))) return true
    if (route.frequency     && route.frequency.toLowerCase().includes(q))       return true
    if (route.category      && route.category.toLowerCase().includes(q))        return true
    return false
  };

  const findMatchedStops = (route) =>            // [body inlined at its call site]
      q ? route.stops.filter(s => s.toLowerCase().includes(q)) : [];

  const list = category === 'all'
      ? getRoutesByCategory('all')
      : getRoutesByCategory(category);

  return list.filter(searchInRoute).map(route => ({
    ...route,
    _matchedStops: findMatchedStops(route)        // [] when q is empty
  }));
}, [query, category]);
```

```js
const getFocusStop = (route, query) =>           // [body inlined at its call site]
     (query && route._matchedStops && route._matchedStops.length)
        ? route._matchedStops[0] : null;
```

**Behavioural notes**

* Matching is **case-insensitive substring** on: route `name`, `stationAddress`, `id`, every entry of `stops`, `frequency`, `category`.
* An **empty query matches every route** (`searchInRoute` short-circuits to `true`), so the initial screen lists the whole category.
* Matching is done against `query.toLowerCase()` **without trimming** — a leading/trailing space becomes part of the needle.
* `_matchedStops` keeps **only stop names** (`stops.filter`), never `stopIds`/coords.
* `_matchedStops` order = route stop order; `getFocusStop` always returns the **first** matching stop.
* **Sort order: none.** Results keep the order of `getRoutesByCategory(category)`, i.e. `ROUTES` (GTFS `lines`) order, optionally filtered by `category`.
* **Debounce: none.** `useMemo` recomputes synchronously on every keystroke; there is no `setTimeout`, no lodash debounce, and `onChangeText` writes state directly (`r16 = setQuery`).
* Category filter and text filter are ANDed.

## 2.4 Exact UI structure

Root: `jsxs(SafeAreaView, { style:{ flex:1, backgroundColor: colors.background }, edges:['top'] }, [ header, list ])`

**Header** — `jsxs(View, { style:{ backgroundColor: accent, paddingHorizontal:16, paddingTop:8, paddingBottom:8 } }, [ row, input, chips ])`

```
<View style={{ backgroundColor: accent, paddingHorizontal:16, paddingTop:8, paddingBottom:8 }}>
  <View style={{ flexDirection:'row', alignItems:'center', marginBottom:16 }}>
    <Pressable android_ripple={{ color:'#FFFFFF50' }}
               onPress={() => navigation.goBack()}
               style={{ height:35, width:35, justifyContent:'center', alignItems:'center',
                        borderRadius:10, overflow:'hidden', marginRight:4 }}>
      <Image source={back} style={{ height:18, width:18, tintColor:'#fff' }} />
    </Pressable>
    <Text style={{ fontSize:22, fontWeight:'700', color:'#fff' }}>Search Routes</Text>
  </View>

  <TextInput value={query}
             onChangeText={setQuery}
             placeholder="Search by route name or stop name ..."
             placeholderTextColor="rgba(255,255,255,0.7)"
             autoFocus={true}
             style={{ backgroundColor:'rgba(255,255,255,0.2)', color:'#fff',
                      borderRadius:10, paddingHorizontal:16, paddingVertical:11,   // SPACING.sm + 3
                      fontSize:16, marginBottom:16 }} />

  <ScrollView horizontal={true} showsHorizontalScrollIndicator={false}
              contentContainerStyle={{ flexDirection:'row', gap:8, paddingHorizontal:0 }}
              keyboardShouldPersistTaps="handled">
    {CATEGORIES_FOR_SEARCH.map(cat => {
      const active = category === cat.key;
      return (
        <Pressable key={cat.key}
                   android_ripple={{ color:'#FFFFFF50' }}
                   onPress={() => setCategory(cat.key)}
                   style={{ paddingHorizontal:16, paddingVertical:8, borderRadius:10,
                            overflow:'hidden',
                            backgroundColor: active ? '#fff' : 'rgba(255,255,255,0.2)',
                            justifyContent:'center', alignItems:'center', flexDirection:'row' }}>
          <Image source={cat.icon} style={{ height:18, width:18,
                                            tintColor: active ? accent : '#fff', marginRight:4 }} />
          <Text style={{ fontSize:18, color: active ? accent : '#fff' }}>{cat.label}</Text>
        </Pressable>);
    })}
  </ScrollView>
</View>
```
Note: the chip `Image` size uses `FONT_SIZE.lg` (18) for both height and width, and the chip label also uses `FONT_SIZE.lg` (18).

**List** — `jsx(FlatList, {...})` with props (key order):
`data` (= `results`), `keyboardShouldPersistTaps: 'handled'`, `keyExtractor`, `contentContainerStyle: { paddingTop: 8, paddingBottom: 32 }`, `showsVerticalScrollIndicator: false`, `ListEmptyComponent`, `renderItem`.

* `keyExtractor(item, index)` → `item.id ?? String(index)`
* `ListEmptyComponent`:
  ```
  <View style={{ alignItems:'center', marginTop:32, flex:1 }}>
    <Image source={search} style={{ height:36, width:36, resizeMode:'contain',
                                    tintColor: colors.textSecondary }} />   // FONT_SIZE.xxxl
    <Text style={{ fontSize:16, color: colors.textSecondary, marginTop:8 }}>
      {query ? 'No routes found' : 'Start typing to search'}
    </Text>
  </View>
  ```
* `renderItem({ item })`:
  ```
  const categoryColor = CATEGORIES_FOR_SEARCH.find(c => c.key === item.category)?.color ?? '#1a73e8';
  const matched = item._matchedStops ?? [];
  const focusStop = getFocusStop(item, query);        // passed as focusStopId param

  <Pressable android_ripple={{ color: colors.text + '15' }}
             onPress={() => navigation.navigate('RouteDetail',
                 { routeId: item.id, color: categoryColor,
                   searchQuery: query, focusStopId: focusStop })}
             style={{ backgroundColor: colors.card, borderRadius:24, marginHorizontal:16,
                      marginBottom:8, flexDirection:'row', alignItems:'center',
                      overflow:'hidden', elevation:1, paddingVertical:16 }}>
    <View style={{ width:42, height:42, borderRadius:16,
                   backgroundColor: `${categoryColor}20`, borderWidth:1,
                   borderColor: `${categoryColor}30`, alignItems:'center',
                   justifyContent:'center', marginHorizontal:16 }}>
      <Image source={renderBusIcon(item.category)}
             style={{ height:30, width:30, resizeMode:'contain', tintColor: categoryColor }} />
    </View>
    <View style={{ flex:1, paddingRight:16 }}>
      <Text numberOfLines={1} style={{ fontSize:14, fontWeight:'700', color: colors.text }}>
        {item.stationAddress}
      </Text>
      <Text style={{ fontSize:12, color: colors.textSecondary, marginTop:3 }}>{item.name}</Text>
      {matched.length > 0 && (
        <View style={{ marginTop:4 }}>
          {matched.slice(0, 2).map((stop, i) =>
            <View key={i} style={{ flexDirection:'row', gap:2 }}>
              <Image source={location} style={{ height:10, width:10, tintColor: categoryColor }} />
              <Text numberOfLines={1} style={{ fontSize:10, color: categoryColor,
                                               fontStyle:'italic' }}>{stop}</Text>
            </View>)}
          {matched.length > 2 && (
            <Text style={{ fontSize:10, color: colors.textSecondary, fontStyle:'italic' }}>
              {['+', matched.length - 2, ' more stops']}
            </Text>)}
        </View>)}
      <View style={{ flexDirection:'row', marginTop:3, gap:8 }}>
        <Text style={{ fontSize:10, color: categoryColor,
                       backgroundColor: `${categoryColor}15`,
                       paddingHorizontal:6, paddingVertical:2, borderRadius:10 }}>
          {item.category}
        </Text>
        <Text style={{ fontSize:10, color: colors.textSecondary }}>{item.frequency}</Text>
      </View>
    </View>
    <Image source={arrow-right} style={{ height:25, width:25, resizeMode:'contain',
                                         tintColor: colors.text, marginRight:16,
                                         alignSelf:'center' }} />
  </Pressable>
  ```
  Style values: BORDER_RADIUS.xl = 24 (card), BORDER_RADIUS.lg = 16 (icon tile), BORDER_RADIUS.md = 10 (category pill), FONT_SIZE.md/sm/xs, SPACING.md/sm.

## 2.5 Literal strings (verbatim)

`'Search Routes'`, `'Search by route name or stop name ...'` (note the space before the ellipsis), `'No routes found'`, `'Start typing to search'`, `' more stops'`, `'+'`, `'All'`, `'Speedo'`, `'Metro'`, `'Orange Line'`, `'Electric'`, `'#fff'`, `'#FFFFFF50'`, `'rgba(255,255,255,0.2)'`, `'rgba(255,255,255,0.7)'`, `'#1a73e8'`, `'speedo'`, `'metro'`, `'orangeLine'`, `'electric'`, `'all'`, `'20'`, `'30'`, `'15'`, `'40'`, `'50'` (alpha suffixes), `''` (initial query).

## 2.6 Navigation calls

* `navigation.goBack()` — header back arrow.
* `navigation.navigate('RouteDetail', { routeId, color, searchQuery, focusStopId })` — tapping a result row.
  * `routeId` = `item.id`
  * `color` = the category colour (or `#1a73e8`)
  * `searchQuery` = the raw query string (untrimmed, original case)
  * `focusStopId` = first matching stop **name** (or `null`)

## 2.7 Interactions

| interaction | effect |
|---|---|
| typing in the `TextInput` | `setQuery` (no debounce) → `useMemo` recomputes filtered routes + `_matchedStops` |
| tapping a category chip | `setCategory(cat.key)` → results filtered to that category (`'all'` = all routes) |
| tapping a result | navigate to `RouteDetail` with the route, its colour, the query and the focus stop |
| tapping back | `navigation.goBack()` |
| keyboard | `autoFocus` on the input; `keyboardShouldPersistTaps="handled"` on the input's ScrollView and on the FlatList |

## 2.8 Empty / loading / error states

* **Empty query + empty result set**: impossible in practice unless `ROUTES` is empty — the empty component then shows the `search` icon + `'Start typing to search'`.
* **Query with no matches**: `search` icon + `'No routes found'` (both tinted `colors.textSecondary`).
* **Loading**: none in this screen. `useRoutes()` loads synchronously from the bundled `ROUTES` module; no `ActivityIndicator` exists here.
* **Error**: none rendered. `useRoutes().error` (`'Failed to load routes'`) is not consumed by SearchScreen.

---

# 3. JourneyResultsScreen — module 1075

## 3.1 Route params consumed

```js
const { fromKey, toKey, fromName, toName } = route.params;
```

`fromKey` / `toKey` are normalised stop keys (`name.trim().toLowerCase()`), `fromName` / `toName` are display names for the header.

## 3.2 Components

### `TransferRow({ leg, nextLeg, colors })`

```
if (leg.transferWalk) {
  <MaterialCommunityIcons name="walk" size={13} color={colors.textSecondary}
                          style={{ marginRight: 5 }} />
  <Text style={{ color: colors.textSecondary, fontSize: 10 }}>
    {['Transfer walk to ', leg.transferWalk.toName, ' · ', leg.transferWalk.minutes, ' min']}
  </Text>
} else {
  <MaterialCommunityIcons name="swap-horizontal" size={16} color={colors.textSecondary}
                          style={{ marginRight: 5 }} />
  <Text style={{ color: colors.textSecondary, fontSize: 14 }}>
    {['Change to', ' ', <Text style={{ fontWeight:'700', color: colors.text }}>{nextLeg.routeName}</Text>,
      ' at ', <Text style={{ fontWeight:'700', color: colors.text }}>{leg.toName}</Text>]}
  </Text>
}
```
Wrapper: `jsxs(View, { style:{ flexDirection:'row', alignItems:'center', marginBottom:4, marginLeft:2 } }, [ icon, text ])`.
(FONT_SIZE.md = 14 in the non-walk branch, FONT_SIZE.xs = 10 in the walk branch.)

### `JourneyResultsScreen({ navigation, route })`

* `colors = useTheme().colors`, `useStatusBarColor(colors.primary)`.
* `journeys = useMemo(() => findJourneys(fromKey, toKey), [fromKey, toKey])` — default limit 8 (see §5).
* `keyExtractor(item, index)` → `` `${index}-${item.legs.map(l => l.routeId).join('-')}` ``

## 3.3 Exact UI structure

Root: `jsxs(SafeAreaView, { style:{ flex:1, backgroundColor: colors.background }, edges:['top'] }, [ header, list ])`

**Header**
```
<View style={{ backgroundColor: colors.primary, paddingHorizontal:16, paddingTop:8,
               paddingBottom:16, flexDirection:'row', alignItems:'center' }}>
  <Pressable android_ripple={{ color:'#FFFFFF50' }}
             onPress={() => navigation.goBack()}
             style={{ height:35, width:35, justifyContent:'center', alignItems:'center',
                      borderRadius:10, overflow:'hidden', marginRight:4 }}>
    <Image source={back} style={{ height:18, width:18, tintColor:'#fff' }} />
  </Pressable>
  <View style={{ flex:1 }}>
    <Text numberOfLines={1} style={{ fontSize:18, color:'#fff' }}>{fromName}</Text>
    <View style={{ flexDirection:'row', alignItems:'center' }}>
      <Text numberOfLines={1} style={{ fontSize:12, color:'rgba(255,255,255,0.85)' }}>
        {[<FeatherIcon name="arrow-right" size={15} />, ' ', toName]}
      </Text>
    </View>
  </View>
  <View style={{ backgroundColor:'rgba(255,255,255,0.2)', paddingHorizontal:8,
                 paddingVertical:6, borderRadius:999 }}>
    <Text style={{ color:'#fff', fontWeight:'700', fontSize:12 }}>{[journeys.length, ' Options']}</Text>
  </View>
</View>
```

**FlatList** — props: `data` (=`journeys`), `keyExtractor`, `contentContainerStyle: { padding: 16, paddingBottom: 32 }`, `ListEmptyComponent`, `renderItem`.

`ListEmptyComponent`:
```
<View style={{ alignItems:'center', marginTop:32, paddingHorizontal:24 }}>
  <Image source={search} style={{ height:32, width:32, tintColor: colors.textSecondary }} />
  <Text style={{ color: colors.textSecondary, marginTop:8, textAlign:'center' }}>
    No bus route found between these stops, even with a walking transfer.
  </Text>
</View>
```

`renderItem({ item })`:
```
<Pressable android_ripple={{ color: colors.text + '15' }}
           onPress={() => navigation.navigate('JourneyDetail',
               { journey: item, fromName, toName })}
           style={{ backgroundColor: colors.card, borderRadius:16, padding:16,
                    marginBottom:16, elevation:0.5, overflow:'hidden' }}>
  <View style={{ flexDirection:'row', alignItems:'center', marginBottom:6 }}>
    <View style={{ backgroundColor: (item.transfers === 0 ? '#2E7D32' : colors.primary) + '18',
                   paddingHorizontal:8, paddingVertical:4, borderRadius:10, marginRight:8 }}>
      <Text style={{ color: item.transfers === 0 ? '#2E7D32' : colors.primary,
                     fontWeight:'800', fontSize:12 }}>
        {item.transfers === 0 ? 'Direct' : `${item.transfers} transfer${item.transfers > 1 ? 's' : ''}`}
      </Text>
    </View>
    <Text style={{ color: colors.textSecondary, fontSize:12 }}>{[item.totalStops, ' stops']}</Text>
    <Text style={{ color: colors.textSecondary, fontSize:12, marginLeft:'auto' }}>
      {['~', formatMinutes(item.estimatedMinutes)]}
    </Text>
  </View>

  <Text style={{ color: colors.text, fontSize:14, marginBottom:8 }}>
    {[(item.legs[0].waitMinutes > 0 ? `Leave in ${item.legs[0].waitMinutes} min · ` : ''),
      item.startClock,
      <FeatherIcon name="arrow-right" size={15} />,
      item.arrivalClock]}
  </Text>

  {item.legs.map((leg, i) => {
    const isLast = i < item.legs.length - 1;
    const hasWalk = isLast && !!leg.transferWalk;
    return (
      <View key={i}>
        <View style={{ flexDirection:'row', alignItems:'center', marginBottom:6 }}>
          <View style={{ flexDirection:'row', alignItems:'center',
                         backgroundColor: leg.color ?? colors.primary,
                         paddingHorizontal:8, paddingVertical:4, borderRadius:6,
                         marginRight:8 }}>
            <Image source={renderBusIcon(leg.category)}
                   style={{ height:13, width:13, tintColor:'#fff', marginRight:4 }} />
            <Text style={{ color:'#fff', fontWeight:'600', fontSize:10 }}>{leg.routeName}</Text>
          </View>
          <Image source={bus2} style={{ height:15, width:15, tintColor: leg.color,
                                        marginRight:6 }} />
          <Text numberOfLines={1} style={{ flex:1, color: colors.text, fontSize:12 }}>
            {[leg.fromName, ' ', <FeatherIcon name="arrow-right" size={15} />, ' ', leg.toName]}
          </Text>
        </View>
        {isLast && <TransferRow leg={leg} nextLeg={item.legs[i + 1]} colors={colors} />}
      </View>);
  })}
</Pressable>
```
Note: the `bus2` `Image` uses `tintColor: leg.color` (which may be `undefined` → no tint).

## 3.4 Literal strings (verbatim)

`' Options'`,`' stops'`,`'Direct'`,`' transfer'`,`'s'`,`'~'`,`'Leave in '`,`' min · '`,`'Change to'`,`' '`,`' at '`,`'Transfer walk to '`,`' · '`,`' min'`,`'No bus route found between these stops, even with a walking transfer.'`,`'#fff'`,`'rgba(255,255,255,0.2)'`,`'rgba(255,255,255,0.85)'`,`'#FFFFFF50'`,`'#2E7D32'`,`'18'`,`'15'`,`'20'`,`'30'`,`'-'`.

## 3.5 Icons / assets

Icons: Feather `arrow-right` (15) ×4 locations; MaterialCommunityIcons `swap-horizontal` (16), `walk` (13) in `TransferRow`.
Assets: `back` (18×18, `tintColor:'#fff'`), `search` (32×32), `bus2` (15×15), plus category icons via `renderBusIcon` (13×13, `tintColor:'#fff'`).

## 3.6 Navigation calls

* `navigation.goBack()` — header back.
* `navigation.navigate('JourneyDetail', { journey: item, fromName, toName })` — tapping a journey card.

## 3.7 Interactions & states

* Tapping a card → `JourneyDetail`.
* **Empty state**: when `findJourneys` returns `[]` (no single- or two-transfer route), the FlatList renders the empty component described above *and* the header still shows `0 Options`.
* **Loading**: none — `findJourneys` is synchronous (`useMemo`).
* **Error**: none — no try/catch, no error UI.

---

# 4. JourneyDetailScreen — module 1076

## 4.1 Route params consumed

```js
const { journey, fromName, toName } = route.params;
```
Derived: `const steps = journey.legs.length * 2 - 1;` (used in the "step(s)" counter).

## 4.2 Small components

### `Chip({ icon, text, colors })`
```
<View style={{ flexDirection:'row', alignItems:'center', backgroundColor: colors.background,
               borderWidth:1, borderColor: colors.border, paddingHorizontal:8,
               paddingVertical:6, borderRadius:999, marginRight:8, marginBottom:8 }}>
  <Image source={icon} style={{ height:16, width:16, tintColor: colors.textSecondary,
                                marginRight:5 }} />
  <Text style={{ color: colors.text, fontSize:12, fontWeight:'600' }}>{text}</Text>
</View>
```

### `StatBox({ icon, label, value, colors, last = false })`
```
<View style={{ flex:1, alignItems:'center', paddingVertical:8,
               borderRightWidth: last ? 0 : 1, borderRightColor: colors.border }}>
  <MaterialCommunityIcons name={icon} size={18} color={colors.primary}
                          style={{ marginBottom: 4 }} />
  <Text style={{ fontSize:10, fontWeight:'700', color: colors.textSecondary,
                 letterSpacing:0.4 }}>{label}</Text>
  <Text style={{ fontSize:18, fontWeight:'800', color: colors.text, marginTop:4 }}>{value}</Text>
</View>
```

### `OutlineButton({ icon, label, onPress, colors })`
```
<Pressable android_ripple={{ color: colors.primary + '20' }} onPress={onPress}
           style={{ flex:1, flexDirection:'row', alignItems:'center', justifyContent:'center',
                    borderWidth:1, borderColor: colors.primary, borderRadius:999,
                    paddingVertical:8, overflow:'hidden' }}>
  <FeatherIcon name={icon} size={17} color={colors.primary} style={{ marginRight:4 }} />
  <Text style={{ color: colors.primary, fontWeight:'700', fontSize:14 }}>{label}</Text>
</Pressable>
```

### `TransferStep({ leg, nextLeg, colors })`
```
const isWalk = !!leg.transferWalk;
<View style={{ flexDirection:'row', alignItems:'center', minHeight:26, marginBottom:8, marginLeft:5 }}>
  <Text style={{ color: colors.text, fontSize:14, flex:1 }}>
    <Text style={{ fontWeight:'800', fontSize:14 }}>
      {isWalk ? leg.transferWalk.toName : nextLeg.routeName}
    </Text>
    {isWalk ? ['Transfer walk to', ' ', <Text style={{fontWeight:'800',fontSize:14}}>{leg.transferWalk.toName}</Text>,
               ' · ', <Text style={{fontWeight:'800',fontSize:14}}>{leg.transferWalk.minutes}</Text>, ' min']
            : ['Change to', ' ', <Text style={{fontWeight:'800',fontSize:14}}>{nextLeg.routeName}</Text>,
               ' at ', <Text style={{fontWeight:'800',fontSize:14}}>{leg.toName}</Text>]}
  </Text>
</View>
```
(Rendered inside a `Fragment`; the bold segment is the highlighted name.)

### `RailIcon({ icon, color, colors, showLine = false })`
```
<View style={{ width:40, alignItems:'center' }}>
  <View style={{ width:40, height:40, borderRadius:50,   // radius = width/2 (circle)
                backgroundColor: `${color}15`, alignItems:'center',
                justifyContent:'center' }}>
    <MaterialCommunityIcons name={icon} size={25} color={color} />
  </View>
  {showLine && <View style={{ flex:1, width:2, backgroundColor: colors.border,
                              marginTop:2, marginBottom:2 }} />}
</View>
```
`backgroundColor` is always the template string `` `${color}15` `` (colour + 8-bit alpha hex `15`) — there is no fallback inside the component. `color` is supplied by the caller: `leg.color ?? colors.primary` for a ride leg, `colors.textSecondary` for a transfer step.

### `LegCard({ leg, colors, navigation })`
Local state `const [expanded, setExpanded] = useState(false)`; `legColor = leg.color ?? colors.primary`.
```
<View style={{ backgroundColor: colors.card, borderRadius:16, marginBottom:8,
              overflow:'hidden', marginLeft:5, elevation:0.5 }}>
  <Pressable android_ripple={{ color:'#FFFFFF40' }}
             onPress={() => navigation.navigate('RouteDetail',
                 { routeId: leg.routeId, color: legColor })}
             style={{ backgroundColor: legColor, paddingHorizontal:16, paddingVertical:16,
                      flexDirection:'row', alignItems:'center' }}>
    <Image source={renderBusIcon(leg.category)}
           style={{ height:26, width:26, tintColor:'#fff', marginRight:8 }} />
    <View style={{ flex:1 }}>
      <Text style={{ color: colors.white, fontWeight:'800', fontSize:18 }}>
        {['Take ', leg.routeName]}
      </Text>
      <Text style={{ color:'rgba(255,255,255,0.85)', fontSize:14, marginTop:2 }}>
        Tap for full route details
      </Text>
    </View>
    <Text style={{ color: colors.white, fontSize:18 }}>›</Text>
  </Pressable>

  <View style={{ padding:16 }}>
    <View style={{ flexDirection:'row', alignItems:'center', marginBottom:8 }}>
      <Text style={{ color: colors.text, fontWeight:'800', fontSize:16 }}>{leg.departureClock}</Text>
      <Text style={{ color: colors.textSecondary, marginHorizontal:8 }}>
        <FeatherIcon name="arrow-right" size={18} />
      </Text>
      <Text style={{ color: colors.text, fontWeight:'800', fontSize:16 }}>{leg.arrivalClock}</Text>
    </View>
    <Text numberOfLines={2} style={{ color: colors.text, fontWeight:'700', marginBottom:8 }}>
      {[leg.fromName, ' ', <Text style={{ color: colors.textSecondary, marginHorizontal:8 }}>
                               <FeatherIcon name="arrow-right" size={18} /></Text>, ' ', leg.toName]}
    </Text>
    <View style={{ flexDirection:'row', flexWrap:'wrap' }}>
      <Chip icon={route}      text={`Rs. ${leg.fare}`}   colors={colors} />
      <Chip icon={loop}       text={leg.frequency}       colors={colors} />
    </View>
    <Pressable android_ripple={{ color:'#FFFFFF50' }}
               onPress={() => navigation.navigate('Map',
                   { routeId: leg.routeId, color: legColor, reversed: leg.reversed })}
               style={{ flexDirection:'row', alignItems:'center', justifyContent:'center',
                        backgroundColor: legColor, borderRadius:10, paddingVertical:8,
                        marginTop:4, marginBottom:8, overflow:'hidden' }}>
      <Image source={location-map} style={{ height:22, width:22, tintColor:'#fff',
                                            marginRight:4 }} />
      <Text style={{ color:'#fff', fontWeight:'700', fontSize:14 }}>View on Map</Text>
    </Pressable>
    <Pressable android_ripple={{ color: colors.text + '15' }}
               onPress={() => setExpanded(e => !e)}
               style={{ flexDirection:'row', alignItems:'center', paddingVertical:8,
                        justifyContent:'center' }}>
      <EntypoIcon name={expanded ? 'chevron-small-up' : 'chevron-small-down'}
                  size={20} color={legColor} />
      <Text style={{ color: legColor, fontWeight:'700', fontSize:14 }}>
        {[leg.stopsTravelled, ' stops']}
      </Text>
    </Pressable>
    {expanded && (
      <View style={{ marginTop:8 }}>
        {leg.stopNames.map((name, i) =>
          <View key={i} style={{ flexDirection:'row', alignItems:'center', paddingVertical:4 }}>
            <View style={{ width:6, height:6, borderRadius:3,
                           backgroundColor: legColor, marginRight:8 }} />
            <Text style={{ color: colors.text, fontSize:14 }}>{name}</Text>
          </View>)}
      </View>)}
  </View>
</View>
```
`LegCard`'s inner padded `View` therefore has **six** children, in order: departure→arrival row, `fromName → toName`, chips row (`Rs. fare`, `frequency`), the "View on Map" bar, the expand toggle, the (optional) stop list.

**Navigation from `LegCard`:**
* header press → `navigation.navigate('RouteDetail', { routeId: leg.routeId, color: legColor })`
* "View on Map" press → `navigation.navigate('Map', { routeId: leg.routeId, color: legColor, reversed: leg.reversed })`

### `shareRoute()` (closure of `JourneyDetailScreen`)
```
const lines = journey.legs.map(l =>
  `${l.routeName}: ${l.fromName} → ${l.toName} (${l.departureClock} → ${l.arrivalClock})`);
Share.share({
  message:
    fromName + ' → ' + toName + '\n' +
    journey.startClock + ' → ' + journey.arrivalClock + ' · ~' +
    formatMinutes(journey.estimatedMinutes) + '\n\n' +
    lines.join('\n')
});
```
(`Share` from `react-native`; the arrow character is the literal `' → '`.)

## 4.3 Exact UI structure of `JourneyDetailScreen`

Root: `jsxs(SafeAreaView, { style:{ flex:1, backgroundColor: colors.background }, edges:['top'] }, [ header, scroll ])`

**4.3.1 Header**
```
<View style={{ backgroundColor: colors.primary, paddingHorizontal:16, paddingTop:8,
               paddingBottom:16, flexDirection:'row', alignItems:'center' }}>
  <Pressable android_ripple={{ color:'#FFFFFF50' }}
             onPress={() => navigation.goBack()}
             style={{ height:35, width:35, justifyContent:'center', alignItems:'center',
                      borderRadius:10, overflow:'hidden', marginRight:4 }}>
    <Image source={back} style={{ height:18, width:18, tintColor:'#fff' }} />
  </Pressable>
  <Text style={{ fontSize:22, fontWeight:'700', color:'#fff', flex:1 }}>Journey</Text>
  <View style={{ backgroundColor:'rgba(255,255,255,0.2)', paddingHorizontal:8,
                 paddingVertical:6, borderRadius:999 }}>
    <Text style={{ color:'#fff', fontWeight:'700', fontSize:12 }}>
      {journey.transfers === 0
        ? 'Direct'
        : `${journey.transfers} transfer${journey.transfers > 1 ? 's' : ''}`}
    </Text>
  </View>
</View>
```

**4.3.2 ScrollView** — `jsxs(ScrollView, { contentContainerStyle:{ padding:16, paddingBottom:32 }, showsVerticalScrollIndicator:false }, [ … ])`

**4.3.3 FROM / TO card** (`marginBottom:16`, `elevation:1`)
```
<View style={{ backgroundColor: colors.card, borderRadius:16, padding:16,
               marginBottom:16, elevation:1 }}>
  <View style={{ flexDirection:'row', alignItems:'center', paddingVertical:4 }}>
    <View style={{ width:10, height:10, borderRadius:5, backgroundColor:'#2E7D32',
                   marginRight:16 }} />
    <View>
      <Text style={{ fontSize:10, fontWeight:'700', color: colors.textSecondary,
                     letterSpacing:0.5 }}>FROM</Text>
      <Text style={{ fontSize:16, fontWeight:'700', color: colors.text, marginTop:2 }}>{fromName}</Text>
    </View>
  </View>
  <View style={{ height:1, backgroundColor: colors.border, marginVertical:8, marginLeft:18 }} />
  <View style={{ flexDirection:'row', alignItems:'center', paddingVertical:4 }}>
    <View style={{ width:10, height:10, borderRadius:3, backgroundColor:'#C62828',
                   marginRight:16 }} />
    <View>
      <Text style={{ fontSize:10, fontWeight:'700', color: colors.textSecondary,
                     letterSpacing:0.5 }}>TO</Text>
      <Text style={{ fontSize:16, fontWeight:'700', color: colors.text, marginTop:2 }}>{toName}</Text>
    </View>
  </View>
</View>
```

**4.3.4 Schedule card** (`marginBottom:16`, `elevation:1`)
```
<View style={{ backgroundColor: colors.card, borderRadius:16, padding:16, marginBottom:16,
               flexDirection:'row', alignItems:'center', elevation:1 }}>
  <FeatherIcon name="clock" size={20} color={colors.primary} style={{ marginRight:8 }} />
  <Text style={{ fontSize:18, fontWeight:'600', color: colors.text, flex:1 }}>
    {[journey.startClock, ' ', <FeatherIcon name="arrow-right" size={20} />, '  ', journey.arrivalClock]}
  </Text>
  <View style={{ backgroundColor: colors.primary + '15', paddingHorizontal:8,
                 paddingVertical:4, borderRadius:999 }}>
    <Text style={{ color: colors.primary, fontWeight:'700', fontSize:10 }}>Scheduled</Text>
  </View>
</View>
```

**4.3.5 Stats card** (`marginBottom:16`, `elevation:1`, no padding — the three StatBoxes supply their own `paddingVertical:8`)
```
<View style={{ backgroundColor: colors.card, borderRadius:16, marginBottom:16,
               flexDirection:'row', elevation:1 }}>
  <StatBox icon="clock-outline"     label="DURATION" value={formatMinutes(journey.estimatedMinutes)} colors={colors} />
  <StatBox icon="cash"              label="FARE"     value={`Rs. ${journey.totalFare}`}          colors={colors} />
  <StatBox icon="swap-horizontal-bold" label="CHANGES" value={String(journey.transfers)}        colors={colors} last />
</View>
```

**4.3.6 Action buttons row**
```
<View style={{ flexDirection:'row', marginBottom:24, gap:8 }}>
  <OutlineButton icon="map"
                 label="View on Map"
                 colors={colors}
                 onPress={() => navigation.navigate('Map', {
                   routeId: journey.legs[0].routeId,
                   color:   journey.legs[0].color,
                   reversed: journey.legs[0].reversed })} />
  <OutlineButton icon="share"
                 label="Share Route"
                 colors={colors}
                 onPress={shareRoute} />
</View>
```

**4.3.7 Step-by-step heading and subtitle**
```
<Text style={{ fontSize:22, fontWeight:'800', color: colors.text }}>Step-by-step directions</Text>
<Text style={{ fontSize:12, color: colors.textSecondary, marginBottom:16 }}>
  {[steps, ' step', steps > 1 ? 's' : '', ' · ', journey.totalStops, ' stops']}
</Text>
```

**4.3.8 Step list** — `journey.legs.map((leg, i) => …)`, key = `i`
```
const isLast = i < journey.legs.length - 1;
const showTransfer = isLast && !!leg.transferWalk;
<View key={i}>
  <View style={{ flexDirection:'row' }}>
    <RailIcon icon="bus" color={leg.color ?? colors.primary} colors={colors}
              showLine={showTransfer} />
    <View style={{ flex:1 }}>
      <LegCard leg={leg} colors={colors} navigation={navigation} />
    </View>
  </View>
  {showTransfer && (
    <View style={{ flexDirection:'row', alignItems:'center' }}>
      <RailIcon icon="walk" color={colors.textSecondary} colors={colors} showLine={true} />
      <View style={{ flex:1 }}>
        <TransferStep leg={leg} nextLeg={journey.legs[i + 1]} colors={colors} />
      </View>
    </View>)}
</View>
```
(The transfer `RailIcon` uses `'walk'` when `showTransfer` is true; `'swap-horizontal'` is the else-branch value and never appears in this list.)

**4.3.9 Estimated-time card** (`marginTop:16`, `marginBottom:16`, `elevation:0.5`)
```
<View style={{ backgroundColor: colors.card, borderRadius:16, padding:8, marginTop:16,
               marginBottom:16, flexDirection:'row', alignItems:'center', elevation:0.5 }}>
  <Image source={clock-filled} style={{ height:20, width:20, tintColor: colors.primary,
                                        marginRight:8 }} />
  <View style={{ flex:1 }}>
    <Text style={{ fontSize:12, fontWeight:'700', color: colors.textSecondary }}>Estimated Time</Text>
    <Text style={{ fontSize:22, fontWeight:'800', color: colors.text }}>
      {formatMinutes(journey.estimatedMinutes)}
    </Text>
  </View>
  <Text style={{ color: colors.textSecondary, fontStyle:'italic', fontSize:14 }}>estimate only</Text>
</View>
```

**4.3.10 Travel-tips card** (`backgroundColor: colors.primary + '10'`, no margin)
```
const TIPS = [
  'Times are estimates — allow extra time for connections',
  'Bus times may vary due to traffic conditions',
  'Fares shown are per leg — confirm with the conductor'
];
<View style={{ backgroundColor: colors.primary + '10', borderRadius:16, padding:16 }}>
  <View style={{ flexDirection:'row', alignItems:'center', marginBottom:8 }}>
    <Text style={{ fontSize:16 }}>💡</Text>
    <Text style={{ fontSize:16, fontWeight:'800', color: colors.text, marginLeft:4 }}>Travel Tips</Text>
  </View>
  {TIPS.map((tip, i) =>
    <Text key={i} style={{ color: colors.textSecondary, fontSize:12, marginBottom:4 }}>
      {'• ' + tip}
    </Text>)}
</View>
```
(The bullet is the literal `'• '` prefix concatenated with the tip string.)

## 4.4 Literal strings (verbatim)

`'Journey'`, `'Direct'`, `' transfer'`, `'s'`, `'FROM'`, `'TO'`, `'Scheduled'`, `'DURATION'`, `'FARE'`, `'CHANGES'`, `'View on Map'`, `'Share Route'`, `'Step-by-step directions'`, `' step'`, `' · '`, `' stops'`, `'Estimated Time'`, `'estimate only'`, `'Travel Tips'`, `'💡'`, `'• '`,
`'Times are estimates — allow extra time for connections'`,
`'Bus times may vary due to traffic conditions'`,
`'Fares shown are per leg — confirm with the conductor'`,
`'Take '`, `'Tap for full route details'`, `'›'`, `'Rs. '`,
`'Change to'`, `' '`, `' at '`, `'Transfer walk to'`, `' min'`,
`' → '`, `' ( '`(`' ('`), `')'`, `': '`, `'\n'`, `'\n\n'`, `'~'`,
`'#FFFFFF40'`, `'#FFFFFF50'`, `'rgba(255,255,255,0.2)'`, `'rgba(255,255,255,0.85)'`, `'#fff'`, `'#2E7D32'`, `'#C62828'`,
`'10'`, `'15'`, `'18'`, `'20'`, `'30'`, `'50'` (alpha suffixes).

## 4.5 Navigation calls

* `navigation.goBack()` — header back.
* `navigation.navigate('RouteDetail', { routeId: leg.routeId, color: legColor })` — `LegCard` header press.
* `navigation.navigate('Map', { routeId, color, reversed })` — "View on Map" `OutlineButton` (uses `journey.legs[0]`).

## 4.6 Interactions & states

* Tap a `LegCard` header → open that leg's route detail.
* Tap the chevron row → expand/collapse the intermediate stop list (`leg.stopNames`).
* Tap "View on Map" → open the Map screen for the **first leg's** route.
* Tap "Share Route" → native share sheet with the plain-text summary.
* No loading/error UI: `journey` comes from navigation params and is assumed complete. If `journey.legs` is empty the header still renders (`steps = -1`), the step list renders nothing, and `LegCard`/`journey.legs[0]` accesses in the action row would throw — the shipped code does not guard against this.

---

# 5. Journey planning engine — module 734

Consumed by `JourneyResultsScreen` (`findJourneys`) and, for formatting, by both journey screens (`formatMinutes`).

## 5.1 Stop index — `norm`, `ALL_STOPS`, `searchStops`, `getStopByKey`

```js
norm(s) { return (s ?? '').trim().toLowerCase(); }        // [inlined body] (String() then trim then toLowerCase)
const STOP_MAP = new Map();
ROUTES.forEach(route => route.stops.forEach((stopName, idx) => {
  const key = norm(stopName);
  if (!key) return;
  if (!STOP_MAP.has(key))
    STOP_MAP.set(key, {
      key,
      name: stopName,
      latitude:  route.coords[idx] == null ? undefined : route.coords[idx].latitude,
      longitude: route.coords[idx] == null ? undefined : route.coords[idx].longitude,
      routes: []
    });
  STOP_MAP.get(key).routes.push({ routeId: route.id, index: idx });
}));
ALL_STOPS = Array.from(STOP_MAP.values()).sort((a, b) => a.name.localeCompare(b.name));
```
* Stops are keyed by **trimmed, lower-cased name** (not by GTFS id).
* `routes` may contain the same `routeId` twice if a route visits the stop twice.
* `ALL_STOPS` is sorted by display name via `localeCompare`.

```js
searchStops(q) {
  if (!q || !q.trim()) return ALL_STOPS;
  const qn = norm(q);
  return ALL_STOPS.filter(s => s.key.includes(qn));
}
getStopByKey(key) { return ALL_STOPS.find(s => s.key === key); }   // may be undefined
routeById(id)      { return ROUTES.find(r => r.id === id); }        // [inlined body]
```

## 5.2 Geometry — `haversine`, `walkMinutesFor`, walk-neighbour graph

```js
const EARTH_RADIUS = 6371000;      // metres (bundle uses the literal 12742000 = 2*R)
haversine(lat1, lng1, lat2, lng2) {   // [inlined body]
  const φ1 = lat1 * Math.PI / 180, φ2 = lat2 * Math.PI / 180;
  const Δφ = (lat2 - lat1) * Math.PI / 180, Δλ = (lng2 - lng1) * Math.PI / 180;
  const a = Math.sin(Δφ/2) ** 2 + Math.cos(φ1) * Math.cos(φ2) * Math.sin(Δλ/2) ** 2;
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return EARTH_RADIUS * c;
}
walkMinutesFor(meters) { return Math.max(1, Math.round(meters / 80)); }   // [inlined body]
```
* **Walk speed = 80 metres/minute = 4.8 km/h**, minimum 1 minute.
* **MAX_WALK_METERS = 600** — neighbours farther than 600 m are discarded.

Walk-neighbour graph (built once at module load over every stop that has both `latitude != null` and `longitude != null`):

```
for each stop A in ALL_STOPS.filter(hasCoords):
  near = []
  for each stop B in ALL_STOPS.filter(hasCoords) where B.key !== A.key:
     d = haversine(A.latitude, A.longitude, B.latitude, B.longitude)
     if (d <= 600) near.push({ key: B.key, name: B.name, distanceMeters: d })
  near.sort((x, y) => x.distanceMeters - y.distanceMeters)
  WALK_NEIGHBORS.set(A.key, near)
```

## 5.3 Time helpers

```js
waitMinutesFrom(frequency, operatingHours, nowMinutes) {   // [inlined body]
  freq  = parseFrequencyMinutes(frequency)
  hours = parseOperatingHours(operatingHours)             // {start, end}
  if (nowMinutes > hours.end) return 0
  let t = nowMinutes < hours.start
        ? hours.start
        : hours.start + Math.ceil((nowMinutes - hours.start) / freq) * freq
  return Math.max(0, t - nowMinutes)
}
addMinutes(date, minutes) { return new Date(date.getTime() + minutes * 60000); }   // [inlined body]
minutesOfDay(date)       { return date.getHours() * 60 + date.getMinutes(); }       // [inlined body]
estimateTravelMinutes(stopsTravelled) { return Math.max(1, Math.round(stopsTravelled * 2)); }  // [inlined body]
```
* **Ride time = 2 minutes per stop travelled**, minimum 1 minute.

## 5.4 `buildLeg(route, aIdx, bIdx)` (recovered verbatim)

```js
buildLeg(route, aIdx, bIdx) {
  const reversed = aIdx > bIdx;
  const lo = Math.min(aIdx, bIdx), hi = Math.max(aIdx, bIdx);
  const stopsTravelled = hi - lo;
  const stopNames = route.stops.slice(lo, hi + 1);
  if (reversed) stopNames.reverse();                 // [...stopNames].reverse()
  return {
    routeId:        route.id,
    routeName:      route.name,
    category:       route.category,
    color:          route.color,
    fare:           route.fare,
    frequency:      route.frequency,
    operatingHours: route.operatingHours,
    fromName:       route.stops[aIdx],
    toName:         route.stops[bIdx],
    reversed,
    stopsTravelled,
    stopNames,
    travelMinutes:  estimateTravelMinutes(stopsTravelled)
  };
}
```
`fromName`/`toName` are the raw array entries at `aIdx`/`bIdx` (i.e. when `reversed`, `fromName` is the later stop).

## 5.5 `findBestTransfer(routeA, aIdx, routeB, bIdx, usedKeys)` (body inlined at 3 call sites)

```js
findBestTransfer(routeA, aIdx, routeB, bIdx, usedKeys) {
  // bMap: normalised stop name -> index, for routeB
  const bMap = new Map(routeB.stops.map((s, i) => [norm(s), i]));
  let best = null;

  routeA.stops.forEach((aName, iA) => {
    const s = norm(aName);
    if (usedKeys.has(s)) return;                       // origin/destination/previous-transfer stops excluded

    // (a) board B at the *same* stop
    if (bMap.has(s)) {
      const jB = bMap.get(s);
      const cost = Math.abs(iA - aIdx) + Math.abs(jB - bIdx);
      if (!best || cost < best.cost)
        best = { aIdx: iA, bIdx: jB, aName, bName: routeB.stops[jB],
                 walkMeters: 0, cost };
    }

    // (b) walk from a nearby stop of A to a nearby stop of B
    (WALK_NEIGHBORS.get(s) ?? []).forEach(n => {
      if (usedKeys.has(n.key)) return;
      if (bMap.has(n.key)) return;                     // the walk must land on a stop of B
      const jB = bMap.get(n.key);
      const walkMin = walkMinutesFor(n.distanceMeters);          // max(1, round(m/80))
      const cost = Math.abs(iA - aIdx) + Math.abs(jB - bIdx) + walkMin * 3;
      if (!best || cost < best.cost)
        best = { aIdx: iA, bIdx: jB, aName, bName: n.name,
                 walkMeters: n.distanceMeters, cost };
    });
  });
  return best;                                          // null when nothing usable
}
```
**Cost function**: `|iA − aIdx| + |jB − bIdx| + 3 × walkMinutes` — i.e. index distance on the boarding route + index distance on the alighting route + a **transfer penalty of 3 cost units per walking minute**. Walks only connect stops that are ≤ 600 m apart, and the walk target must be a stop of route B (case (b) is skipped when `bMap.has(n.key)`).

## 5.6 `legsSignature(legs)` (body inlined at its call site)

```js
legsSignature(legs) {
  return legs.map(l => `${l.routeId}:${l.fromName} → ${l.toName}`).join('|');
}
```

## 5.7 `findJourneys(fromKey, toKey, limit = 8)` — full algorithm

```js
findJourneys(fromKey, toKey, limit = 8) {
  if (!fromKey || !toKey || fromKey === toKey) return [];
  const from = getStopByKey(fromKey);          // ALL_STOPS.find(s => s.key === fromKey)
  const to   = getStopByKey(toKey);
  if (!from || !to) return [];

  const used = new Set([from.key, to.key]);
  const results = [];

  // ---- 1. DIRECT journeys (0 transfers) --------------------------------
  from.routes.forEach(({ routeId, index: iFrom }) => {
    to.routes.forEach(({ routeId: rid2, index: iTo }) => {
      if (rid2 !== routeId) return;
      const route = routeById(routeId);
      if (!route) return;
      results.push({ transfers: 0, legs: [ buildLeg(route, iFrom, iTo) ] });
    });
  });

  // ---- 2. ONE transfer, only if no direct journey was found -----------
  if (results.length === 0) {
    from.routes.forEach(({ routeId, index: iFrom }) => {
      const routeA = routeById(routeId); if (!routeA) return;
      to.routes.forEach(({ routeId: rid2, index: iTo }) => {
        if (rid2 === routeId) return;
        const routeB = routeById(rid2); if (!routeB) return;
        const best = findBestTransfer(routeA, iFrom, routeB, iTo, used);
        if (!best) return;
        const leg1 = buildLeg(routeA, iFrom, best.aIdx);
        const leg2 = buildLeg(routeB, best.bIdx, iTo);
        if (leg1.stopsTravelled <= 0 || leg2.stopsTravelled <= 0) return;
        if (best.walkMeters > 0)
          leg1.transferWalk = {
            distanceMeters: best.walkMeters,
            minutes: walkMinutesFor(best.walkMeters),
            toName: best.bName
          };
        results.push({ transfers: 1, legs: [leg1, leg2] });
      });
    });
  }

  // ---- 3. TWO transfers, only if still empty ---------------------------
  if (results.length === 0) {
    from.routes.forEach(({ routeId, index: iFrom }) => {
      const routeA = routeById(routeId); if (!routeA) return;
      to.routes.forEach(({ routeId: rid2, index: iTo }) => {
        const routeB = routeById(rid2); if (!routeB) return;
        ROUTES.forEach(routeC => {
          if (routeC.id === routeId || routeC.id === rid2) return;
          const bestAB = findBestTransfer(routeA, iFrom, routeC, 0, used);   // bIdx literal 0
          if (!bestAB) return;
          const used2 = new Set([...used, norm(bestAB.bName)]);
          const bestBC = findBestTransfer(routeC, bestAB.bIdx, routeB, iTo, used2);
          if (!bestBC) return;
          const leg1 = buildLeg(routeA, iFrom, bestAB.aIdx);
          const leg2 = buildLeg(routeC, bestAB.bIdx, bestBC.aIdx);
          const leg3 = buildLeg(routeB, bestBC.bIdx, iTo);
          if (leg1.stopsTravelled <= 0) return;
          if (leg2.stopsTravelled <= 0) return;
          if (leg3.stopsTravelled <= 0) return;
          if (bestAB.walkMeters > 0)
            leg1.transferWalk = { distanceMeters: bestAB.walkMeters,
                                  minutes: walkMinutesFor(bestAB.walkMeters),
                                  toName: bestAB.bName };
          if (bestBC.walkMeters > 0)
            leg2.transferWalk = { distanceMeters: bestBC.walkMeters,
                                  minutes: walkMinutesFor(bestBC.walkMeters),
                                  toName: bestBC.bName };
          results.push({ transfers: 2, legs: [leg1, leg2, leg3] });
        });
      });
    });
  }

  // ---- 4. de-duplicate, sort, cap --------------------------------------
  const seen = new Set();
  let journeys = results.filter(j => {
    const sig = legsSignature(j.legs);
    if (seen.has(sig)) return false;
    seen.add(sig);
    return true;
  });

  journeys.sort((a, b) => {
    if (a.transfers !== b.transfers) return a.transfers - b.transfers;
    const totalA = a.legs.reduce((s, l) => s + l.stopsTravelled, 0);
    const totalB = b.legs.reduce((s, l) => s + l.stopsTravelled, 0);
    return totalA - totalB;
  });

  return journeys.slice(0, limit).map(j => enrich(j));
}
```

### `enrich(journey)` (inlined in the final `.map`)

```js
enrich(j) {
  const start  = new Date();
  let   cursor = new Date(start.getTime());

  j.legs.forEach(leg => {
    const now   = cursor;
    const wait  = waitMinutesFrom(leg.frequency, leg.operatingHours,
                                  now.getHours() * 60 + now.getMinutes());
    const dep   = new Date(now.getTime()  + wait * 60000);
    const arr   = new Date(dep.getTime()  + leg.travelMinutes * 60000);
    leg.waitMinutes    = wait;
    leg.departureTime  = dep;
    leg.arrivalTime    = arr;
    leg.departureClock = formatClock(dep.getHours()*60 + dep.getMinutes());
    leg.arrivalClock  = formatClock(arr.getHours()*60 + arr.getMinutes());
    cursor = arr;
    if (leg.transferWalk)
      cursor = new Date(arr.getTime() + leg.transferWalk.minutes * 60000);
  });

  const totalWalkMinutes = j.legs.reduce((s, l) => s + (l.transferWalk ? l.transferWalk.minutes : 0), 0);
  const totalStops       = j.legs.reduce((s, l) => s + l.stopsTravelled, 0);
  const totalFare        = j.legs.reduce((s, l) => s + (parseInt(l.fare, 10) || 0), 0);
  const estimatedMinutes = Math.max(1, Math.round((cursor.getTime() - start.getTime()) / 60000));

  return {
    ...j,                                   // { transfers, legs[] }
    totalStops,
    totalFare,
    totalWalkMinutes,
    estimatedMinutes,
    startTime:  start,
    startClock: formatClock(start.getHours()*60 + start.getMinutes()),
    arrivalTime:  cursor,
    arrivalClock: formatClock(cursor.getHours()*60 + cursor.getMinutes())
  };
}
```
Result key order: `transfers, legs, totalStops, totalFare, totalWalkMinutes, estimatedMinutes, startTime, startClock, arrivalTime, arrivalClock`.

### Journey / leg object shapes (contract for the UI)

```
journey = {
  transfers: 0|1|2,
  legs: Leg[],                        // 1..3 legs
  totalStops: int,                    // Σ stopsTravelled
  totalFare: int,                     // Σ parseInt(fare,10)
  totalWalkMinutes: int,              // Σ transferWalk.minutes
  estimatedMinutes: int,              // wall-clock from first departure to final arrival (≥1)
  startClock: 'h:mm AM',              // formatClock of the first leg's departure
  arrivalClock: 'h:mm AM',            // formatClock of the final cursor
  startTime / arrivalTime: Date
}
leg = {
  routeId, routeName, category, color, fare (string), frequency, operatingHours,
  fromName, toName, reversed (bool),
  stopsTravelled (int),
  stopNames (string[]),
  travelMinutes (int),
  waitMinutes (int), departureTime (Date), arrivalTime (Date),
  departureClock ('h:mm AM'), arrivalClock ('h:mm AM'),
  transferWalk?: { distanceMeters (int), minutes (int), toName (string) }
}
```

## 5.8 Formatters

```js
formatMinutes(m) {
  if (m < 60) return `${m} min`;
  const h = Math.floor(m / 60), r = m % 60;
  return r > 0 ? `${h}h ${r}m` : `${h}h`;
}
formatWalkDistance(meters) {
  if (meters >= 1000) return `${(meters / 1000).toFixed(1)} km`;
  return `${Math.round(meters)} m`;
}
```
(1 decimal place for km, rounded metres otherwise.)

**Module 734's public exports are exactly:** `ALL_STOPS`, `findJourneys`, `formatMinutes`, `formatWalkDistance`, `getStopByKey`, `searchStops`.
Of these, the four screens under review consume **only `findJourneys` (1× in m1075) and `formatMinutes` (1× in m1075, 3× in m1076)**.
`formatWalkDistance` is defined but never imported by m1033/m1071/m1075/m1076 (`formatWalkTime`, `formatDistance` and the `norm`/`routeById`/`haversine`/`walkMinutesFor`/`waitMinutesFrom`/`addMinutes`/`minutesOfDay`/`estimateTravelMinutes`/`buildLeg`/`findBestTransfer`/`legsSignature` names are module-private or non-existent in the bundle; `shareRoute` is a closure of `JourneyDetailScreen`, `openDirections`/`openLocation`/`openSheet`/`handleMarkerPress`/`closeSheet` are closures of `MapScreen`, `findMatchedStops`/`getFocusStop`/`searchInRoute` are closures inside `SearchScreen`'s `useMemo`).

## 5.9 Constants summary (journey engine)

| constant | value |
|---|---|
| walk speed | 80 m/min (4.8 km/h) |
| max walk distance | 600 m |
| transfer penalty | 3 cost units per walking minute |
| ride time | 2 min per stop travelled (min 1) |
| cost term | `abs(iA-aIdx) + abs(jB-bIdx) + 3*walkMinutes` |
| max journeys returned | 8 (`limit` default) |
| earth radius (haversine) | 6 371 000 m |
| `MAP_INITIAL_REGION` | lat 31.5204, lng 74.3587, deltas 0.2 |
| departure refresh | every 30 000 ms (`useNextDepartures`) |
| stop sheet spring | tension 60, friction 10, `toValue 1` |
| sheet close timing | 250 ms (`toValue 0`) |
| marker camera animation | 400 ms; focus-stop animation 500 ms; delta 0.01 |
| `fitToCoordinates` edge padding | `{top:100,right:60,bottom:60,left:60}` |

---

# 6. Navigation summary (route names)

| From | Route name | Params |
|---|---|---|
| MapScreen back arrow | — | `navigation.goBack()` |
| SearchScreen back arrow | — | `navigation.goBack()` |
| SearchScreen result tap | `'RouteDetail'` | `{ routeId, color, searchQuery, focusStopId }` |
| JourneyResults back arrow | — | `navigation.goBack()` |
| JourneyResults card tap | `'JourneyDetail'` | `{ journey, fromName, toName }` |
| JourneyDetail back arrow | — | `navigation.goBack()` |
| JourneyDetail `LegCard` tap | `'RouteDetail'` | `{ routeId: leg.routeId, color: legColor }` |
| JourneyDetail "View on Map" | `'Map'` | `{ routeId: journey.legs[0].routeId, color: journey.legs[0].color, reversed: journey.legs[0].reversed }` |

External (non-navigator) links:

| Action | URL |
|---|---|
| MapScreen "Get Direction" | `https://www.google.com/maps/dir/?api=1&destination=<lat>,<lng>&travelmode=transit` |
| MapScreen "View on Map" | `geo:<lat>,<lng>?q=<lat>,<lng>()` (label = `encodeURIComponent('')`) |
| JourneyDetail "Share Route" | `Share.share({ message: <plain text> })` |

---

# 7. Cross-screen checklist

## 7.1 All literal user-visible strings (verbatim, one list)

```
'Map'                                     MapScreen header title fallback
' stops on route'                         MapScreen header subtitle (preceded by a number)
'Satellite' / 'Street'                    MapScreen map-type toggle label
'Get Direction'                           MapScreen sheet button
'View on Map'                             MapScreen sheet button (and JourneyDetail OutlineButton)
'✕'                                       MapScreen sheet close
'Every '                                  MapScreen summary card frequency prefix
' · '                                     separator (MapScreen card, JourneyDetail steps subtitle, TransferStep)
' stops'                                  suffix (MapScreen card, SearchScreen "N more stops", JourneyDetail subtitle)
'  ' / ' '                                spacing literals
'Search Routes'                           SearchScreen title
'Search by route name or stop name ...'   SearchScreen placeholder
'No routes found'                         SearchScreen empty state
'Start typing to search'                  SearchScreen empty state (no query)
'All' / 'Speedo' / 'Metro' / 'Orange Line' / 'Electric'   SearchScreen category chips
'+N more stops'                           SearchScreen matched-stop overflow ('+', N, ' more stops')
'Options'                                 JourneyResults header pill (preceded by a number)
'Direct'                                  JourneyResults + JourneyDetail (transfers === 0)
' transfer' / ' transfers'                JourneyResults/Detail chip ('1 transfer', '2 transfers')
'Leave in ' / ' min · '                   JourneyResults first-leg wait prefix
'Change to' / ' at '                      transfer rows
'Transfer walk to ' / ' min'              walking transfer rows
'No bus route found between these stops, even with a walking transfer.'  JourneyResults empty state
'Journey'                                 JourneyDetail title
'FROM' / 'TO'                             JourneyDetail origin/destination card
'Scheduled'                               JourneyDetail schedule card pill
'DURATION' / 'FARE' / 'CHANGES'           JourneyDetail StatBox labels
'Rs. '                                    fare prefix (LegCard chips and JourneyDetail FARE value)
'Take '                                   LegCard header
'Tap for full route details'              LegCard sub-header
'›'                                       LegCard chevron character
'Step-by-step directions'                 JourneyDetail heading
' step' / ' steps'                        JourneyDetail subtitle
'Estimated Time' / 'estimate only'        JourneyDetail estimated-time card
'Travel Tips'                             JourneyDetail tips card
'Times are estimates — allow extra time for connections'
'Bus times may vary due to traffic conditions'
'Fares shown are per leg — confirm with the conductor'
'• '                                      JourneyDetail tip bullet prefix
'Failed to load routes'                   useRoutes error string (not rendered by these screens)
'6:00 AM - 10:00 PM'                      parseOperatingHours default
'No more buses today'                     (StopDetailScreen, module 1072 — not in scope)
```

## 7.2 Icons (all screens, by set)

See §0.9. In short: **MaterialCommunityIcons** (`swap-horizontal` 16, `walk` 13, `clock-outline` 18, `cash` 18, `swap-horizontal-bold` 18, `bus` 25, `walk`/`swap-horizontal` 25), **Feather** (`arrow-right` 15/18/20, `clock` 20, `map` 17, `share` 17), **Entypo** (`chevron-small-down`/`chevron-small-up` 20).

## 7.3 Images (all screens)

`back`, `search`, `location`, `arrow-right`, `location-direction`, `location-map`, `bus2`, `route`, `loop`, `clock-filled`, plus category icons via `renderBusIcon` (`speedo`, `metro`, `orange-line`, `electric`, `filter`, `bus2`).

## 7.4 Empty / loading / error states

| Screen | empty | loading | error |
|---|---|---|---|
| MapScreen | no route → empty map + `'Map'` title; no departures → chips omitted | none (`ROUTES` is bundled) | none |
| SearchScreen | `search` icon + `'Start typing to search'` (no query) or `'No routes found'` (no match), inside the FlatList `ListEmptyComponent` | none | none (`useRoutes.error` not consumed) |
| JourneyResultsScreen | `search` icon 32×32 + `'No bus route found between these stops, even with a walking transfer.'`, header still shows `0 Options` | none (`findJourneys` is synchronous) | none |
| JourneyDetailScreen | n/a (params-driven); empty `legs` would break `journey.legs[0]` | none | none |

## 7.5 Functional notes for the reimplementation

* Everything is synchronous and bundled — no network layer, no spinners. Only the 30 s departure ticker and the 400/500 ms camera timeouts are asynchronous.
* `SearchScreen` is the only screen that reads no `route.params`; `MapScreen` reads `routeId`, `focusStopId`, `color`, `reversed`.
* Stop identity across the journey engine is the **normalised stop name** (`trim().toLowerCase()`), never the GTFS id.
* The two-transfer branch (5.7 §3) boards the *first* walk on route A, walks to route **C**, then transfers from **C** to route **B**, which alights at the destination; the returned `legs` array is ordered `[A, C, B]` and the first `findBestTransfer` call passes the literal `bIdx = 0`.
* `transferWalk` is always attached to the leg **before** the transfer (it describes the walk off that leg).
* MapScreen marker dot `borderRadius` is the literal `11` for both sizes (14 and 22).
* MapScreen `initialRegion` reads `stopsWithCoords[3]` when at least one coordinate exists, otherwise `MAP_INITIAL_REGION` (Lahore centre).
* The header `<Text>` colour on MapScreen is hard-coded `'#fff'`/`'rgba(255,255,255,0.8)'`, so it always assumes a coloured route bar.
