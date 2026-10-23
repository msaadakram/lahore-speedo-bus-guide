# Home Screen Spec — `RouteFinderScreen` (module 569) + `StopCard` (module 1021)

**Target app:** Lahore Speedo Bus Guide (`com.codez.lahoreelectricbusguide`), React Native / Hermes, Metro bundle.
**Sources analysed (verbatim register-machine dumps):**

| Module | File | Lines | Exports | Role |
|---|---|---|---|---|
| 569 | `/home/ubuntu/bus/reverse_engineering/hermes/app_graph_src/m569.js` | 1089 | `default = RouteFinderScreen` | The **Home tab** screen. Also contains the private components `TagChip`, `StopField`, `HowItWorksRow`. |
| 1021 | `/home/ubuntu/bus/reverse_engineering/hermes/app_graph_src/m1021.js` | 257 | `default = StopCard` | Presentational stop row card (used by `RouteDetailScreen`, module 1020). |

No Dart/Flutter code is included below — implementation-ready specification only.
All numbers below are the **exact** values recovered from the dump (dp / px as used by React Native style props).

---

## 0. How to read this spec (dump conventions used)

* Object literals print as `rN = {'name': 'Home', 'children': null}`; a **numeric key `k` = the k-th declared property** of that literal (`r5[0] = x` ⇒ the 1st declared prop is `x`).
* `rN.jsx(Component, {...})` / `rN.jsxs(Component, {...})` ⇒ JSX element. `jsxs` is used when the child list is an **array** (2+ children).
* Small integer registers (`r0`, `r1`, `r2`, …) are literal indices in this dump: `deps[r7]` = the 8th dependency, `arr[r0]` = `arr[0]`, `props[3]` = the 4th declared prop.
* Recovered function names appear as `// Original name: Foo`.
* `x + k` where `k` is a raw string (`r19 = '30'; r11 = r18 + r19`) is **JS string concatenation**, i.e. an 8-digit hex colour `#RRGGBBAA` (Android-style alpha suffix). See §12 for conversions.

---

## 1. Dependency resolution (which depot index = which library)

`m569.js` header: `deps=[1, 32, 69, 2, 558, 238, 570, 571, 577, 700, 709, 711, 712, 713]`
`m1021.js` header: `deps=[1, 69, 2, 238, 571, 570, 1022]`

| m569 index | m1021 index | Module | What it is | Verified by |
|---|---|---|---|---|
| – | – | 1 | Babel `_interopRequireWildcard` helper module (inlined helper, not app code) | appears as the wrapper used for `require(...)` |
| 1 (`deps[1]`) | – | 32 | Babel destructuring helper (`sliceToArray`-style), used as `X.default(arr, 2)` then `arr[0]`, `arr[1]` | m569 L525-532, m571 L183-193 |
| 2 (`deps[2]`) | 1 (`deps[1]`) | 69 | **React** (namespace: `useState`) | m569 L521; m1021 L44 |
| 3 (`deps[3]`) | 2 (`deps[2]`) | 2 | **react-native** (`View`, `Text`, `Pressable`, `ScrollView`, `Image`, `FlatList`) | m569 L185; m1021 L52 |
| 4 (`deps[4]`) | – | 558 | **react-native-vector-icons / `MaterialCommunityIcons`** (default export) | m558 = `createIconSet(…, 'Material Design Icons', 'MaterialCommunityIcons.ttf')` |
| 5 (`deps[5]`) | 3 (`deps[3]`) | 238 | **`react/jsx-runtime`** (`jsx`, `jsxs`) | m239 = `jsxProd` with `Fragment`/`jsx`/`jsxs` |
| 6 (`deps[6]`) | 5 (`deps[5]`) | 570 | **Design tokens** module: `SPACING`, `FONT_SIZE`, `BORDER_RADIUS` | m570 L7-17 |
| 7 (`deps[7]`) | 4 (`deps[4]`) | 571 | **Theme context** (`useTheme`) | m571 (`ThemePreference` context, `useTheme`) |
| 8 (`deps[8]`) | – | 577 | `useStatusBarColor` hook | m577 |
| 9 (`deps[9]`) | – | 700 | **react-native-safe-area-context** (`useSafeAreaInsets`) | m700 re-export |
| 10 (`deps[10]`) | – | 709 | image asset `speedo.jpg` | m709 |
| 11 (`deps[11]`) | – | 711 | image asset `metro.jpg` | m711 |
| 12 (`deps[12]`) | – | 712 | image asset `electric.jpg` | m712 |
| 13 (`deps[13]`) | – | 713 | image asset `orange-line.jpg` | m713 |
| – | 6 (`deps[6]`) | 1022 | image asset `route.jpg` | m1022 (used by `StopCard`) |

### 1.1 Design tokens (module 570) — use verbatim

```
SPACING      = { xs: 4,  sm: 8,  md: 16,  lg: 24,  xl: 32,  xxl: 48 }
FONT_SIZE    = { xs: 10, sm: 12, md: 14,  base: 16, lg: 18, xl: 22, xxl: 28, xxxl: 36 }
BORDER_RADIUS= { sm: 6,  md: 10, lg: 16,  xl: 24,  full: 999 }
```

### 1.2 Theme colours (module 576, consumed through `useTheme()`)

