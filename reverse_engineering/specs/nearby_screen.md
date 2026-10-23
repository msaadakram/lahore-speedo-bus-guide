# NearbyScreen — Implementation-Ready Specification

Source: Hermes Metro register-machine decompilations in
`/home/ubuntu/bus/reverse_engineering/hermes/app_graph_src/`

| Hermes module | Contents |
|---|---|
| **m722.js** | `NearbyScreen` (default export), `RouteChipLabel`, `formatDistance`, `formatWalkTime`, `haversine`, `requestLocationPermission`, `openLocationSettings`, `openAppSettings` |
| **m734.js** | data/helper module: `ALL_STOPS`, `searchStops`, `getStopByKey`, `routeById` (internal), `findJourneys`, `formatMinutes`, `formatWalkDistance` |
| **m729.js** | `react-native-geolocation-service` wrapper (default export object) |
| **m723.js** | `react-native-vector-icons/MaterialIcons` font registration |
| **m725.js** | `react-native-vector-icons/Ionicons` font registration |
| **m727.js** | `react-native-vector-icons/Feather` font registration |

---

## 0. Resolved module graph for m722 (dependency → meaning)

`m722.js` header: `deps=[1, 32, 350, 69, 2, 558, 723, 725, 727, 729, 238, 571, 577, 700, 734, 578, 570, 736, 718, 715]`

The dep array is **0-based**. In the decompilation `_closure0_slotK` = `interop(require(deps[K]))`, and
theme/data imports are fetched inline as `depMap[N]` (verified semantically against the target module
sources, e.g. `depMap[11] → m571.useTheme`, `depMap[14] → m734.ALL_STOPS`, `depMap[16] → m570.SPACING`).

| Dep index | Module | Identity | How m722 uses it |
|---|---|---|---|
| 0 | 1 | `@babel/runtime/helpers/interopRequireWildcard` | interop helper |
| 1 | 32 | *(imported, never referenced — dead import)* | — |
| 2 | 350 | `@babel/runtime` async-generator helpers | `.default` = `_wrapAsyncGenerator`, wraps `requestLocationPermission` |
| 3 | 69 | **react** | `useState`, `useRef`, `useCallback`, `useEffect` |
| 4 | 2 | **react-native** | `View`, `Text`, `Image`, `Pressable`, `ActivityIndicator`, `FlatList`, `Fragment`, `Linking`, `AppState`, `PermissionsAndroid` |
| 5 | 558 | **react-native-vector-icons/MaterialCommunityIcons** | `reload`, `map-marker-off-outline` |
| 6 | 723 | **react-native-vector-icons/MaterialIcons** | `directions-walk` |
| 7 | 725 | **react-native-vector-icons/Ionicons** | `time-outline` |
| 8 | 727 | **react-native-vector-icons/Feather** | `chevron-right` |
| 9 | 729 | **react-native-geolocation-service** (wrapper) | `Geolocation.getCurrentPosition` |
| 10 | 238 | react JSX runtime (`jsx`, `jsxs`) | all element creation |
| 11 | 571 | theme context (`useTheme`) | `const {colors} = useTheme()` |
| 12 | 577 | `useStatusBarColor` hook | `useStatusBarColor(colors.primary)` |
| 13 | 700 | react-native-safe-area-context | `useSafeAreaInsets()` |
| 14 | 734 | data/helpers | `ALL_STOPS` |
| 15 | 578 | `@react-navigation/native` | `useFocusEffect` |
| 16 | 570 | theme constants | `SPACING`, `FONT_SIZE`, `BORDER_RADIUS` |
| 17 | 736 | image asset | `location.jpg` |
| 18 | 718 | routes data | `ROUTES` (used by `RouteChipLabel`) |
| 19 | 715 | bus-icon helper | `renderBusIcon(category)` |

Supporting modules read to recover literal values:

* **m570.js** (theme constants)
  * `SPACING = {xs: 4, sm: 8, md: 16, lg: 24, xl: 32, xxl: 48}`
  * `FONT_SIZE = {xs: 10, sm: 12, md: 14, base: 16, lg: 18, xl: 22, xxl: 28, xxxl: 36}`
  * `BORDER_RADIUS = {sm: 6, md: 10, lg: 16, xl: 24, full: 999}`
* **m576.js** (palette, exported as `COLORS` / `DARK_COLORS`)
  * `COLORS` (light): `primary #fc3b38`, `background #F5F7FA`, `card #FFFFFF`, `border #E0E0E0`, `text #212121`, `textSecondary #757575`, `white #FFFFFF`, `black #000000`, `overlay rgba(0,0,0,0.5)`
  * `DARK_COLORS`: `primary #fc3b38`, `background #121212`, `card #2C2C2C`, `border #333333`, `text #EEEEEE`, `textSecondary #AAAAAA`, `white #FFFFFF`, `black #000000`, `overlay rgba(0,0,0,0.7)`