```
COLORS (light)      = { primary:'#fc3b38', background:'#F5F7FA', card:'#FFFFFF', border:'#E0E0E0',
                        text:'#212121', textSecondary:'#757575', white:'#FFFFFF',
                        black:'#000000', overlay:'rgba(0,0,0,0.5)' }
DARK_COLORS (dark)  = { primary:'#fc3b38', background:'#121212', card:'#2C2C2C', border:'#333333',
                        text:'#EEEEEE', textSecondary:'#AAAAAA', white:'#FFFFFF',
                        black:'#000000', overlay:'rgba(0,0,0,0.7)' }
```

`useTheme()` (module 571) returns `{ colors, isDark, toggleTheme, preference, setThemePreference }`.
Both modules only destructure `const { colors } = useTheme()`.

### 1.3 `useStatusBarColor` (module 577)

`useStatusBarColor(color = colors.primary, barStyle = 'light-content', animated = true)`
→ `useFocusEffect(useCallback(() => { StatusBar.setBarStyle(barStyle, animated); StatusBar.setBackgroundColor(color, animated); }, [color, barStyle, animated]))`.

---

## 2. Components and helper functions

### 2.1 `TagChip` (m569 L165-247) — private, not exported

A translucent "pill" used in the hero header. Rendered on the **primary-coloured** background, so all of its colours are hard-coded whites (not theme colours).

**Props**

| Prop | Type | Default | Notes |
|---|---|---|---|
| `icon` | string | `null` | MaterialCommunityIcons glyph name. Used only when `iconSource` is falsy. |
| `iconSource` | asset object | `undefined` | Result of `require(...jpg)`; when present an `<Image>` is rendered instead of the icon. |
| `label` | string | – | Text of the chip. |
| `colors` | object | – | Theme colours. **Received but effectively unused** in the current code (colours are hard-coded). |
| `last` | bool | `false` | When `false`, a trailing `·` separator is appended. |

**Behaviour / structure** (`jsxs(View, {style, children})`)

```
<View style={{flexDirection:'row', alignItems:'center'}}>
   {iconSource
      ? <Image source={iconSource}
               style={{width:13, height:13, tintColor:'rgba(255,255,255,0.9)', marginRight:5}} />
      : <MaterialCommunityIcons name={icon} size={14}
               color="rgba(255,255,255,0.9)" style={{marginRight:5}} />}
   <Text style={{color:'rgba(255,255,255,0.9)', fontSize:12, fontWeight:'600'}}>{label}</Text>
   {!last && <Text style={{color:'rgba(255,255,255,0.6)', marginHorizontal:4}}>·</Text>}
</View>
```

Details:
* Container style is an **inline object** (not an array, not `StyleSheet`).
* Icon branch is chosen by `if (iconSource)` — Image wins over icon.
* The separator branch is `!last && <Text>·</Text>` (children array slot holds `false` when `last === true`, React renders nothing).
* No `numberOfLines`, no `ellipsizeMode`, no touch handlers.

### 2.2 `StopField` (m569 L248-372) — private, not exported

One pressable "from/to" input row with a coloured round icon badge, a small uppercase label and a value/placeholder line.

**Props**

| Prop | Type | Default | Notes |
|---|---|---|---|
| `label` | string | – | `'FROM'` / `'TO'` — rendered verbatim (already uppercase). |
| `accent` | string (hex) | – | `'#F08C00'` (FROM) or `'#2E7D32'` (TO). Used for badge bg, icon colour. |
| `icon` | string | – | MaterialCommunityIcons glyph: `'map-marker'` / `'flag-variant'`. |
| `value` | string &#124; undefined | `undefined` | Selected stop name. |
| `placeholder` | string | – | Shown when `value` is falsy. |
| `onPress` | function | – | Attached to the whole `Pressable`. |
| `colors` | object | – | Theme colours. |

**Behaviour**

* Ripple: `android_ripple={{color: colors.text + '15', foreground: true}}`.
* Pressing the row calls `onPress` (opens the Stop Picker).
* Value styling: `fontWeight` = `value ? '700' : '400'`; `color` = `value ? colors.text : colors.textSecondary`.
* Displayed text = `value || placeholder` (so `undefined`/`''` ⇒ placeholder).
* Value `Text` has `numberOfLines={1}`.

**Structure** (`jsxs(Pressable, {android_ripple, onPress, style, children})`)

```
<Pressable android_ripple={{color: colors.text+'15', foreground:true}}
           onPress={onPress}
           style={{paddingVertical:8, flexDirection:'row', alignItems:'center'}}>
  <View style={{width:34, height:34, borderRadius:17, backgroundColor: accent+'18',
                alignItems:'center', justifyContent:'center', marginRight:8}}>
    <MaterialCommunityIcons name={icon} size={16} color={accent} />
  </View>
  <View style={{flex:1}}>
    <Text style={{fontSize:10, fontWeight:'700', color: colors.textSecondary, letterSpacing:0.5}}>
      {label}
    </Text>
    <Text numberOfLines={1}
          style={{fontSize:16, fontWeight: value?'700':'400',
                  color: value?colors.text:colors.textSecondary, marginTop:2}}>
      {value || placeholder}
    </Text>
  </View>
  <MaterialCommunityIcons name="chevron-right" size={18} color={colors.textSecondary} />
</Pressable>
```

### 2.3 `HowItWorksRow` (m569 L373-496) — private, not exported

One explanatory card in the "HOW IT WORKS" section: numbered badge on the right, icon tile on the left, title + subtitle in the middle.

**Props**

| Prop | Type | Default | Notes |
|---|---|---|---|
| `icon` | string | – | MaterialCommunityIcons glyph: `'bus-multiple'`, `'routes'`, `'wifi-off'`. |
| `title` | string | – | Bold title line. |
| `subtitle` | string | – | Secondary line. |
| `number` | string | – | Already-formatted ordinal: `'01'`, `'02'`, `'03'`. |
| `colors` | object | – | Theme colours. |

**Structure** (`jsxs(View, {style, children})`)

```
<View style={{flexDirection:'row', alignItems:'center', backgroundColor: colors.card,
              borderRadius:16, padding:16, marginBottom:8}}>
  <View style={{width:38, height:38, borderRadius:10, backgroundColor: colors.primary+'15',
                alignItems:'center', justifyContent:'center', marginRight:8}}>
    <MaterialCommunityIcons name={icon} size={19} color={colors.primary} />
  </View>
  <View style={{flex:1}}>
    <Text style={{fontSize:16, fontWeight:'700', color: colors.text}}>{title}</Text>
    <Text style={{fontSize:12, color: colors.textSecondary, marginTop:2}}>{subtitle}</Text>
  </View>
  <Text style={{fontSize:12, fontWeight:'700', color: colors.border}}>{number}</Text>
</View>
```

* The ordinal `Text` uses `colors.border` as its colour (intentionally washed out).
* No press handlers at all.

### 2.4 `RouteFinderScreen` (m569 L497-1089) — **the exported Home screen**

**Props**

| Prop | Type | Notes |
|---|---|---|
| `navigation` | React Navigation navigation object | Only `navigation` is read; `route.params` is **never** read by this screen. |
| `route` | – | Not used. |

**Hooks, in evaluation order**

1. `const { colors } = useTheme();` (module 571)
2. `useStatusBarColor(colors.primary);` (module 577) — status bar background = theme primary, style `light-content`.
3. `const [fromStop, setFromStop] = useState(null);`
4. `const [toStop, setToStop] = useState(null);`
5. `const insets = useSafeAreaInsets();` (module 700) — only `insets.top` is used.
6. `const openPicker = (mode) => { … }` (plain closure; no `useCallback`/`useMemo`/`useEffect` is emitted for this screen).

**`openPicker(mode)` — exact behaviour**

```
navigation.navigate('StopPicker', {
  mode,                                   // 'from' | 'to'
  onSelect: (stop) => (mode === 'from' ? setFromStop(stop) : setToStop(stop)),
});
```

* `onSelect` receives the stop object chosen in `StopPickerScreen` (module 1073) and calls `goBack()` after invoking it.
* Stop object shape (module 734 `ALL_STOPS`): `{ key: normalizedName, name: displayName, latitude, longitude, routes: [{routeId, index}] }` — `key` is the lowercase/trimmed name, `name` is the display name, sorted by `name.localeCompare`.
* Decompiler note: hermes-de emitted `openPicker`'s body inlined at the two `onPress` call sites (the closure slot holds the function object); semantics above are certain.

**Derived value**

```
const canSearch = !!fromStop && !!toStop && (fromStop.key !== toStop.key);
```
(compiled as a short-circuit `&&` chain with a `ToBoolean` on each stop object, then a `!==` of the two `key`s).

**`swap()` — exact behaviour**

```
setFromStop(toStop);
setToStop(fromStop);
```

**Top-level render** (`jsxs(View, {style, children})`)

```
<View style={{flex:1, backgroundColor: colors.background}}>
  {/* 1. fixed hero header (NOT scrollable) */}
  <View style={{backgroundColor: colors.primary, paddingHorizontal:16,
                paddingTop: insets.top + 16, paddingBottom:32}}>
     … (see §3.1)
  </View>
  {/* 2. scrollable body */}
  <ScrollView showsVerticalScrollIndicator={false} contentContainerStyle={{paddingBottom:32}}>
     … (see §3.2)
  </ScrollView>
</View>
```

### 2.5 `StopCard` (m1021 L27-256) — exported `default`

Presentational stop row used inside `RouteDetailScreen`'s `FlatList`.

**Props**

| # | Prop | Type | Default | Notes |
|---|---|---|---|---|
| 1 | `stop` | string | – | Stop name shown in the title line. |
| 2 | `index` | number &#124; string | – | Ordinal shown in the badge (caller passes `index + 1`). |
| 3 | `estimatedTime` | string | – | Secondary line (caller passes the route `frequency`). |
| 4 | `routeColor` | string (hex) | – | Route colour used for badge/tint/highlight. |
| 5 | `onPress` | function | – | Row press (opens `StopDetail`). |
| 6 | `onMapPress` | function &#124; undefined | `undefined` | When provided a small map button is rendered on the right. |
| 7 | `isHighlighted` | bool | `false` | Selected-stop emphasis. |

**Behaviour**