* **m571.js** — `useTheme()` returns `{colors, isDark, toggleTheme, preference, setThemePreference}`; `colors` is `COLORS` when light and `DARK_COLORS` when dark. `useTheme()` is `useContext(ThemeContext)`, no default theme object (null context → `colors` would crash if used outside the provider, so it is always inside the app's `ThemeProvider`).
* **m577.js** — `useStatusBarColor(color, barStyle = 'light-content', animated = true)`; on focus it calls `StatusBar.setBarStyle(barStyle, animated)` and `StatusBar.setBackgroundColor(color, animated)`.
* **m736.js** — single image asset: `{__packager_asset: true, httpServerLocation: '/assets/src/assets/icons', width: 48, height: 48, scales: [1], hash: '365dc25f5123c266cf4d0e5759c98f8e', name: 'location', type: 'jpg'}`. On disk: `src/assets/icons/location.jpg`.
* **m715.js** — `renderBusIcon(category)` returns one of the registered image assets: `speedo → m709 (speedo.jpg)`, `metro → m711 (metro.jpg)`, `orangeLine → m713 (orange-line.jpg)`, `electric → m712 (electric.jpg)`, `all → m716 (filter.jpg)`, **unknown category → returns `undefined`** (fallthrough returns the dep-map entry for index 5, which is not an asset → renders as a broken/empty image).
* **m718.js** — `ROUTES` derived from the raw GTFS-ish data (m735/m719): each route object = `{id, name (shortName), stationAddress (longName), frequency, operatingHours (scheduleDisplay), category, fare (String(ticketCost ?? '25')), color, stops (names), stopIds, coords [{latitude, longitude, name, id}]}`. `category` = `'speedo'` if `shortName.startsWith('Speedo')`, else `'metro'` if starts with `'Metro'`, else `'electric'` if starts with `'Orange'`, else `'orangeLine'`.
* **m557.js** — the bottom-tab host that mounts this screen (`Screen name="Nearby" component={<NearbyScreen/>}`), `screenOptions = {headerShown: false, animation: 'shift'}`, so **no React Navigation header is shown on NearbyScreen**; it draws its own header.

---

## 1. Components and helper functions

### 1.1 `NearbyScreen(props)` — default export of m722.js

* **Props:** `{ navigation }` (React Navigation navigation object). Nothing else is read from props.
* **Hooks, in execution order:**
  1. `const {colors} = useTheme();` (m571)
  2. `useStatusBarColor(colors.primary)` (m577) — status bar background = primary red, bar style `light-content`.
  3. `const insets = useSafeAreaInsets();` (m700)
  4. `const [status, setStatus] = useState('idle');`
  5. `const [stops, setStops] = useState([]);`
  6. `const appStateRef = useRef(AppState.currentState);`
  7. `const requestAndFind = useCallback(<see 1.3>, []);`
  8. `useFocusEffect(useCallback(() => { if (status === 'idle') requestAndFind(); }, [status, requestAndFind]));`
  9. `useEffect(<AppState listener, see 1.4>, [status, requestAndFind]);`
* **Render:** `jsxs(View, {style: {flex: 1, backgroundColor: colors.background}, children: [...]})` with a **6-slot children array** (see §2).

### 1.2 `RouteChipLabel({routeId, colors})` — local component of m722

* **Props:** `routeId` (string), `colors` (theme palette object).
* **Behaviour:** `const route = ROUTES.find(r => r.id === routeId);` — **if not found, returns `null`** (renders nothing).
* **Output** (when found): a `Fragment` containing, in order:
  1. `jsx(Image, {source: renderBusIcon(route.category), style: {height: 15, width: 15, marginRight: 5, tintColor: route.color || colors.primary}})`
  2. `jsx(Text, {style: {color: route.color || colors.primary, fontWeight: '700', fontSize: FONT_SIZE.md (=14)}, children: route.name})`
* Note `route.color || colors.primary` — falsy/empty route colour falls back to the theme primary.

### 1.3 `requestAndFind` — `useCallback(..., [])` (stored in `_closure1_slot6`)

Exact behaviour:

```js
const requestAndFind = useCallback(() => {
  setStatus('loading');
  requestLocationPermission().then((granted) => {
    if (!granted) { setStatus('denied'); return; }          // falsy → denied screen
    Geolocation.getCurrentPosition(
      (position) => { /* §8 success handler */ },
      (error) => {
        const code = (error == null) ? undefined : error.code;
        setStatus(code === 2 ? 'locationOff' : 'error');
      },
      {enableHighAccuracy: true, timeout: 15000}
    );
  });
}, []);
```

* **`enableHighAccuracy: true`**, **`timeout: 15000`** (15 s) — the only options passed.
* Error mapping: `error.code === 2` → status `'locationOff'`; every other error (including `code === 1` permission denied, `code === 3` timeout, or a null/absent error object) → status `'error'`.

### 1.4 AppState effect

```js
useEffect(() => {
  const sub = AppState.addEventListener('change', (nextAppState) => {
    appStateRef.current = nextAppState;                    // ref updated unconditionally
    if (<app became active> && (status === 'locationOff' || status === 'denied')) requestAndFind();
  });
  return () => sub.remove();
}, [status, requestAndFind]);
```

Register-level detail (decompiled): the handler first computes `appStateRef.current.match(/inactive|background/)`,
then `nextAppState === 'active'`, stores `appStateRef.current = nextAppState`, and calls `requestAndFind()` only when
that condition holds **and** `status` is `'locationOff'` or `'denied'`. Net effect: returning to the foreground while the
screen sits in the permission-denied or location-off state silently retries the whole permission + fix flow.
There is **no** re-fetch when the app becomes active and `status === 'done'`.

### 1.5 `requestLocationPermission()` — generator wrapped by `_wrapAsyncGenerator`

```js
const requestLocationPermission = _wrapAsyncGenerator(function* () {
  return yield PermissionsAndroid.request(PermissionsAndroid.PERMISSIONS.ACCESS_FINE_LOCATION)
       === PermissionsAndroid.RESULTS.GRANTED;
});
```

* Requests exactly one Android permission: **`ACCESS_FINE_LOCATION`**.
* Returns `true` only for `PermissionsAndroid.RESULTS.GRANTED`; `DENIED` and `NEVER_ASK_AGAIN` both return `false`.
* No `try/catch` in the visible body (the wrapper's catch only rethrows), so a native throw becomes an unhandled promise rejection — the screen stays in `'loading'` forever in that case.
* iOS note: this path is Android-only; on iOS there is no permission call and the status bar/geolocation would fail into the `'error'` state.

### 1.6 `openLocationSettings()` — `_closure0_slot14`

```js
const openLocationSettings = () => { Linking.sendIntent('android.settings.LOCATION_SOURCE_SETTINGS'); };
```
Return value: `undefined` (the promise returned by `sendIntent` is discarded; no `.catch`).

### 1.7 `openAppSettings()` — `_closure0_slot15` (a.k.a. "openSettings")

```js
const openAppSettings = () => Linking.openSettings();
```
Return value: the `Linking.openSettings()` promise (also not awaited / not caught).

### 1.8 `formatDistance(metres)` — `_closure0_slot16`

```js
const formatDistance = (m) => (m >= 1000) ? (m / 1000).toFixed(1) + ' km'
                                          : Math.round(m) + ' m';
```
* `< 1000` → integer metres with a leading space before the unit, e.g. `"842 m"`, `"0 m"`.
* `>= 1000` → kilometres with **exactly one decimal**, e.g. `"1.2 km"`, `"12.3 km"`.
* The function is also **inlined verbatim** inside `renderItem` (identical branch/identical `toFixed(1)`), so the reimplementation must keep both in sync.

### 1.9 `formatWalkTime(metres)` — `_closure0_slot17`

```js
const formatWalkTime = (m) => Math.max(1, Math.round(m / 80)) + ' min';
```
* Walking speed constant = **80 metres per minute** (≈4.8 km/h).
* Minimum is always `1` → `"1 min"`. Examples: `80 m → "1 min"`, `120 m → "2 min"` (round(1.5)=2), `400 m → "5 min"`, `1240 m → "16 min"` (round(15.5)=16).
* Also inlined verbatim inside `renderItem`.

### 1.10 `haversine(lat1, lon1, lat2, lon2)` — `_closure0_slot12`

Body is inlined at its single call site (identical to the copy inside m734.js):

```js
const dLat = (lat2 - lat1) * Math.PI / 180;
const dLon = (lon2 - lon1) * Math.PI / 180;
const a = Math.sin(dLat / 2) ** 2
        + Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) * Math.sin(dLon / 2) ** 2;
const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
return 12742000 * c;        // metres — Earth diameter 12 742 km
```

### 1.11 `renderItem({item})` — FlatList row renderer

See §2.6 for the full tree.

### 1.12 `keyExtractor(item)`

```js
const keyExtractor = (item) => item.key;
```

---

## 2. Exact UI structure (top → bottom, with every style value)

Concrete numbers in brackets are the resolved theme constants (`SPACING`/`FONT_SIZE`/`BORDER_RADIUS`) and the
light/dark palette values from m576.

### 2.0 Root

```
jsxs(View, {
  style: {
    flex: 1,
    backgroundColor: colors.background,      // #F5F7FA light / #121212 dark
  },
  children: [
    <header>,                 // index 0  — ALWAYS rendered
    status === 'loading'      ? <loading>      : false,   // index 1
    status === 'denied'       ? <denied>       : false,   // index 2
    status === 'locationOff'  ? <locationOff>  : false,   // index 3
    status === 'error'        ? <error>        : false,   // index 4
    status === 'done'         ? <FlatList>     : false,   // index 5
  ]
})
```

* `status === 'idle'` renders **only the header**; the body is blank (background colour only).

### 2.1 Header (always visible)

```
jsxs(View, {
  style: {
    backgroundColor: colors.primary,             // #fc3b38
    paddingHorizontal: SPACING.md,               // 16
    paddingTop: insets.top + SPACING.md,         // safe-area top + 16
    paddingBottom: SPACING.lg,                   // 24
    flexDirection: 'row',
    alignItems: 'flex-start',
    justifyContent: 'space-between',
  },
  children: [
    jsxs(View, { children: [                    // left title block — NO style prop at all
      jsx(Text, { style: { fontSize: FONT_SIZE.xxl(28), fontWeight: '800', color: '#fff' },
                  children: 'Nearby Stops' }),
      jsx(Text, { style: { fontSize: FONT_SIZE.lg(18), fontWeight: '600',
                           color: 'rgba(255,255,255,0.9)' },
                  children: 'Bus stops close to you' }),
    ]}),
    jsx(Pressable, {
      android_ripple: { color: '#FFFFFF30', foreground: true, borderless: true },
      onPress: requestAndFind,                    // the reload action
      disabled: (status === 'loading'),
      hitSlop: 10,
      style: { marginTop: 4 },
      children: jsx(MaterialCommunityIcons, {
        name: 'reload', size: 24, color: '#fff',
        style: { opacity: (status === 'loading') ? 0.5 : 1 },
      }),
    }),
  ]
})
```

Notes:

* Title `fontWeight: '800'` (string), subtitle `fontWeight: '600'` (string), both white family colours hard-coded (`#fff` and `rgba(255,255,255,0.9)`) — not theme values. The wrapping title `View` receives **no `style` prop** (no `flex`, no `flex: 1`), so it shrinks to its content width inside the `space-between` row.
* Reload button: `hitSlop: 10` (all sides), ripple `#FFFFFF30` (≈19 % white), `borderless: true`, `foreground: true`.
* The reload button is **disabled only while `status === 'loading'`**, and its icon drops to `opacity: 0.5` in that same condition.

### 2.2 Loading state (`status === 'loading'`)

```
jsxs(View, { style: { flex: 1, alignItems: 'center', justifyContent: 'center' }, children: [
  jsx(ActivityIndicator, { color: colors.primary /* #fc3b38 */, size: 'large' }),
  jsx(Text, { style: { color: colors.textSecondary /* #757575 / #AAAAAA */,
                       marginTop: SPACING.sm /* 8 */ },
              children: 'Finding your location…' }),      // U+2026 ellipsis
]})
```

* The loading `Text` has **no `fontSize` / `fontWeight`** of its own (default platform size), only `color` and `marginTop`.
* No `paddingHorizontal` on this container (unlike the other three states).
* No `animating` prop → defaults to `true`.

### 2.3 Permission-denied state (`status === 'denied'`)

```
jsxs(View, { style: { flex: 1, alignItems: 'center', justifyContent: 'center',
                      paddingHorizontal: SPACING.xl /* 32 */ }, children: [
  jsx(Image, { source: <location.jpg asset>,                      // module 736
               style: { height: 32, width: 32,
                        tintColor: colors.textSecondary,           // #757575 / #AAAAAA
                        marginBottom: SPACING.sm /* 8 */ } }),
  jsx(Text, { style: { color: colors.textSecondary, textAlign: 'center',
                       marginBottom: SPACING.md /* 16 */ },
              children: 'Location permission is needed to find stops near you.' }),
  jsx(Pressable, {
    android_ripple: { color: '#FFFFFF50', foreground: true },     // ≈31 % white
    onPress: openAppSettings,
    style: { backgroundColor: colors.primary,                     // #fc3b38
             paddingHorizontal: SPACING.lg /* 24 */,
             paddingVertical: SPACING.sm /* 8 */,
             borderRadius: BORDER_RADIUS.md /* 10 */,
             overflow: 'hidden',
             marginBottom: SPACING.sm /* 8 */ },
    children: jsx(Text, { style: { color: '#fff', fontWeight: '700' },
                          children: 'Open App Settings' }),
  }),
  jsx(Pressable, {                                                  // no android_ripple
    onPress: requestAndFind,
    style: { paddingVertical: SPACING.xs /* 4 */ },
    children: jsx(Text, { style: { color: colors.primary /* #fc3b38 */, fontWeight: '700' },
                          children: 'Try Again' }),
  }),
]})
```

### 2.4 Location-off state (`status === 'locationOff'`)

```
jsxs(View, { style: { flex: 1, alignItems: 'center', justifyContent: 'center',
                      paddingHorizontal: SPACING.xl /* 32 */ }, children: [
  jsx(MaterialCommunityIcons, { name: 'map-marker-off-outline', size: 34,
                                color: colors.textSecondary /* #757575 / #AAAAAA */,
                                style: { marginBottom: SPACING.sm /* 8 */ } }),
  jsx(Text, { style: { color: colors.textSecondary, textAlign: 'center',
                       marginBottom: SPACING.md /* 16 */ },
              children: 'Location is turned off on your device. Turn it on to find stops near you.' }),
  jsx(Pressable, {
    android_ripple: { color: '#FFFFFF50', foreground: true },
    onPress: openLocationSettings,
    style: { backgroundColor: colors.primary /* #fc3b38 */,
             paddingHorizontal: SPACING.lg /* 24 */,
             paddingVertical: SPACING.sm /* 8 */,
             borderRadius: BORDER_RADIUS.md /* 10 */,
             overflow: 'hidden',
             marginBottom: SPACING.sm /* 8 */ },
    children: jsx(Text, { style: { color: '#fff', fontWeight: '700' },
                          children: 'Open Location Settings' }),
  }),
  jsx(Pressable, {                                                  // no android_ripple
    onPress: requestAndFind,
    style: { paddingVertical: SPACING.xs /* 4 */ },
    children: jsx(Text, { style: { color: colors.primary /* #fc3b38 */, fontWeight: '700' },
                          children: 'Try Again' }),
  }),
]})
```

* This is the only state whose top visual is a **vector icon** (MaterialCommunityIcons, size 34) rather than the `location.jpg` image; the icon carries no `size`-independent padding, only `marginBottom: 8`.

### 2.5 Error state (`status === 'error'`)

```
jsxs(View, { style: { flex: 1, alignItems: 'center', justifyContent: 'center',
                      paddingHorizontal: SPACING.xl /* 32 */ }, children: [
  jsx(Image, { source: <location.jpg asset>,
               style: { height: 32, width: 32, tintColor: colors.textSecondary,
                        marginBottom: SPACING.sm /* 8 */ } }),
  jsx(Text, { style: { color: colors.textSecondary, textAlign: 'center',
                       marginBottom: SPACING.md /* 16 */ },
              children: 'Could not get your location. Please try again.' }),
  jsx(Pressable, {
    android_ripple: { color: '#FFFFFF50', foreground: true },
    onPress: requestAndFind,
    style: { backgroundColor: colors.primary /* #fc3b38 */,
             paddingHorizontal: SPACING.lg /* 24 */,
             paddingVertical: SPACING.sm /* 8 */,
             borderRadius: BORDER_RADIUS.md /* 10 */,
             overflow: 'hidden' },                // NOTE: no marginBottom here
    children: jsx(Text, { style: { color: '#fff', fontWeight: '700' },
                          children: 'Try Again' }),
  }),
]})
```

* Only **one** button (no secondary "Try Again" text button), and the primary button has **no `marginBottom`** (differs from the denied/locationOff variants); the button text style is otherwise identical (`#fff`, `fontWeight: '700'`, no `fontSize`).

### 2.6 Success state (`status === 'done'`) — `FlatList`

```
jsx(FlatList, {
  data: stops,                     // state array, max 15 entries
  keyExtractor: (item) => item.key,
  contentContainerStyle: { padding: SPACING.md /* 16 */, paddingBottom: SPACING.xl /* 32 */ },
  ListFooterComponent: jsx(Text, {
    style: { textAlign: 'center', color: colors.textSecondary /* #757575 / #AAAAAA */,
             fontStyle: 'italic', fontSize: FONT_SIZE.sm /* 12 */,
             marginTop: SPACING.sm /* 8 */ },
    children: 'Tap any stop for directions · Sorted by walking distance',   // U+00B7 middle dot
  }),
  renderItem: renderItem,
})
```

* **No** `ListEmptyComponent`, **no** `ListHeaderComponent`, **no** `refreshControl`/`onRefresh`, **no** `ItemSeparatorComponent`, **no** `showsVerticalScrollIndicator={false}`, **no** `initialNumToScrollTop`/`extraData`. An empty result therefore shows a blank list area plus only the italic footer line.
* `contentContainerStyle.padding = 16` on all four sides; bottom padding overridden to `32`.

#### 2.6.1 Row — `renderItem({item})`

```
jsxs(Pressable, {
  android_ripple: { color: colors.text + '15', foreground: true },   // '#21212115' light / '#EEEEEE15' dark
  onPress: () => navigation.navigate('StopDetail', { stopName: item.name }),
  style: {
    backgroundColor: colors.card,          // #FFFFFF light / #2C2C2C dark
    borderRadius: BORDER_RADIUS.lg,        // 16
    padding: SPACING.md,                   // 16
    marginBottom: SPACING.sm,              // 8
    elevation: 0.5,                        // Android shadow only (fractional!)
    overflow: 'hidden',
  },
  children: [
    jsxs(View, { style: { flexDirection: 'row', alignItems: 'flex-start' }, children: [
      // (a) leading 38×38 tinted square containing location.jpg
      jsxs(View, { style: { width: 38, height: 38,
                            borderRadius: BORDER_RADIUS.md /* 10 */,
                            backgroundColor: colors.primary + '15',   // '#fc3b3815'
                            alignItems: 'center', justifyContent: 'center',
                            marginRight: SPACING.sm /* 8 */ },
                 children: [
        jsx(Image, { source: <location.jpg asset>,
                     style: { height: 20, width: 20, tintColor: colors.primary /* #fc3b38 */ } }),
      ]}),
      // (b) flexible middle column
      jsxs(View, { style: { flex: 1 }, children: [
        jsx(Text, { numberOfLines: 1,
                    style: { fontSize: FONT_SIZE.base /* 16 */, fontWeight: '700',
                             color: colors.text /* #212121 / #EEEEEE */ },
                    children: item.name }),
        jsxs(View, { style: { flexDirection: 'row', alignItems: 'center', marginTop: 4 }, children: [
          jsx(MaterialIcons, { name: 'directions-walk', size: 19,
                               color: colors.text, style: { marginRight: 3 } }),
          jsx(Text, { style: { fontSize: FONT_SIZE.md /* 14 */,
                               color: colors.textSecondary },
                      children: formatDistance(item.distance) }),
          jsx(Text, { style: { fontSize: FONT_SIZE.md /* 14 */,
                               color: colors.textSecondary,
                               marginHorizontal: 5 },
                      children: ' -- ' }),                 // space, dash, dash, space
          jsx(Ionicons, { name: 'time-outline', size: 19,
                          color: colors.text, style: { marginRight: 3 } }),
          jsx(Text, { style: { fontSize: FONT_SIZE.md /* 14 */,
                               color: colors.textSecondary },
                      children: formatWalkTime(item.distance) }),
        ]}),
      ]}),
      // (c) trailing chevron
      jsx(Text, { style: { fontSize: 18, color: colors.textSecondary },   // literal 18, not FONT_SIZE.lg
                  children: jsx(Feather, { name: 'chevron-right', size: 18,
                                          color: colors.text }) }),
    ]}),
    // (d) route chips
    jsx(View, { style: { flexDirection: 'row', flexWrap: 'wrap',
                         marginTop: SPACING.sm /* 8 */, marginLeft: 46 },   // literal 46
               children: item.routes.slice(0, 4).map((r, i) =>
                 jsx(View, { key: r.routeId + i,                    // string concat routeId + index
                   style: { flexDirection: 'row', alignItems: 'center',
                            backgroundColor: colors.primary + '15',  // '#fc3b3815'
                            borderWidth: 1,
                            borderColor: colors.primary + '30',      // '#fc3b3830'
                            paddingHorizontal: SPACING.sm /* 8 */,
                            paddingVertical: 3,                      // literal 3 (dp)
                            borderRadius: BORDER_RADIUS.full /* 999 */,
                            marginRight: SPACING.xs /* 4 */,
                            marginBottom: SPACING.xs /* 4 */ },
                   children: jsx(RouteChipLabel, { routeId: r.routeId, colors }) })
               ) }),
  ]
})
```

Row structure summary: `Pressable > [ row View > [ 38×38 icon tile, middle column > [ name (1 line), meta row ], chevron Text ], chips row View ]`.

* `marginLeft: 46` aligns the chip block with the middle text column (38 icon tile + 8 `marginRight`).
* `item.routes.slice(0, 4)` — at most **4 route chips** per stop; extra routes are silently dropped (no "+N" badge).
* Chip key = `routeId + index` (e.g. `"O1" + 0` → `"O10"`).
* `elevation: 0.5` is sub-pixel; effectively no visible Android shadow.
* No `borderWidth`, no `borderColor` and no shadow props on the card itself.

---

## 3. Every user-visible string (verbatim)

| # | String | Where |
|---|---|---|
| 1 | `Nearby Stops` | header title |
| 2 | `Bus stops close to you` | header subtitle |
| 3 | `Finding your location…` | loading state (`…` = U+2026) |
| 4 | `Location permission is needed to find stops near you.` | denied state body |
| 5 | `Open App Settings` | denied state primary button |
| 6 | `Try Again` | denied state secondary button / location-off secondary button / error primary button |
| 7 | `Location is turned off on your device. Turn it on to find stops near you.` | location-off state body |
| 8 | `Open Location Settings` | location-off state primary button |
| 9 | `Could not get your location. Please try again.` | error state body |
| 10 | `Tap any stop for directions · Sorted by walking distance` | FlatList footer (`·` = U+00B7) |
| 11 | ` -- ` (space, two hyphens, space) | row meta separator between distance and walk time |
| 12 | `android.settings.LOCATION_SOURCE_SETTINGS` | intent string passed to `Linking.sendIntent` |
| 13 | `ACCESS_FINE_LOCATION` | `PermissionsAndroid.PERMISSIONS` |
| 14 | `` `ReactNativeGeolocation.stopObserving` is deprecated and should not be used. Use `ReactNativeGeolocation.clearWatch` instead. `` | `console.warn` in **m729** `stopObserving()` (never called by this screen) |
| 15 | `Generator functions may not be called on executing generators` | Hermes/Babel runtime guard text, not user-facing |
| 16 | `Trying to call a non-function` | Hermes runtime guard text, not user-facing |

There is **no** toast/alert/`Alert.alert`, **no** modal, **no** rationale dialog, and **no** native permission
rationale string of the app's own — the only permission-related UI is the state screens above. Android's own
system permission dialog is triggered by `PermissionsAndroid.request`.

---

## 4. Icons used (name, size, colour, icon set)

| Icon name | Size | Colour | Icon set (module) | Placement |
|---|---|---|---|---|
| `reload` | 24 | `#fff` (opacity 0.5 while loading) | **MaterialCommunityIcons** (m558) | header reload button |
| `map-marker-off-outline` | 34 | `colors.textSecondary` (`#757575` light / `#AAAAAA` dark) | **MaterialCommunityIcons** (m558) | location-off state, `style:{marginBottom: SPACING.sm}` |
| `directions-walk` | 19 | `colors.text` (`#212121` / `#EEEEEE`) | **MaterialIcons** (m723) | row meta row, `style:{marginRight: 3}` |
| `time-outline` | 19 | `colors.text` | **Ionicons** (m725) | row meta row, `style:{marginRight: 3}` |
| `chevron-right` | 18 | `colors.text` | **Feather** (m727) | row trailing chevron (inside a `Text`, no extra style) |

All five are rendered through the library's default component export
(`jsx(Icon.default, {name, size, color, style})`) — i.e. the plain `createIconSet` glyph-font icons, **not**
`Icon.Button` and **not** `getImageSource`.

Attribution caveat: the icon-set assignment above is derived from the resolved dep indices
(`dep[5] → m558 = MaterialCommunityIcons`, `dep[6] → m723 = MaterialIcons`, `dep[7] → m725 = Ionicons`,
`dep[8] → m727 = Feather`), cross-validated against another app module (m1076) where the same slot→dep-index
convention reproduces React (69), react-native (2), the JSX runtime (238), Feather (727) and the theme constants
(570) correctly. `chevron-right` and `time-outline` exist in several of these sets, so a rebuild may substitute an
equivalent glyph from one bundled icon font; `reload`, `map-marker-off-outline` and `directions-walk` are
unambiguous for their sets.

Context (from the tab host m557, not part of this screen but useful for parity): the "Nearby" tab bar icon is
MaterialCommunityIcons `map-marker-outline` when unfocused and `map-marker` when focused, size 24, colour =
tab `activeColor` (`colors.primary`) / `inactiveColor` (`colors.textSecondary`).

---

## 5. Image assets referenced

| Asset (file) | Registered as | Used by | Style at use site |
|---|---|---|---|
| `src/assets/icons/location.jpg` (module 736; `httpServerLocation: '/assets/src/assets/icons'`, 48×48, scale `[1]`, hash `365dc25f…`, type `jpg`) | `location` | denied state (32×32, tint `textSecondary`, `marginBottom: 8`), error state (same 32×32), row icon tile (20×20, tint `colors.primary`) | see §2.3/§2.5/§2.6.1 |
| `src/assets/icons/speedo.jpg` (m709, 96×96, hash `f22457af…`) | `speedo` | indirect: `renderBusIcon('speedo')` → `RouteChipLabel` Image `source` | 15×15, `marginRight: 5`, `tintColor: route.color \|\| colors.primary` |
| `src/assets/icons/metro.jpg` (m711, 96×96, hash `e0277a6c…`) | `metro` | `renderBusIcon('metro')` | idem |
| `src/assets/icons/orangeline.jpg` (m713, 96×96, hash `e6888e67…`; **registered name is `orange-line`**) | `orange-line` | `renderBusIcon('orangeLine')` — note registered asset *name* differs from the *category key* | idem |
| `src/assets/icons/electric.jpg` (m712, 96×96, hash `011ec33d…`) | `electric` | `renderBusIcon('electric')` | idem |
| `src/assets/icons/filter.jpg` (m716, 64×64, hash `d524aa64…`) | `filter` | `renderBusIcon('all')` (fallback category) — **never reached from this screen**, because `RouteChipLabel` bails out with `null` when the route id is unknown | idem |

No other asset (`speedo`, `metro`, `orangeLine`, `electric`, `filter`, `bus2`, `search`, `arrow-right`,
`location`, `route`, `back`, `share`, `clock`, `clock-filled`, `loop`, `stop`, `location-map`,
`location-direction`, `bus`, `alert`) is referenced by m722; only `location.jpg` is used directly, plus the
four category bus icons via `renderBusIcon`.

Note: `RouteChipLabel` calls `renderBusIcon(route.category)`; if the returned asset module is `undefined`
(unknown category) the `Image` receives `source: undefined` and renders nothing (blank 15×15 slot).

---

## 6. Location permission flow (exact sequence)

1. **Mount / first focus** — `useFocusEffect` fires; `status === 'idle'` → `requestAndFind()`.
2. `setStatus('loading')` → header reload button becomes `disabled` + icon `opacity: 0.5`; body shows spinner + `Finding your location…`.
3. `requestLocationPermission()` → `PermissionsAndroid.request(PermissionsAndroid.PERMISSIONS.ACCESS_FINE_LOCATION)` (Android runtime dialog; no pre-check with `PermissionsAndroid.check`, no `requestMultiple`, no rationale UI first).
4. **Grant** (`RESULTS.GRANTED`) → continue to step 5.
   **Deny / "Don't allow" / "Never ask again"** (anything ≠ `GRANTED`) → `setStatus('denied')` → denied screen (§2.3).
5. `Geolocation.getCurrentPosition(success, error, {enableHighAccuracy: true, timeout: 15000})`.
   * **Success** → build list, `setStops(list)`, `setStatus('done')` (§8).
   * **Error with `code === 2`** (position unavailable, typically device location services off) → `setStatus('locationOff')` → §2.4.
   * **Any other error** (`code === 1` denied, `code === 3` timeout after 15 s, null error object) → `setStatus('error')` → §2.5.
6. **From the denied screen**
   * `Open App Settings` → `Linking.openSettings()` (app's system settings page). Nothing else happens automatically; the retry path is the AppState listener (step 8).
   * `Try Again` → `requestAndFind()` again (full re-request of the runtime permission).
7. **From the location-off screen**
   * `Open Location Settings` → `Linking.sendIntent('android.settings.LOCATION_SOURCE_SETTINGS')` (the system location toggle page).
   * `Try Again` → `requestAndFind()` again.
8. **Returning to the app** (`AppState` `'change'` listener): on every change the ref is updated; if the app became active again from `inactive`/`background` **and** `status` is `'locationOff'` or `'denied'`, `requestAndFind()` runs again automatically. When the user turns location on (step 7) or grants the permission in settings (step 6) and comes back, the screen silently re-runs the whole flow. If `status === 'done'`, returning to the foreground does **not** re-fetch.
9. **Manual refresh** — header reload `Pressable` → `requestAndFind()` from any state (except while `loading`, where the button is `disabled`).

There is no `PermissionsAndroid.check` pre-flight, no `PERMISSIONS.ACCESS_COARSE_LOCATION`, no background
location permission, no `requestAuthorization` (that is iOS-only and never called here), and no
`Geolocation.setRNConfiguration` call anywhere in m722.

---

## 7 & 8. Distance / sorting algorithm, state variables, effects, polling & watch behaviour

### 8.1 Success handler (verbatim logic)

```js
(position) => {
  const {latitude, longitude} = position.coords;
  const list = ALL_STOPS
    .filter(s => s.latitude != null && s.longitude != null)      // drop coordinate-less stops
    .map(s => ({...s, distance: haversine(latitude, longitude, s.latitude, s.longitude)}))
    .sort((a, b) => a.distance - b.distance)                     // ascending, metres
    .slice(0, 15);                                               // HARD CAP: 15 rows
  setStops(list);
  setStatus('done');
}
```

* **No radius filter.** Every coordinate-bearing stop is measured and the 15 closest are kept, however far away.
* `ALL_STOPS` (m734) is the alphabetically-sorted flat stop list: one entry per distinct normalised stop name, each `{key, name, latitude, longitude, routes: [{routeId, index}]}` (see §12.1).
* Spread `{...s, distance}` keeps `key`, `name`, `routes` and adds `distance` (metres, floating point).
* `Math.round` never happens on the raw value — only `formatDistance`/`formatWalkTime` round it.
* Displayed distance: `>= 1000` → one decimal `km`; otherwise integer `m`. Displayed walk time: `max(1, round(distance / 80))` minutes.

### 8.2 State variables

| Variable | Initial | Type | Purpose |
|---|---|---|---|
| `status` | `'idle'` | `'idle' \| 'loading' \| 'denied' \| 'locationOff' \| 'error' \| 'done'` | drives which body branch renders |
| `stops` | `[]` | array of `{key, name, latitude, longitude, routes[], distance}` | FlatList `data` |
| `appStateRef` | `AppState.currentState` | `useRef` | previous AppState value used for the foreground-transition check |

No other state (no search query, no radius, no sort toggle, no ordering state, no refresh counter).

### 8.3 Effects / listeners

| # | Hook | Deps | Behaviour |
|---|---|---|---|
| 1 | `useStatusBarColor(colors.primary)` (m577, internally `useFocusEffect(useCallback(...)))` | colour | sets status-bar background to `#fc3b38` and bar style to `light-content` while the screen is focussed |
| 2 | `useFocusEffect(useCallback(..., [status, requestAndFind]))` | status, requestAndFind | on focus (and whenever `status` changes while focused) call `requestAndFind()` **only if `status === 'idle'`** |
| 3 | `useEffect(..., [status, requestAndFind])` | status, requestAndFind | adds the `AppState` `'change'` listener; cleanup calls `subscription.remove()` |

### 8.4 Polling / watch behaviour

* **No polling.** No `setInterval`, no `setTimeout`, no `Geolocation.watchPosition`, no `clearWatch`.
* Location is acquired exactly once per `requestAndFind()` invocation, via `getCurrentPosition`.
* `useFocusEffect` deps include `status`, but the `status === 'idle'` guard prevents repeat fetches on re-focus once a result exists.
* The only automatic re-acquisition is the AppState-foreground retry described in §6 step 8 (restricted to the `denied`/`locationOff` states).
* `m729`'s wrapper exposes `watchPosition`, `clearWatch`, `requestAuthorization`, `setRNConfiguration`, `stopObserving` but m722 calls **none** of them.

---

## 9. Navigation

* **Outbound (only one):** `navigation.navigate('StopDetail', {stopName: item.name})`
  * Route name: `StopDetail` (exact).
  * Params: **only** `stopName`. No `stopId`, no `routeId`, no params object spread.
  * Trigger: pressing any stop row `Pressable` (whole row is the touch target; ripple `colors.text + '15'`, `foreground: true`).
* **Inbound:** registered by the bottom-tab navigator (m557) as `Screen name="Nearby"`, tab label `Nearby`, tab icon MaterialCommunityIcons `map-marker-outline` / `map-marker`, `headerShown: false`, tab transition `animation: 'shift'`. The screen receives only `navigation` from the navigator; it reads no `route.params`.
* No `navigation.push`, no `goBack`, no ` setParams`, no `addListener('blur'…)`, no deep-link handling, no `Linking.getInitialURL`.

---

## 10. Every user interaction

| Interaction | Effect |
|---|---|
| Press header reload icon | `requestAndFind()` → `status = 'loading'`, permission re-request, new fix, new sort, new 15-row slice. Disabled (no-op) while `status === 'loading'`; icon opacity 0.5 while loading. |
| Press `Open App Settings` (denied state) | `Linking.openSettings()` — leaves the app for the system app-settings page. |
| Press `Open Location Settings` (location-off state) | `Linking.sendIntent('android.settings.LOCATION_SOURCE_SETTINGS')` — opens Android location-source settings. |
| Press `Try Again` (denied / location-off secondary button) | `requestAndFind()` — re-runs the whole flow (permission dialog again if still denied). |
| Press `Try Again` (error state primary button) | `requestAndFind()` — same. |
| Press a stop row | `navigation.navigate('StopDetail', {stopName: item.name})`. |
| Scroll the FlatList | native scroll only; content container padding 16, bottom 32; no infinite scroll. |
| Background → foreground the app while denied/locationOff | automatic silent retry (AppState listener). |
| Rotate device / resize | `insets.top` re-read on re-render, header top padding follows; no custom orientation handling. |
| Android system permission dialog response | `GRANTED` → continue; anything else → denied state. No callback/observer stays registered. |

No pull-to-refresh, no long-press, no swipe actions, no search field, no filter chips on this screen.

---

## 11. States summary (what is on screen)

| `status` | Visual |
|---|---|
| `idle` | Header only; body empty (`colors.background`). Transient (immediately replaced by `loading` on first focus, because `useFocusEffect` fires on mount). |
| `loading` | Centred large `ActivityIndicator` (`colors.primary`) + `Finding your location…` (`colors.textSecondary`, default font size, marginTop 8). Header reload disabled/dimmed. |
| `denied` | 32×32 `location.jpg` tinted `textSecondary`, the permission sentence, primary `Open App Settings` button, secondary `Try Again` text button. |
| `locationOff` | 34px `map-marker-off-outline` icon tinted `textSecondary`, the location-off sentence, primary `Open Location Settings` button, secondary `Try Again` text button. |
| `error` | 32×32 `location.jpg` tinted `textSecondary`, `Could not get your location. Please try again.`, one primary `Try Again` button. |
| `done` | `FlatList` of up to 15 nearest stops (cards with icon tile, name, `distance -- walk time`, chevron, ≤4 route chips) + italic footer line. **No empty-state UI if 0 stops** (only the footer is visible). |

---

## 12. Supporting module specifications

### 12.1 m734.js — data / journey helpers (default-export object)

Module-level exports: **`ALL_STOPS`, `findJourneys`, `formatMinutes`, `formatWalkDistance`, `getStopByKey`, `searchStops`**
(`routeById`, `haversine`, `walkMinutesFor` exist as internal helpers; `routeById` is **not** exported).

#### `norm(value)`
`value ?? ''` → `String.prototype.trim` → `toLowerCase`. Used as the canonical stop key.

#### `ALL_STOPS` (built once at module load)
```js
const map = new Map();
ROUTES.forEach(route => route.stops.forEach((stopName, index) => {
  const key = norm(stopName);
  if (!key) return;
  if (!map.has(key)) map.set(key, {
    key, name: stopName,
    latitude:   route.coords?.[index]?.latitude,     // undefined when coords missing
    longitude:  route.coords?.[index]?.longitude,
    routes: [],
  });
  map.get(key).routes.push({routeId: route.id, index});
}));
const ALL_STOPS = Array.from(map.values()).sort((a, b) => a.name.localeCompare(b.name));
```
* One entry per distinct normalised name; `routes` lists every `{routeId, index}` occurrence of that stop.

#### `searchStops(query)`
* falsy `query` **or** `query.trim()` empty → returns **`ALL_STOPS`** (the whole list, not a copy).
* otherwise `const q = norm(query); return ALL_STOPS.filter(s => s.key.includes(q));` (substring match on the normalised key; no fuzzy matching, no scoring, no ranking).

#### `getStopByKey(key)`
`ALL_STOPS.find(s => s.key === key)` → stop object or `undefined`.

#### `routeById(id)` (internal)
`ROUTES.find(r => r.id === id)` — used by the journey planner; returns `undefined` when unknown.

#### `haversine(aLat, aLon, bLat, bLon)` (internal)
Identical formula to §1.10; earth radius `12742000` m.

#### `walkMinutesFor(metres)` (internal)
`Math.max(1, Math.round(metres / 80))` — 80 m/min walking speed.

#### Walk-neighbour index (module load, internal)
`MAX_WALK_METERS = 600` (`_closure0_slot6`), `WALK_METERS_PER_MINUTE = 80` (`_closure0_slot7`).
For every pair of coordinate-bearing stops within **600 m** great-circle distance, the target stop is pushed as
`{key, name, distanceMeters}` into the source stop's list, and each list is sorted ascending by `distanceMeters`.
This map powers transfer search only — **it does not limit the Nearby screen's list** (which takes the 15 closest overall).

#### Journey planning (internal, used by other screens)
* `minutesOfDay(date)` = `date.getHours() * 60 + date.getMinutes()`.
* `waitMinutesFrom(frequencyMinutes, operatingHours, minutesOfDay)` → minutes until the next departure, computed by rounding up to the next `frequency` slot inside the operating window (0 when outside/unknown).
* `addMinutes(date, minutes)`, `estimateTravelMinutes(stopsTravelled)` = `Math.max(1, Math.round(stopsTravelled * 2))` (2 min per stop).
* `buildLeg(route, fromIdx, toIdx)` → `{routeId, routeName, category, color, fare, frequency, operatingHours, fromName, toName, reversed, stopsTravelled, stopNames, travelMinutes}`; `reversed = fromIdx > toIdx`; `stopNames` reversed when travelling backwards.
* `findBestTransfer(...)` → cheapest interchange between two routes; cost = `|aIdx − bIdx| + |otherIdx diff| + Math.max(1, Math.round(walkMeters / 80)) * 3` (a walk minute is weighted as 3 stops) with a hard 600 m walk cap.
* `legsSignature(journey)` = `journey.legs.map(l => l.routeId + ':' + l.fromName + ':' + l.toName).join('|')`.
* `findJourneys(fromKey, toKey, maxResults = 8)` → array of `{transfers, legs[]}` (0-, 1- and 2-transfer options), de-duplicated by `legsSignature`, sorted by `(transfers asc, total stopsTravelled asc)`, sliced to `maxResults` (default 8), then annotated with `totalStops`, `totalFare` (`parseInt(leg.fare, 10) || 0` summed), `totalWalkMinutes`, `estimatedMinutes` (`max(1, round((arrival − start)/60000))`), `startTime`/`startClock`, `arrivalTime`/`arrivalClock`, per-leg `waitMinutes`, `departureTime`/`departureClock`, `arrivalTime`/`arrivalClock`, and `transferWalk` = `{distanceMeters, minutes, toName}` when a walk leg is longer than 0 m. `parseFrequencyMinutes`, `parseOperatingHours` and `formatClock` come from module m735. Returns `[]` when either stop key is unknown or both keys are equal.
* **`formatMinutes(minutes)`**: `minutes >= 60` → `` `${Math.floor(m/60)}h${m%60}m` `` when the remainder is non-zero, `` `${Math.floor(m/60)}h` `` when the remainder is 0, else `` `${minutes} min` ``.
* **`formatWalkDistance(metres)`**: identical to `formatDistance` — `>= 1000` → `(m/1000).toFixed(1) + ' km'`, else `Math.round(m) + ' m'`.

> Requested-but-absent helpers: `searchInRoute`, `choose`, `addEventListener`, `canOpenURL`, `openURL`,
> `getInitialURL`, `sendIntent`, `shareRoute` **do not exist in m734**. `sendIntent`/`canOpenURL`/`openURL`/
> `openSettings`/`getInitialURL`/`addEventListener` are React Native `Linking`/`AppState` APIs (`Linking` is the
> react-native module, used by m722 only for `sendIntent` and `openSettings`).

### 12.2 m729.js — geolocation wrapper (default export)

```js
export default {
  getCurrentPosition(success, error, options) { return Geolocation.getCurrentPosition(success, error, options); }, // returns undefined
  watchPosition(success, error, options)      { return Geolocation.watchPosition(success, error, options); },
  clearWatch(watchId)                         { Geolocation.clearWatch(watchId); },   // returns undefined
  stopObserving()                             { console.warn('`ReactNativeGeolocation.stopObserving` is deprecated …clearWatch` instead.'); Geolocation.stopObserving(); },
  requestAuthorization(success, error)        { Geolocation.requestAuthorization(success, error); },
  setRNConfiguration(config)                  { Geolocation.setRNConfiguration(config); },
};
```
Underlying implementation module: **m730** (the real library: `getCurrentPosition`, `watchPosition`, `clearWatch`,
`stopObserving` — which warns `Called stopObserving with existing subscriptions.` when invoked while watches exist —
`requestAuthorization`, `setRNConfiguration`, plus `authorizationLevel`, `locationProvider` and
`enableBackgroundLocationUpdates` configuration keys). NearbyScreen uses only `getCurrentPosition`.

### 12.3 m723.js / m725.js / m727.js — icon-font registrations

Each is a one-line `createIconSet`-style registration (from `react-native-vector-icons`):

| Module | Default export | Font family | TTF file |
|---|---|---|---|
| m723 | MaterialIcons component (+ `Button`, `getImageSource`, `getImageSourceSync`) | `Material Icons` | `MaterialIcons.ttf` |
| m725 | Ionicons component (+ `Button`, `getImageSource`, `getImageSourceSync`) | `Ionicons` | `Ionicons.ttf` |
| m727 | Feather component (+ `Button`, `getImageSource`, `getImageSourceSync`) | `Feather` | `Feather.ttf` |

Each registration object only exposes `default`, `Button`, `getImageSource`, `getImageSourceSync`; the glyph
lookup itself is inside `react-native-vector-icons`' shared `createIconSet` implementation (m559/m568 family), so
`name`/`size`/`color`/`style` are the full prop surface used by NearbyScreen.

(For completeness, m558 = MaterialCommunityIcons / `Material Design Icons` / `MaterialCommunityIcons.ttf`, and
19 TTFs ship in `assets/fonts/`.)

---

## 13. Cross-cutting implementation notes

1. **Header is always rendered**, even in `idle`; the background colour of the root view shows through the empty body.
2. `paddingTop` of the header = `insets.top + 16`, so the screen is safe-area aware but does **not** use `edges`/`SafeAreaView`.
3. Status bar colour is set to `#fc3b38` with `light-content` (white icons) whenever the screen is focused.
4. Ripple colours are 8-digit hex alpha suffixes appended to theme colours (`colors.text + '15'`, `colors.primary + '15'`, `colors.primary + '30'`) plus hard-coded `#FFFFFF30` / `#FFFFFF50` in the header and in the state screens' buttons.
5. Android-only code paths: `PermissionsAndroid`, `Linking.sendIntent('android.settings.LOCATION_SOURCE_SETTINGS')`, `android_ripple`, `elevation`. The screen has no iOS branch.
6. Exact numeric literals to preserve: `hitSlop: 10`, `marginTop: 4` (header button), `marginTop: 4` (meta row), `marginHorizontal: 5`, `marginRight: 3` (icons), `38` / `20` (tile & icon sizes), `32` / `20` (state images), `46` (chips indent), `18` (chevron font size & icon size), `3` (chip vertical padding), `0.5` / `1` (reload opacity), `15` (list cap), `15000` (geolocation timeout ms), `1000` (m/km threshold), `80` (m per walk minute), `12742000` (earth radius m).
7. `formatDistance` / `formatWalkTime` exist both as module-level functions and as inlined copies inside `renderItem`; the inlined copies are what actually render the row text.
8. Because `RouteChipLabel` returns `null` for an unknown `routeId` while its container `View` (with chip styling) still renders, a chip with a missing route appears as an **empty pill** (bordered, tinted background) with no content.

### Appendix A — resolved literal values

| Token group | Resolved values |
|---|---|
| `SPACING` | xs 4, sm 8, md 16, lg 24, xl 32, xxl 48 |
| `FONT_SIZE` | xs 10, sm 12, md 14, base 16, lg 18, xl 22, xxl 28, xxxl 36 |
| `BORDER_RADIUS` | sm 6, md 10, lg 16, xl 24, full 999 |
| Light `colors` | primary `#fc3b38`, background `#F5F7FA`, card `#FFFFFF`, border `#E0E0E0`, text `#212121`, textSecondary `#757575` |
| Dark `colors` | primary `#fc3b38`, background `#121212`, card `#2C2C2C`, border `#333333`, text `#EEEEEE`, textSecondary `#AAAAAA` |
| Derived alpha colours | `colors.primary + '15'` → `#fc3b3815`; `colors.primary + '30'` → `#fc3b3830`; `colors.text + '15'` → `#21212115` (light) / `#EEEEEE15` (dark); hard-coded ripples `#FFFFFF30`, `#FFFFFF50` |