* When `isHighlighted === false` (default): card = `colors.card`, no border, `elevation: 1`, `shadowColor: colors.black`.
* When `isHighlighted === true`: card bg = `routeColor + '15'`, `borderWidth: 1.5`, `borderColor: routeColor`, `elevation: 0`.
* `onMapPress` present ⇒ extra `Pressable` with `routeColor` background, a `route.jpg` icon tinted `#fff`, and a 30dp hit-slop on all four sides.
* All colour strings built by concatenation: `routeColor + '30'`, `routeColor + '70'`, `routeColor + '15'`, `colors.text + '50'`.
* Uses its own `useTheme()` call (theme is re-read per card).

**Structure** (`jsxs(Pressable, {android_ripple, onPress, style, children})`)

```
<Pressable android_ripple={{color: routeColor+'30', foreground:true}}
           onPress={onPress}
           style={{backgroundColor: isHighlighted ? routeColor+'15' : colors.card,
                   borderWidth: isHighlighted ? 1.5 : 0,
                   borderColor: isHighlighted ? routeColor : 'transparent',
                   borderRadius:16, marginHorizontal:16, marginVertical:4, padding:16,
                   flexDirection:'row', alignItems:'flex-start',
                   elevation: isHighlighted ? 0 : 1, shadowColor: colors.black,
                   overflow:'hidden'}}>
  {/* index badge */}
  <View style={{width:32, height:32, borderRadius:10,
                backgroundColor: (routeColor || colors.primary)+'30',
                borderWidth:1, borderColor: (routeColor || colors.primary)+'70',
                alignItems:'center', justifyContent:'center', marginRight:8, marginTop:2}}>
    <Text style={{color: routeColor || colors.primary, fontSize:12, fontWeight:'700'}}>
      {index}
    </Text>
  </View>
  {/* text column */}
  <View style={{flex:1}}>
    <Text numberOfLines={2} style={{fontSize:16, fontWeight:'700', color: colors.text}}>{stop}</Text>
    <Text style={{fontSize:12, color: colors.textSecondary, marginTop:2}}>{estimatedTime}</Text>
  </View>
  {/* optional map shortcut */}
  {onMapPress &&
    <Pressable hitSlop={{top:30, bottom:30, left:30, right:30}}
               android_ripple={{color: colors.text+'50', foreground:true}}
               onPress={onMapPress}
               style={{backgroundColor: routeColor, borderRadius:10, padding:11,
                       marginLeft:8, overflow:'hidden'}}>
      <Image source={require('…/route.jpg')} style={{height:18, width:18, tintColor:'#fff'}} />
    </Pressable>}
</Pressable>
```

* The 3rd child slot of the card always exists; it holds `undefined` when `onMapPress` is falsy.
* `routeColor || colors.primary` fallback pattern appears exactly as `(routeColor + '30') || (colors.primary + '30')` in the dump.

---

## 3. Exact UI structure (every style value)

Notation: values in parentheses are the token expansions (§1.1/§1.2). All style props are **plain inline objects** (no `StyleSheet.create`, no style arrays anywhere in these two modules).

### 3.1 `RouteFinderScreen` — hero header (fixed, not inside the `ScrollView`)

```
View  [style={{flex:1, backgroundColor: colors.background}}]                       // SCREEN ROOT
├─ View  [style={{backgroundColor: colors.primary,                                // HERO HEADER
│                paddingHorizontal: 16 /*SPACING.md*/,
│                paddingTop: insets.top + 16 /*SPACING.md*/,
│                paddingBottom: 32 /*SPACING.xl*/}}]
│  ├─ View [style={{flexDirection:'row', alignItems:'center',
│  │               justifyContent:'space-between', marginBottom: 24 /*SPACING.lg*/}}]
│  │  ├─ Text   children: "Lahore 🇵🇰"
│  │  │          style={{fontSize: 18 /*FONT_SIZE.lg*/, fontWeight:'800', color:'#fff'}}
│  │  └─ Pressable  android_ripple={{color:'#FFFFFF30', foreground:true, borderless:true}}
│  │      onPress={() => navigation.navigate('Search')}
│  │      hitSlop={10}
│  │      └─ MaterialCommunityIcons  name="magnify"  size={24}  color="#fff"
│  ├─ Text   children: "Every route, one tap away!"
│  │          style={{fontSize: 22 /*FONT_SIZE.xl*/, fontWeight:'800', color:'#fff', lineHeight:40}}
│  └─ View [style={{flexDirection:'row', alignItems:'center', flexWrap:'wrap',
│                   marginTop: 8 /*SPACING.sm*/}}]
│     ├─ TagChip  iconSource={require('speedo.jpg')}      label="Speedo"       colors={colors}
│     ├─ TagChip  iconSource={require('metro.jpg')}       label="Metro"        colors={colors}
│     ├─ TagChip  iconSource={require('electric.jpg')}    label="Electric"     colors={colors}
│     ├─ TagChip  iconSource={require('orange-line.jpg')} label="Orange Line"  colors={colors}
│     └─ TagChip  icon="wifi-off"  label="Offline"  colors={colors}  last={true}
└─ ScrollView  showsVerticalScrollIndicator={false}
      contentContainerStyle={{paddingBottom: 32 /*SPACING.xl*/}}
   ├─ View [style={{backgroundColor: colors.card, marginHorizontal: 16 /*SPACING.md*/,
   │               marginTop: 16 /*SPACING.md*/, borderRadius: 16 /*BORDER_RADIUS.lg*/,
   │               padding: 8 /*SPACING.sm*/}}]                                 // ROUTE CARD
   │  ├─ StopField  label="FROM"  accent="#F08C00"  icon="map-marker"
   │  │             value={fromStop ? fromStop.name : undefined}
   │  │             placeholder="From — pick a stop"
   │  │             onPress={() => openPicker('from')}  colors={colors}
   │  ├─ View [style={{flexDirection:'row', alignItems:'center'}}]              // CONNECTOR
   │  │  └─ View [style={{width:34, alignItems:'center'}}]
   │  │     └─ View [style={{width:1, height:16 /*SPACING.md*/,
   │  │                     backgroundColor: colors.border}}]                  // 1dp vertical line
   │  ├─ View [style={{flexDirection:'row', alignItems:'center'}}]              // TO ROW
   │  │  ├─ View [style={{flex:1}}]
   │  │  │  └─ StopField  label="TO"  accent="#2E7D32"  icon="flag-variant"
   │  │  │               value={toStop ? toStop.name : undefined}
   │  │  │               placeholder="To — pick a stop"
   │  │  │               onPress={() => openPicker('to')}  colors={colors}
   │  │  └─ Pressable  android_ripple={{color: colors.text+'20', foreground:true, borderless:true}}
   │  │      onPress={swap}
   │  │      style={{width:32, height:32, borderRadius:16, backgroundColor: colors.background,
   │  │                borderWidth:1, borderColor: colors.border, alignItems:'center',
   │  │                justifyContent:'center', marginRight: 4 /*SPACING.xs*/, overflow:'hidden'}}
   │  │      └─ MaterialCommunityIcons  name="swap-vertical"  size={16}  color={colors.textSecondary}
   │  └─ Pressable                                                     // FIND ROUTES BUTTON
   │      android_ripple={{color: colors.text+'15', foreground:true}}
   │      disabled={!canSearch}
   │      onPress={() => navigation.navigate('JourneyResults', {
   │                   fromKey: fromStop.key, toKey: toStop.key,
   │                   fromName: fromStop.name, toName: toStop.name})}
   │      style={{flexDirection:'row', alignItems:'center', justifyContent:'center',
   │               backgroundColor: canSearch ? colors.primary+'15' : colors.background,
   │               marginTop: 8 /*SPACING.sm*/, paddingVertical: 16 /*SPACING.md*/,
   │               borderRadius: 16 /*BORDER_RADIUS.lg*/, overflow:'hidden'}}
   │      ├─ MaterialCommunityIcons  name="magnify"  size={18}
   │      │      color={canSearch ? colors.primary : colors.textSecondary}
   │      │      style={{marginRight: 4 /*SPACING.xs*/}}
   │      └─ Text children: "Find Routes"
   │             style={{color: canSearch ? colors.primary : colors.textSecondary,
   │                     fontSize: 16 /*FONT_SIZE.base*/}}
   └─ View [style={{marginHorizontal: 16 /*SPACING.md*/, marginTop: 24 /*SPACING.lg*/}}]
      │                                                                 // HOW IT WORKS SECTION
      ├─ Text children: "HOW IT WORKS"
      │      style={{fontSize: 12 /*FONT_SIZE.sm*/, fontWeight:'800',
      │               color: colors.textSecondary, letterSpacing:0.5,
      │               marginBottom: 8 /*SPACING.sm*/}}
      ├─ HowItWorksRow  icon="bus-multiple"  title="All Bus Types"
      │                 subtitle="Speedo, Metro, Orange Line & Electric buses"
      │                 number="01"  colors={colors}
      ├─ HowItWorksRow  icon="routes"  title="Direct or One Transfer"
      │                 subtitle="We'll find the best route for you"
      │                 number="02"  colors={colors}
      └─ HowItWorksRow  icon="wifi-off"  title="Works Offline"
                        subtitle="No internet needed to find your route"
                        number="03"  colors={colors}
```

**Empty-state / placeholder behaviour**
* `fromStop`/`toStop` start as `null` ⇒ both `StopField`s show their placeholder strings, styled `fontWeight:'400'` and `colors.textSecondary`.
* `canSearch === false` ⇒ the Find Routes `Pressable` is `disabled`, its background is `colors.background`, its icon and label are `colors.textSecondary` (greyed out, no red).
* The `FROM` → `TO` 1dp connector line is always rendered (no state involved).

**No** FlatList, `SectionList`, `RefreshControl`, `ActivityIndicator`, `Skeleton`, empty-state illustration, error banner or `ListEmptyComponent` exists on this screen — it is a static, fully-offline screen.

### 3.2 `StopCard` — exact layout (module 1021)

```
Pressable  (see §2.5 for all style values)
├─ View   32×32, radius 10, bg (routeColor||primary)+'30', border 1px (routeColor||primary)+'70',
│         marginRight 8, marginTop 2
│  └─ Text  {color: routeColor||colors.primary, fontSize:12, fontWeight:'700'}  → {index}
├─ View   {flex:1}
│  ├─ Text  numberOfLines={2}  {fontSize:16, fontWeight:'700', color:colors.text}  → {stop}
│  └─ Text                      {fontSize:12, color:colors.textSecondary, marginTop:2}
│                              → {estimatedTime}
└─ Pressable (only when onMapPress)  hitSlop 30 all sides, bg routeColor, radius 10,
                                    padding 11, marginLeft 8, overflow hidden
   └─ Image  source=route.jpg  {height:18, width:18, tintColor:'#fff'}
```

---

## 4. Every literal string shown to the user (verbatim)

All strings recovered from `m569.js` / `m1021.js`, in order of appearance (exact bytes, em-dash = U+2014, flag = 🇵🇰 = U+1F1F5 U+1F1F0):

| String | Where |
|---|---|
| `Lahore 🇵🇰` | Header title `Text` (m569 L606) |
| `Every route, one tap away!` | Header tagline `Text` (m569 L644) |
| `Speedo` | `TagChip` label (m569 L666) |
| `Metro` | `TagChip` label (m569 L675) |
| `Electric` | `TagChip` label (m569 L683) |
| `Orange Line` | `TagChip` label (m569 L691) |
| `Offline` | `TagChip` label (m569 L699) |
| `·` | `TagChip` separator (U+00B7 MIDDLE DOT) (m569 L231) |
| `From — pick a stop` | `StopField` placeholder, FROM (m569 L755) |
| `To — pick a stop` | `StopField` placeholder, TO (m569 L858) |
| `FROM` | `StopField` label (m569 L755) |
| `TO` | `StopField` label (m569 L858) |
| `Find Routes` | Primary button label (m569 L1008) |
| `HOW IT WORKS` | Section heading (m569 L1043) |
| `All Bus Types` | `HowItWorksRow` title (m569 L1063) |
| `Speedo, Metro, Orange Line & Electric buses` | `HowItWorksRow` subtitle (m569 L1063) |
| `Direct or One Transfer` | `HowItWorksRow` title (m569 L1068) |
| `We'll find the best route for you` | `HowItWorksRow` subtitle (m569 L1068) — note the ASCII apostrophe, emitted in double quotes |
| `Works Offline` | `HowItWorksRow` title (m569 L1073) |
| `No internet needed to find your route` | `HowItWorksRow` subtitle (m569 L1073) |
| `01`, `02`, `03` | `HowItWorksRow` numbers (m569 L1063/1068/1073) |
| `Trying to call a non-function` | decompiler artifact of the throwTypeError guard on `openPicker` — **not user-visible** (m569 L763) |

There are **no other user-visible strings** in either module. No text-transform is applied anywhere (all uppercase strings are already typed uppercase). No `accessibilityLabel`s, no `testID`s are emitted.

---

## 5. Icons (all from `react-native-vector-icons` → `MaterialCommunityIcons`, glyph font `MaterialCommunityIcons.ttf`, family `Material Design Icons`)

| Component | context | Icon name | Size | Colour |
|---|---|---|---|---|
| Header search button | `RouteFinderScreen` | `magnify` | 24 | `#fff` |
| Find Routes button | `RouteFinderScreen` | `magnify` | 18 | `canSearch ? colors.primary : colors.textSecondary` |
| Swap button | `RouteFinderScreen` | `swap-vertical` | 16 | `colors.textSecondary` |
| FROM field | `StopField` | `map-marker` | 16 | `accent` = `#F08C00` |
| TO field | `StopField` | `flag-variant` | 16 | `accent` = `#2E7D32` |
| FROM/TO field trailing | `StopField` | `chevron-right` | 18 | `colors.textSecondary` |
| TagChip (Offline) | `TagChip` | `wifi-off` | 14 | `rgba(255,255,255,0.9)` |
| How it works 1 | `HowItWorksRow` | `bus-multiple` | 19 | `colors.primary` |
| How it works 2 | `HowItWorksRow` | `routes` | 19 | `colors.primary` |
| How it works 3 | `HowItWorksRow` | `wifi-off` | 19 | `colors.primary` |

**No `MaterialIcons` and no `Ionicons` usage exists in these two modules.** (For reference, the rest of the app does use `MaterialCommunityIcons` throughout, e.g. the tab bar in module 557 uses `home-outline`/`home`, `map-marker-outline`/`map-marker`, `bus-side`/`bus`.)

---

## 6. Image assets referenced

`TagChip`/`RouteFinderScreen` use `<Image source={require(<asset module>)} />`; the modules each `registerAsset({__packager_asset:true, httpServerLocation:'/assets/src/assets/icons', …})`.

| Used in | Module | `name` | `type` | `httpServerLocation` | width×height | scales | Rendered size |
|---|---|---|---|---|---|---|---|
| TagChip `Speedo` | 709 | `speedo` | jpg | `/assets/src/assets/icons` | 96×96 | `[1]` | 13×13 dp, `tintColor: rgba(255,255,255,0.9)`, `marginRight: 5` |
| TagChip `Metro` | 711 | `metro` | jpg | `/assets/src/assets/icons` | 96×96 | `[1]` | 13×13 dp, `tintColor: rgba(255,255,255,0.9)`, `marginRight: 5` |
| TagChip `Electric` | 712 | `electric` | jpg | `/assets/src/assets/icons` | 96×96 | `[1]` | 13×13 dp, `tintColor: rgba(255,255,255,0.9)`, `marginRight: 5` |
| TagChip `Orange Line` | 713 | `orange-line` | jpg | `/assets/src/assets/icons` | 96×96 | `[1]` | 13×13 dp, `tintColor: rgba(255,255,255,0.9)`, `marginRight: 5` |
| `StopCard` map button | 1022 | `route` | jpg | `/assets/src/assets/icons` | 48×48 | `[1]` | 18×18 dp, `tintColor: #fff` |

Note the on-disk/asset name is `orange-line` (hyphen), which corresponds to the `OrangeLine` import in the original TypeScript source. `tintColor` is used on every image (they are monochrome masks tinted at render time).

Full app icon-asset inventory (for reference, modules 709–721 / 1022–1032): `speedo, metro, electric, orange-line, filter, bus2, search, arrow-right, location, route, back, back-icon, back-icon-mask, share, clock, clock-filled, loop, stop, location-map, location-direction, bus, alert, search-icon, close-icon, clear-icon, close, down`.

---

## 7. State, derived data and effects

| Screen | State | Initial | Setter | Set by |
|---|---|---|---|---|
| `RouteFinderScreen` | `fromStop` | `null` | `setFromStop` | `openPicker` `onSelect` when `mode === 'from'`; `swap()` |
| `RouteFinderScreen` | `toStop` | `null` | `setToStop` | `openPicker` `onSelect` when `mode !== 'from'`; `swap()` |
| `StopCard` | none | – | – | pure/presentational (only `useTheme()` which reads context) |

Derived:
* `canSearch = !!fromStop && !!toStop && fromStop.key !== toStop.key` (used for `disabled`, button bg, icon colour, label colour).
* `value` for the FROM field: `fromStop == null ? undefined : fromStop.name`; for TO: `toStop == null ? undefined : toStop.name`.
* Header `paddingTop: insets.top + SPACING.md` (safe-area aware top only; nothing uses `insets.bottom`/`left`/`right`).

Effects: **none** in `RouteFinderScreen` (no `useEffect`, `useFocusEffect`, `useCallback`, `useMemo`). The only non-`useState` hooks are `useTheme`, `useStatusBarColor(colors.primary)` and `useSafeAreaInsets()`.

---

## 8. Navigation

| Trigger | Call | Params |
|---|---|---|
| Header magnify `Pressable.onPress` | `navigation.navigate('Search')` | none |
| FROM `StopField.onPress` → `openPicker('from')` | `navigation.navigate('StopPicker', {mode:'from', onSelect})` | `mode: 'from'` (string), `onSelect: (stop) => setFromStop(stop)` |
| TO `StopField.onPress` → `openPicker('to')` | `navigation.navigate('StopPicker', {mode:'to', onSelect})` | `mode: 'to'` (string), `onSelect: (stop) => setToStop(stop)` |
| Find Routes `Pressable.onPress` | `navigation.navigate('JourneyResults', {fromKey, toKey, fromName, toName})` | `fromKey: fromStop.key`, `toKey: toStop.key`, `fromName: fromStop.name`, `toName: toStop.name` |

* `navigation.push`, `navigation.setParams`, `navigation.goBack`, `navigation.replace`, `route.params.*` reads: **none** in these modules.
* Consumer contract confirmed: `JourneyResultsScreen` (module 1075) reads `route.params.fromKey`, `.toKey`, `.fromName`, `.toName`; `StopPickerScreen` (module 1073) reads `params.mode` (defaulting to `'from'`) and `params.onSelect`, calls `onSelect(stop)` then `navigation.goBack()`.
* The screen is registered as the **Home tab** (module 557 `BottomTabs`): `<Tab.Screen name="Home" component={RouteFinderScreen} options={{tabBarLabel:'Home', tabBarIcon: focused => MCI(focused ? 'home' : 'home-outline', color, 24)}} />`. The screen itself renders its own header (the stack navigator has `headerShown:false`).

---

## 9. User interactions

| Target | Event | Handler behaviour |
|---|---|---|
| Header magnify `Pressable` | `onPress` | `navigation.navigate('Search')`. Ripple `#FFFFFF30`, `foreground`, `borderless`, `hitSlop: 10`. |
| FROM `StopField` (whole row incl. chevron) | `onPress` (via `Pressable`) | calls `openPicker('from')` → `navigate('StopPicker', {mode:'from', onSelect})`. Ripple `colors.text+'15'`. |
| TO `StopField` (whole row) | `onPress` | `openPicker('to')` → `navigate('StopPicker', {mode:'to', onSelect})`. |
| Swap `Pressable` (32×32 round) | `onPress` (`swap`) | `setFromStop(toStop); setToStop(fromStop);` — swaps the two selected stops in place. Ripple `colors.text+'20'`, `borderless`, `foreground`. |
| Find Routes `Pressable` | `onPress` | `navigation.navigate('JourneyResults', {fromKey,toKey,fromName,toName})`. Ignored when `disabled` (React Native `Pressable` swallows presses when `disabled`). Ripple `colors.text+'15'`. |
| HowItWorks rows | – | no handlers; purely informational. |
| TagChip | – | no handlers. |
| `StopCard` row | `onPress` | forwarded verbatim to the root `Pressable` (caller navigates to `StopDetail`). |
| `StopCard` map button | `onPress` (`onMapPress`) | forwarded verbatim (caller navigates to `Map`). Ripple `colors.text+'50'`, `hitSlop` 30/30/30/30. |

No `onLongPress`, `onChange`, `onChangeText`, `onSubmitEditing`, `focus/blur`, `PanResponder`, pull-to-refresh or scroll listeners exist in these modules.

---

## 10. Validation, empty, loading and error states

* **Validation:** the only validation is `canSearch` (`both stops chosen AND from.key !== to.key`). Selecting the same stop as FROM and TO disables the button.
* **Disabled state visuals:** bg `colors.background`, icon colour `colors.textSecondary`, label colour `colors.textSecondary`, `disabled` = true.
* **Enabled state visuals:** bg `colors.primary + '15'` (theme primary at ~8 % alpha), icon/label `colors.primary`.
* **Empty state:** `fromStop`/`toStop = null` ⇒ placeholders `From — pick a stop` / `To — pick a stop`, `fontWeight '400'`, `colors.textSecondary`.
* **Loading state:** none — no spinners, no async work, no `ActivityIndicator`, all data is local (the screen advertises "Works Offline").
* **Error state:** none — no error boundaries, alerts, toasts or retry UI.
* `StopCard` has no empty/loading/error handling; it always renders the 3-row layout, and hides only the map shortcut when `onMapPress` is undefined.

---

## 11. Scroll behaviour, list rendering, keys, sections

`RouteFinderScreen`:
* Body is a **single React Native `ScrollView`** with `showsVerticalScrollIndicator={false}` and `contentContainerStyle={{paddingBottom: 32}}`.
* The hero header is a sibling **outside** the `ScrollView` ⇒ it is pinned/fixed; only the card + "HOW IT WORKS" section scroll under it.
* Vertical scroll only. No `horizontal` scroll views, no carousels, no `pagingEnabled`, no `onScroll`, no `refreshControl`, no `scrollEventThrottle`.
* No `map()` over an array of data; the 5 chips and 3 rows are **static JSX literals** (no arrays of data, therefore **no `keyExtractor`, no `renderItem`**).
* No `FlatList`/`SectionList`/`VirtualizedList` in module 569.
* Horizontal wrapping behaviour of the chip row is achieved with `flexWrap:'wrap'` + `flexDirection:'row'` + `alignItems:'center'` — chips flow onto multiple lines on narrow screens.

`StopCard`:
* Not a list itself; it is one row. Its only consumer (`RouteDetailScreen`, module 1020) renders it in a `FlatList`:
  * `data` = the route's stop-name array, `keyExtractor` = `` `${selectedStop?.key}-${item}-${index}` ``,
  * `contentContainerStyle={{paddingTop:16, paddingBottom:24}}`,
  * `renderItem` passes `stop: item`, `index: index + 1`, `estimatedTime: route.frequency`, `routeColor`, `isHighlighted: item === selectedStopName`, `onPress` → `navigate('StopDetail', {stopId, stopName})`, `onMapPress` → `navigate('Map', {routeId, focusStopId, color, reversed})`,
  * `onScrollToIndexFailed` → `scrollToOffset({offset: averageItemLength * index, animated:true})`.

---

## 12. Decompiler caveats & colour-conversion notes (read before implementing)

1. **8-digit hex colours.** Several colours are produced by string concatenation of a 6-digit hex and a 2-digit alpha suffix, which React Native accepts:
   * `colors.text + '15'` → `#21212115` (light) / `#EEEEEE15` (dark) — alpha `0x15` = 21/255 ≈ 8.2 %
   * `colors.text + '20'` → `#21212120` ≈ 12.5 % alpha
   * `colors.text + '50'` → `#21212150` ≈ 31.4 % alpha
   * `accent + '18'` → `#F08C0018` / `#2E7D3218` ≈ 9.4 % alpha
   * `colors.primary + '15'` → `#fc3b3815` ≈ 8.2 % alpha
   * `routeColor + '30'` → e.g. `#D6298E30` ≈ 18.8 % alpha
   * `routeColor + '70'` → e.g. `#D6298E70` ≈ 43.9 % alpha
   * `routeColor + '15'` (highlighted card bg) ≈ 8.2 % alpha
   * `#FFFFFF30` (header ripple) ≈ 18.8 % alpha
   * `rgba(255,255,255,0.9)` and `rgba(255,255,255,0.6)` are genuine RGBA strings.
2. `openPicker`'s body was emitted inline at its call sites by hermes-de (see §2.4); treat the two `onPress` handlers as `() => openPicker('from'|'to')`.
3. `_closure0_slot2.default(arr, 2)` + `arr[0]`/`arr[1]` is Babel's array-destructuring helper ⇒ `const [x, setX] = useState(null)`.
4. `value ? … : …` guards compiled from loose equality `fromStop == null` (the dump compares with `null` via `r15 == r3`).
5. `style` props are plain objects everywhere; there is **no `StyleSheet.create`** in these modules, so all style literals must be recreated inline (or as a Flutter `const` style object) with the exact values above.
