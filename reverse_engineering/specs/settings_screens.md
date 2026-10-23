# Lahore Speedo Bus Guide — Settings / Credits / Feedback / ForceUpdate Screens

Implementation-ready specification for a faithful Flutter reimplementation.
Source of truth: hermes-register-machine decompilations of Metro modules in
`reverse_engineering/hermes/app_graph_src/`.

Analysed modules:

| Module file | Module id | Contents |
|---|---|---|
| `m737.js` | 737 | `SettingsScreen`, helpers `SectionHeader`, `Row` |
| `m1081.js` | 1081 | `CreditsScreen`, helper `CreditCard` |
| `m1082.js` | 1082 | `FeedbackScreen`, helpers `FieldLabel`, `inputStyle`, `handleSubmit`, `renderRightIcon` |
| `m1079.js` | 1079 | `ForceUpdateModal` (incl. `onRequestClose`) + `StyleSheet` |
| `m1080.js` | 1080 | Image asset module (`alert`) |
| `m800.js` | 800 | `react-native-screens` compatibility/feature flags (**not** AsyncStorage) |
| `m1315.js` | 1315 | `@react-navigation/stack` re-export barrel (not a screen) |
| `m570.js` | 570 | design tokens `SPACING`, `FONT_SIZE`, `BORDER_RADIUS` |
| `m576.js` | 576 | `COLORS`, `DARK_COLORS` |
| `m571.js` | 571 | `ThemeProvider`, `useTheme` (AsyncStorage persistence) |
| `m577.js` | 577 | `useStatusBarColor` |
| `m572.js` | 572 | AsyncStorage instance (`getLegacyStorage()` / `createAsyncStorage`) |
| `m495.js` | 495 | `AppShell` / `App` — stack + tab navigators, ForceUpdateModal host |
| `m557.js` | 557 | `BottomTabs` — registers the `Settings` tab |
| `m558.js` / `m568.js` | 558 / 568 | `react-native-vector-icons/MaterialCommunityIcons` + glyph map |
| `m1083.js` | 1083 | `@react-native-firebase/firestore` |
| `m1151.js` | 1151 | `react-native-dropdown-picker` |
| `m700.js` | 700 | `react-native-safe-area-context` |

---

## 0. Global conventions and shared design tokens

### 0.1 Tokens — module 570

```
SPACING      = { xs: 4, sm: 8, md: 16, lg: 24, xl: 32, xxl: 48 }
FONT_SIZE    = { xs: 10, sm: 12, md: 14, base: 16, lg: 18, xl: 22, xxl: 28, xxxl: 36 }
BORDER_RADIUS = { sm: 6, md: 10, lg: 16, xl: 24, full: 999 }
```

### 0.2 Palette — module 576

```
COLORS (light)      = {
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

`primary` is identical in both themes (`#fc3b38`).

### 0.3 Alpha-suffixed colour convention

The app builds translucent colours by **string concatenation** of a hex colour with a
two-digit alpha suffix (not `rgba()`). The suffix values used are `'10'`, `'12'`, `'15'`,
`'18'`, `'20'`, `'30'`, `'50'`, `'80'` — i.e. 8-digit `#RRGGBBAA` with alpha 6 %, 7 %,
8 %, 9 %, 13 %, 19 %, 31 %, 50 % respectively. Examples: `colors.primary + '15'`
→ `#fc3b3815`; `colors.text + '10'` → `#21212110`; `colors.primary + '80'` → `#fc3b3880`.
In the Credits screen the accent hexes are `#12B886` (teal) and `#F59F00` (amber).

### 0.4 `useTheme()` — module 571

Returns `{ colors, isDark, toggleTheme, preference, setThemePreference }`.

* `colors` = `isDark ? DARK_COLORS : COLORS`.
* `preference` state initial value `'system'`; on mount `AsyncStorage.getItem('themePreference')`
  is read; the value is only accepted if it is exactly `'light'`, `'dark'` or `'system'`.
* `isDark` = `preference === 'dark' ? true : systemColorScheme === 'dark'`
  (i.e. when `preference` is `'system'`, `isDark` follows `Appearance.getColorScheme()`).
* `toggleTheme()` = `setThemePreference(isDark ? 'light' : 'dark')`.
* `setThemePreference(v)` writes `AsyncStorage.setItem('themePreference', v)` and swallows errors.
* An `Appearance.addChangeListener` updates the system scheme.

### 0.5 `useStatusBarColor(color, barStyle = 'light-content', animated = true)` — module 577

Runs inside `@react-navigation/core`'s `useFocusEffect` + `useCallback([color, barStyle, animated])`:
on focus it calls `StatusBar.setBarStyle(barStyle, animated)` and
`StatusBar.setBackgroundColor(color, animated)`.
All four screens call it with **only** the colour argument (so barStyle is `'light-content'`).

### 0.6 Icons — module 558 / 568

All icons in these modules come from **`react-native-vector-icons/MaterialCommunityIcons`**
(the module has a `default` export that is the icon component, props `name`, `size`, `color`,
optional `style`). Glyph codepoints were confirmed against the module-568 glyph map
(e.g. `white-balance-sunny` = 984488, `weather-night` = 984468, `web` = 984479,
`shield-check-outline` = 986312, `open-in-new` exists, `chevron-right` exists,
`send` = 984202, `code-tags` exists, `arrow-left` exists, `chevron-left` exists,
`bus` exists).
**No `MaterialIcons` and no `Ionicons` icons are used by any of the four screens.**

### 0.7 Navigation primitives

`SafeAreaView` from `react-native-safe-area-context` (module 700),
`Modal/View/Text/Image/Pressable/ScrollView/TouchableOpacity/Switch/KeyboardAvoidingView/
TextInput/ActivityIndicator/Alert/BackHandler/Linking/StyleSheet` from `react`-native core
(module 2), `Linking.openURL(url)` for external links, `Alert.alert(title, message, buttons)`.

---

# 1. `SettingsScreen` (module 737) — the "Settings" tab

## 1.1 Module-level constants (verbatim)

| Slot | Value |
|---|---|
| `WEBSITE_URL` | `'https://theislam313.vercel.app'` |
| `SUPPORT_EMAIL` | `'bilaliqbal883s@gmail.com'` |
| `PRIVACY_URL` | `'https://codez-android.netlify.app'` |
| `OFFICIAL_SOURCES` | `[{ name: 'Punjab Mass Transit Authority', domain: 'etransit.punjab.gov.pk', url: 'https://etransit.punjab.gov.pk', icon: 'bus' }]` (exactly **1** entry) |
| `DISCLAIMER` | `'This app is an independent, community-built app. It is not affiliated with, endorsed by, or operated by any government body, Lahore Transport Company (LTC), or Punjab Mass Transit Authority (PMTA).'` |

Default export: `SettingsScreen`. No named exports.

## 1.2 Component signatures

### `SectionHeader({ icon, label, colors })`

Props (declared order): `icon` (string), `label` (string), `colors` (theme colours object).
Renders a row: icon (MaterialCommunityIcons, size 18, colour `colors.primary`,
`style={{ marginRight: SPACING.xs }}`) followed by the label `Text`.
No press behaviour.

### `Row({ icon, title, subtitle = '', onPress, external = false, colors })`

Props (declared order): `icon`, `title`, `subtitle` (defaults to `''`), `onPress`,
`external` (defaults to `false`), `colors`.

* Root is a `Pressable` with `android_ripple={{ color: colors.text + '10', foreground: true }}`,
  `onPress` passthrough, `overflow: 'hidden'`.
* Trailing icon is `external ? 'open-in-new' : 'chevron-right'` (MaterialCommunityIcons,
  size 21, colour `colors.textSecondary`).
* The `subtitle` `Text` is rendered **only when `subtitle` is truthy** (conditional
  `subtitle ? <Text …/> : null`); no placeholder is rendered when empty.

### `SettingsScreen({ navigation })`

* `const { colors, isDark, toggleTheme } = useTheme();`
* `useStatusBarColor(colors.primary);`
* No local state, no `useCallback`, no storage access of its own.

## 1.3 Exact UI tree (top → bottom)

```
SafeAreaView                       style={ flex:1, backgroundColor: colors.background }   edges={['top']}
├─ View  (header)                 style={ backgroundColor: colors.primary,
│                                        paddingHorizontal: SPACING.md /*16*/,
│                                        paddingTop: SPACING.md /*16*/,
│                                        paddingBottom: SPACING.lg /*24*/ }
│  ├─ Text  'Settings'            style={ fontSize: FONT_SIZE.xxl /*28*/, fontWeight:'800', color:'#fff' }
│  └─ Text  'Manage your preferences'
│                                 style={ fontSize: FONT_SIZE.lg /*18*/, fontWeight:'600',
│                                         color:'rgba(255,255,255,0.9)' }
└─ ScrollView                     contentContainerStyle={ padding: SPACING.md /*16*/,
│                                                          paddingBottom: SPACING.xl /*32*/ }   (no showsVerticalScrollIndicator prop)
   ├─ TouchableOpacity  (Dark Mode row)   activeOpacity={0.9}   onPress={toggleTheme}
   │    style={ backgroundColor: colors.card, borderRadius: BORDER_RADIUS.lg /*16*/,
   │            overflow:'hidden' }
   │  └─ View               style={ flexDirection:'row', alignItems:'center', padding: SPACING.md /*16*/ }
   │     ├─ View (icon chip)   style={ width:38, height:38, borderRadius: BORDER_RADIUS.md /*10*/,
   │     │                            backgroundColor: colors.primary + '15',
   │     │                            alignItems:'center', justifyContent:'center',
   │     │                            marginRight: SPACING.sm /*8*/ }
   │     │  └─ MaterialCommunityIcons  name={ isDark ? 'weather-night' : 'white-balance-sunny' }
   │     │                                size={20}  color={colors.primary}
   │     ├─ View  style={ flex:1 }
   │     │  ├─ Text 'Dark Mode'   style={ fontSize: FONT_SIZE.base /*16*/, fontWeight:'700',
   │     │  │                            color: colors.text }
   │     │  └─ Text { isDark ? 'Currently on' : 'Currently off' }
   │     │                       style={ fontSize: FONT_SIZE.sm /*12*/, color: colors.textSecondary,
   │     │                               marginTop: 2 }
   │     └─ Switch  value={isDark}  onValueChange={toggleTheme}
   │                trackColor={{ false: colors.border, true: colors.primary + '80' }}
   │                thumbColor={ isDark ? colors.primary : '#FFFFFF' }
   │
   ├─ View  (disclaimer card)  style={ backgroundColor: colors.primary + '12',
   │                                  borderRadius: BORDER_RADIUS.md /*10*/,
   │                                  padding: SPACING.md /*16*/,
   │                                  marginTop: SPACING.lg /*24*/,
   │                                  borderLeftColor: colors.primary }
   │  │   ⚠ NOTE: `borderLeftWidth` is NOT set, so on React Native the left border is not
   │  │   actually painted. Reimplement either with the same omission or add a 4px left border
   │  │   for visual fidelity of intent.
   │  └─ View               style={ flexDirection:'row', alignItems:'center',
   │                               marginBottom: SPACING.xs /*4*/ }
   │     ├─ MaterialCommunityIcons  name='information'  size={18}  color={colors.primary}
   │     │                          style={{ marginRight: SPACING.xs /*4*/ }}
   │     └─ Text 'Unofficial App'  style={ fontSize: FONT_SIZE.base /*16*/, fontWeight:'800',
   │                                       color: colors.primary }
   │     └─ Text  {DISCLAIMER}     style={ fontSize: FONT_SIZE.md /*14*/, color: colors.text,
   │                                        lineHeight: 21 }      ← sibling of the inner View
   │
   ├─ SectionHeader  icon='email-outline'        label='Contact & Support'   colors={colors}
   ├─ Row            icon='web'
   │                 title='Visit our Website'
   │                 subtitle={ WEBSITE_URL.replace('https://','') }   →  'theislam313.vercel.app'
   │                 onPress={ () => Linking.openURL('https://theislam313.vercel.app') }
   │                 external={true}       colors={colors}
   ├─ Row            icon='help-circle-outline'
   │                 title='Help & Support'
   │                 subtitle='bilaliqbal883s@gmail.com'
   │                 onPress={ () => Linking.openURL('mailto:bilaliqbal883s@gmail.com') }
   │                 colors={colors}          (external defaults to false → 'chevron-right')
   ├─ Row            icon='message-alert-outline'
   │                 title='Send Feedback'
   │                 subtitle='Complaint, suggestion, bug report & more'
   │                 onPress={ () => navigation.navigate('Feedback') }
   │                 colors={colors}          (external defaults to false → 'chevron-right')
   ├─ SectionHeader  icon='shield-check-outline'  label='Legal'           colors={colors}
   ├─ Row            icon='shield-check-outline'
   │                 title='Privacy Policy'
   │                 subtitle = ''  (not supplied → not rendered)
   │                 onPress={ () => Linking.openURL('https://codez-android.netlify.app') }
   │                 external={true}       colors={colors}
   ├─ SectionHeader  icon='web'                  label='Official Sources'  colors={colors}
   └─ { OFFICIAL_SOURCES.map( s => (
         <Row key={s.url}
              icon={s.icon}                 → 'bus'
              title={s.name}                → 'Punjab Mass Transit Authority'
              subtitle={s.domain}           → 'etransit.punjab.gov.pk'
              onPress={ () => Linking.openURL(s.url) }
              external={true} colors={colors} /> ) ) }
```

### `SectionHeader` / `Row` detailed styles (for reuse)

`SectionHeader` outer `View` style:
`{ flexDirection:'row', alignItems:'center', marginBottom: SPACING.sm /*8*/, marginTop: SPACING.lg /*24*/ }`
Icon: name from prop, `size:18`, `color: colors.primary`, `style:{ marginRight: SPACING.xs /*4*/ }`.
Label `Text`: `{ fontSize: FONT_SIZE.lg /*18*/, fontWeight:'800', color: colors.text }`.

`Row` root `Pressable` style:
`{ flexDirection:'row', alignItems:'center', backgroundColor: colors.card,`
`borderRadius: BORDER_RADIUS.lg /*16*/, padding: SPACING.md /*16*/, marginBottom: SPACING.sm /*8*/,`
`overflow:'hidden' }`

`Row` icon chip `View`: `{ width:38, height:38, borderRadius: BORDER_RADIUS.md /*10*/,`
`backgroundColor: colors.primary + '15', alignItems:'center', justifyContent:'center',`
`marginRight: SPACING.sm /*8*/ }` — inner icon `size:21`, `color: colors.primary`.

`Row` body `View`: `{ flex:1 }`.
Title `Text`: `{ fontSize: FONT_SIZE.base /*16*/, fontWeight:'700', color: colors.text }`.
Subtitle `Text`: `{ fontSize: FONT_SIZE.md /*14*/, color: colors.textSecondary, marginTop:2 }`.
Trailing icon: `size:21`, `color: colors.textSecondary`.

## 1.4 Every literal string shown to the user (SettingsScreen)

| String | Where |
|---|---|
| `Settings` | header title |
| `Manage your preferences` | header subtitle |
| `Dark Mode` | row title |
| `Currently on` | row subtitle when `isDark === true` |
| `Currently off` | row subtitle when `isDark === false` |
| `Unofficial App` | disclaimer card heading |
| `This app is an independent, community-built app. It is not affiliated with, endorsed by, or operated by any government body, Lahore Transport Company (LTC), or Punjab Mass Transit Authority (PMTA).` | disclaimer body |
| `Contact & Support` | section header |
| `Visit our Website` | row title |
| `theislam313.vercel.app` | row value (subtitle) |
| `Help & Support` | row title |
| `bilaliqbal883s@gmail.com` | row value (subtitle) |
| `Send Feedback` | row title |
| `Complaint, suggestion, bug report & more` | row value (subtitle) |
| `Legal` | section header |
| `Privacy Policy` | row title |
| `Official Sources` | section header |
| `Punjab Mass Transit Authority` | official-source row title |
| `etransit.punjab.gov.pk` | official-source row value |

**No version string, no build number and no "Rate us"/"Share app"/"Clear cache" row exist
in this screen.**

## 1.5 Row-by-row tap behaviour (incl. exact URLs)

| # | Icon (MaterialCommunityIcons) | Label | Value shown | Tap behaviour |
|---|---|---|---|---|
| 1 | `white-balance-sunny` (light) / `weather-night` (dark), size 20 | `Dark Mode` | `Currently off` / `Currently on` + a `Switch` | Whole row is a `TouchableOpacity` (`activeOpacity 0.9`) calling `toggleTheme()` — switches `preference` between `'light'` and `'dark'` and persists `themePreference`. The `Switch` calls the same `toggleTheme`. No navigation. |
| 2 | `information`, size 18 | `Unofficial App` | disclaimer paragraph | Not pressable |
| 3 | `email-outline` | `Contact & Support` | — | Section header, not pressable |
| 4 | `web`, size 21, trailing `open-in-new` | `Visit our Website` | `theislam313.vercel.app` | `Linking.openURL('https://theislam313.vercel.app')` |
| 5 | `help-circle-outline`, size 21, trailing `chevron-right` | `Help & Support` | `bilaliqbal883s@gmail.com` | `Linking.openURL('mailto:bilaliqbal883s@gmail.com')` |
| 6 | `message-alert-outline`, size 21, trailing `chevron-right` | `Send Feedback` | `Complaint, suggestion, bug report & more` | `navigation.navigate('Feedback')` |
| 7 | `shield-check-outline` | `Legal` | — | Section header |
| 8 | `shield-check-outline`, size 21, trailing `open-in-new` | `Privacy Policy` | (none) | `Linking.openURL('https://codez-android.netlify.app')` |
| 9 | `web` | `Official Sources` | — | Section header |
| 10 | `bus`, size 21, trailing `open-in-new` | `Punjab Mass Transit Authority` | `etransit.punjab.gov.pk` | `Linking.openURL('https://etransit.punjab.gov.pk')` |

## 1.6 Toggles / switches

Exactly one switch: RN `Switch`, `value = isDark`, `onValueChange = toggleTheme`,
`trackColor = { false: colors.border, true: colors.primary + '80' }`,
`thumbColor = isDark ? colors.primary : '#FFFFFF'`.
State lives in `ThemeProvider` (`preference`: `'system' | 'light' | 'dark'`), persisted to
AsyncStorage under `themePreference`.

## 1.7 Where the screen is hosted

`Settings` is a **bottom-tab** screen (`id: 'BottomTabs'`, screen name `'Settings'`,
component = module 737), 4th and last tab. Tab options:
`tabBarLabel: 'Settings'`, `tabBarIcon` = MaterialCommunityIcons
`focused ? 'cog' : 'cog-outline'`, `size: 24`, `color` = tab colour.
The tab bar itself (`BottomNavigation.Bar` from module 848) is configured with
`compact: true`, `activeColor: colors.primary`, `inactiveColor: colors.textSecondary`,
`style: { backgroundColor: colors.card, borderTopWidth: 1, borderTopColor: colors.border }`,
`activeIndicatorStyle: { backgroundColor: colors.primary + '20' }`.
There is **no** stack screen named `Settings`; the screen is not reachable by
`navigation.navigate('Settings')` from outside the tab navigator.

---

# 2. `CreditsScreen` (module 1081)

## 2.1 Module-level data (verbatim)

`CREDITS` — array of exactly **2** objects (declared order of keys: `role`, `icon`,
`accent`, `name`, `description`, `tags`, `linkLabel`, `linkUrl`):

```
[0] role        : 'FOUNDER & DEVELOPER'
    icon        : 'code-tags'
    accent      : '#12B886'
    name        : 'Muhammad Awais'
    description : 'Designed and built Lahore Speedo App — the web and mobile apps and the transit data behind them.'
    tags        : ['Product & Design', 'Web & Mobile Apps', 'Routing & Data']
    linkLabel   : 'Connect on LinkedIn'
    linkUrl     : 'https://www.linkedin.com/in/awais882s'

[1] role        : 'Software Engineer'
    icon        : 'code-tags'
    accent      : '#F59F00'
    name        : 'Muhammad Bilal'
    description : 'Designed and built Lahore Speedo App — the web and mobile apps and the transit data behind them.'   (identical text to [0])
    tags        : ['Product & Design', 'Web & Mobile Apps', 'Routing & Data']                                             (identical to [0])
    linkLabel   : 'Connect on LinkedIn'
    linkUrl     : 'https://www.linkedin.com/in/muhammadbilaliqbal'
```

Default export: `CreditsScreen`. No named exports.

## 2.2 Component signatures

### `CreditCard({ item, colors })`

Props (declared order): `item` (one `CREDITS` entry), `colors`.

### `CreditsScreen({ navigation })`

`const { colors } = useTheme();` then `useStatusBarColor(colors.primary);`
(`isDark`/`toggleTheme` are **not** consumed).
Renders `CREDITS.map(item => <CreditCard key={item.name} item={item} colors={colors} />)`.

## 2.3 Exact UI tree

```
SafeAreaView                    style={ flex:1, backgroundColor: colors.background }   edges={['top']}
└─ View  (header)               style={ backgroundColor: colors.primary,
                                       paddingHorizontal: SPACING.md /*16*/,
                                       paddingTop: SPACING.md /*16*/,
                                       paddingBottom: SPACING.lg /*24*/,
                                       flexDirection:'row', alignItems:'center' }
   ├─ Pressable (back)          android_ripple={{ color:'#FFFFFF30', foreground:true, borderless:true }}
   │                            onPress={ () => navigation.goBack() }
   │                            style={ width:36, height:36, borderRadius: BORDER_RADIUS.full /*999*/,
   │                                    backgroundColor:'rgba(255,255,255,0.15)',
   │                                    alignItems:'center', justifyContent:'center',
   │                                    marginRight: SPACING.sm /*8*/ }
   │  └─ MaterialCommunityIcons  name='chevron-left'  size={22}  color='#fff'
   └─ Text 'Credits'            style={ fontSize: FONT_SIZE.xl /*22*/, fontWeight:'800', color:'#fff' }
└─ ScrollView                   contentContainerStyle={ padding: SPACING.md /*16*/,
                                                         paddingBottom: SPACING.xl /*32*/ }
   └─ CreditCard × 2   (key = item.name)
```

### `CreditCard` detailed tree and styles

```
View (card)                 style={ backgroundColor: colors.card,
                                  borderRadius: BORDER_RADIUS.lg /*16*/,
                                  padding: SPACING.lg /*24*/,
                                  marginBottom: SPACING.md /*16*/,
                                  elevation: 1 }                       // Android elevation only, no shadow* props
└─ View (top row)           style={ flexDirection:'row', alignItems:'center',
                                    marginBottom: SPACING.md /*16*/ }
   ├─ View (avatar)         style={ width:44, height:44, borderRadius: BORDER_RADIUS.full /*999*/,
   │                              backgroundColor: item.accent + '20',
   │                              alignItems:'center', justifyContent:'center',
   │                              marginRight: SPACING.sm /*8*/ }
   │  └─ MaterialCommunityIcons  name={item.icon}  size={22}  color={item.accent}
   └─ View (role badge)     style={ backgroundColor: item.accent + '18',
                                    paddingHorizontal: SPACING.sm /*8*/,
                                    paddingVertical: 4,
                                    borderRadius: BORDER_RADIUS.full /*999*/ }
      └─ Text {item.role}   style={ color: item.accent, fontSize: FONT_SIZE.xs /*10*/,
                                    fontWeight:'800', letterSpacing: 0.5 }
├─ Text {item.name}         style={ fontSize: FONT_SIZE.xl /*22*/, fontWeight:'800',
                                    color: colors.text, marginBottom: SPACING.xs /*4*/ }
├─ Text {item.description}  style={ fontSize: FONT_SIZE.md /*14*/, color: colors.textSecondary,
                                    lineHeight: 21, marginBottom: SPACING.md /*16*/ }
├─ View (tags)              style={ flexDirection:'row', flexWrap:'wrap',
                                    marginBottom: SPACING.md /*16*/ }
│  └─ View (tag chip) × 3   key={tag}
│        style={ backgroundColor: item.accent + '15',
│                paddingHorizontal: SPACING.sm /*8*/, paddingVertical: 5,
│                borderRadius: BORDER_RADIUS.full /*999*/,
│                marginRight: SPACING.xs /*4*/, marginBottom: SPACING.xs /*4*/ }
│     └─ Text {tag}  style={ color: item.accent, fontSize: FONT_SIZE.sm /*12*/,
│                            fontWeight:'600' }
└─ Pressable (link)         android_ripple={{ color: item.accent + '30', foreground:true }}
                            onPress={ () => Linking.openURL(item.linkUrl) }
                            style={ backgroundColor: item.accent + '18',
                                    borderRadius: BORDER_RADIUS.md /*10*/,
                                    paddingVertical: SPACING.sm + 2  /* = 10 */,
                                    alignItems:'center', flexDirection:'row',
                                    justifyContent:'center', overflow:'hidden' }
   ├─ Text {item.linkLabel} style={ color: item.accent, fontWeight:'700',
   │                               fontSize: FONT_SIZE.base /*16*/,
   │                               marginRight: SPACING.xs /*4*/ }
   └─ MaterialCommunityIcons  name='chevron-right'  size={18}  color={item.accent}
```

## 2.4 Every literal string (CreditsScreen)

| String | Source |
|---|---|
| `Credits` | header title |
| `FOUNDER & DEVELOPER` | card 1 role badge |
| `Software Engineer` | card 2 role badge |
| `Muhammad Awais` | card 1 name |
| `Muhammad Bilal` | card 2 name |
| `Designed and built Lahore Speedo App — the web and mobile apps and the transit data behind them.` | both cards' description (note the em-dash `—`) |
| `Product & Design` | tag (both cards) |
| `Web & Mobile Apps` | tag (both cards) |
| `Routing & Data` | tag (both cards) |
| `Connect on LinkedIn` | both cards' link label |

## 2.5 Links

| Card | Link label | URL opened |
|---|---|---|
| Muhammad Awais | `Connect on LinkedIn` | `https://www.linkedin.com/in/awais882s` |
| Muhammad Bilal | `Connect on LinkedIn` | `https://www.linkedin.com/in/muhammadbilaliqbal` |

## 2.6 Notes / gaps

* The screen shows **no** app version, no "made in Lahore" footer, no license text.
* `Credits` is registered as a screen in the root stack (`name: 'Credits'`, see §10) but
  **no `navigation.navigate('Credits')` call exists in any analysed module** — the screen is
  currently unreachable from the UI (dead route). The reimplementation should keep the route
  and, for parity, no entry point.
* No AsyncStorage / Firebase / Linking other than the two LinkedIn URLs.

---

# 3. `FeedbackScreen` (module 1082)

## 3.1 Module-level data (verbatim)

`FEEDBACK_TYPES` (declared order; used as `data` for the Dropdown, `labelField:'label'`,
`valueField:'value'`):

```
[0] { label: 'Complaint',                    value: 'complaint' }
[1] { label: 'Suggestion',                   value: 'suggestion' }
[2] { label: 'Feature Request',              value: 'feature_request' }
[3] { label: 'Bug Report',                   value: 'bug_report' }
[4] { label: 'Route / Stop Data Correction', value: 'data_correction' }
[5] { label: 'Other',                        value: 'other' }
```

Default export: `FeedbackScreen`. Helpers `FieldLabel`, `inputStyle` are module-private
(not exported).

## 3.2 Component signatures / helpers

### `FieldLabel({ text, colors, required })`

Props (declared order): `text` (string), `colors`, `required` (boolean).
Renders a single `Text` whose children are the array `[text, required ? ' *' : '']`
(i.e. a literal space + asterisk appended when required, no separate red asterisk element).

```
Text style = { fontSize: FONT_SIZE.sm /*12*/, fontWeight:'700',
               color: colors.textSecondary,
               marginBottom: SPACING.xs /*4*/,
               marginTop: SPACING.md /*16*/ }
```

### `inputStyle(colors)`

Returns exactly:

```
{
  backgroundColor:   colors.card,
  borderWidth:       1,
  borderColor:       colors.border,
  borderRadius:      BORDER_RADIUS.md /*10*/,
  paddingHorizontal: SPACING.md /*16*/,
  paddingVertical:   SPACING.sm + 4   /* 8 + 4 = 12 */,
  fontSize:          FONT_SIZE.base /*16*/,
  color:             colors.text,
}
```

The multiline comment field reuses this object and adds `minHeight: 120`.

### `handleSubmit` (async, created via `asyncGeneratorStep` trampoline, held in a closure slot)

```
if (!isValid) return;                       // early return, no alert
setSubmitting(true);
try {
  await addDoc( collection( getFirestore(), 'feedback' ), {
    name:      name.trim(),
    email:     email.trim(),
    location:  location.trim(),
    type:      type,                 // raw value, NOT trimmed (null until a choice is made)
    comment:   comment.trim(),
    platform: 'android',
    createdAt: serverTimestamp(),
  } );
  Alert.alert('Thank you!', 'Your feedback has been sent.',
              [ { text: 'OK', onPress: () => navigation.goBack() } ]);
} catch (e) {
  Alert.alert('Could not send feedback',
              (e == null ? undefined : e.message) || 'Please check your connection and try again.');
} finally {
  setSubmitting(false);
}
```

The `Alert` used is the core `react-native` `Alert` (module 2). `getFirestore`, `addDoc`,
`collection`, `serverTimestamp` come from `@react-native-firebase/firestore` (module 1083),
so the write is a **top-level Firestore collection**, no sub-collection, no auth uid,
no device id, no app version.

### `renderRightIcon()` (Dropdown)

Returns `<MaterialCommunityIcons name='chevron-down' size={20} color={colors.textSecondary} />`.

### `FeedbackScreen({ navigation })`

State (declared order), all via `useState` + array-destructuring:

| State | Initial | Setter |
|---|---|---|
| `name` | `''` | `setName` |
| `email` | `''` | `setEmail` |
| `location` | `''` | `setLocation` |
| `type` | `null` | `setType` |
| `comment` | `''` | `setComment` |
| `submitting` | `false` | `setSubmitting` |

Derived values (recomputed on every render):

```
emailValid = /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email.trim())

isValid = name.trim().length > 0
        && email.trim().length > 0
        && emailValid
        && location.trim().length > 0
        && comment.trim().length > 0
        && type != null          // i.e. Boolean(type)
        && !submitting
```

## 3.3 Exact UI tree

```
SafeAreaView                  style={ flex:1, backgroundColor: colors.background }  edges={['top']}
└─ View  (header)             style={ backgroundColor: colors.primary,
                                     paddingHorizontal: SPACING.md /*16*/,
                                     paddingTop: SPACING.sm /*8*/,
                                     paddingBottom: SPACING.md /*16*/,
                                     flexDirection:'row', alignItems:'center' }
   ├─ Pressable (back)        android_ripple={{ color:'#FFFFFF50', foreground:true }}
   │                          onPress={ () => navigation.goBack() }
   │                          style={ height:35, width:35, justifyContent:'center',
   │                                  alignItems:'center', borderRadius: BORDER_RADIUS.md /*10*/,
   │                                  overflow:'hidden', marginRight: SPACING.xs /*4*/ }
   │  └─ MaterialCommunityIcons  name='arrow-left'  size={22}  color='#fff'
   └─ View   (no style prop at all — plain grouping View)
      ├─ Text 'Send Feedback'     style={ fontSize: FONT_SIZE.xl /*22*/, fontWeight:'800',
      │                                  color:'#fff' }
      └─ Text 'We read every message'  style={ fontSize: FONT_SIZE.sm /*12*/,
                                                color:'rgba(255,255,255,0.85)' }
└─ KeyboardAvoidingView       style={ flex:1 }   behavior={ undefined }   ← RN default
                                                    ('padding' on iOS) — no Platform check in code
   └─ ScrollView              contentContainerStyle={ padding: SPACING.md /*16*/,
                                                      paddingBottom: SPACING.xl /*32*/ }
                              keyboardShouldPersistTaps='handled'
      ├─ [0]  FieldLabel  text='Your Name'  colors={colors}  required={true}
      ├─ [1]  TextInput   value={name}  onChangeText={setName}
      │                  placeholder='enter your name'
      │                  placeholderTextColor={colors.textSecondary}
      │                  style={ inputStyle(colors) }
      ├─ [2]  FieldLabel  text='Email'  colors={colors}  required={true}
      ├─ [3]  TextInput   value={email}  onChangeText={setEmail}
      │                  placeholder='enter your email'
      │                  placeholderTextColor={colors.textSecondary}
      │                  keyboardType='email-address'
      │                  autoCapitalize='none'
      │                  style={ inputStyle(colors) }
      ├─ [4]  { !emailValid && <Text style={{ color:'#C62828', fontSize: FONT_SIZE.sm /*12*/,
      │                                     marginTop: 4 }}>Enter a valid email address.</Text> }
      │        (nothing rendered when emailValid — no empty placeholder node)
      ├─ [5]  FieldLabel  text='Location'  colors={colors}  required={true}
      ├─ [6]  TextInput   value={location}  onChangeText={setLocation}
      │                  placeholder='enter your location'
      │                  placeholderTextColor={colors.textSecondary}
      │                  style={ inputStyle(colors) }        (default keyboard, no autoCapitalize override)
      ├─ [7]  FieldLabel  text='Type'  colors={colors}  required={true}
      ├─ [8]  Dropdown    (react-native-dropdown-picker)
      │        style               = { ...inputStyle(colors), justifyContent:'center' }
      │        containerStyle      = { backgroundColor: colors.card,
      │                                borderRadius: BORDER_RADIUS.md /*10*/,
      │                                borderColor: colors.border }
      │        itemContainerStyle  = { borderRadius: BORDER_RADIUS.sm /*6*/ }
      │        activeColor         = colors.primary + '15'
      │        placeholderStyle    = { color: colors.textSecondary, fontSize: FONT_SIZE.base /*16*/ }
      │        selectedTextStyle   = { color: colors.text, fontSize: FONT_SIZE.base /*16*/ }
      │        itemTextStyle       = { color: colors.text, fontSize: FONT_SIZE.base /*16*/ }
      │        data                = FEEDBACK_TYPES   (6 items, see §3.1)
      │        labelField          = 'label'
      │        valueField          = 'value'
      │        placeholder         = 'Select a type'
      │        value               = type
      │        onChange            = (item) => setType(item.value)
      │        renderRightIcon     = () => <MaterialCommunityIcons name='chevron-down'
      │                                        size={20} color={colors.textSecondary} />
      ├─ [9]  FieldLabel  text='Comment'  colors={colors}  required={true}
      ├─ [10] TextInput   value={comment}  onChangeText={setComment}
      │                  placeholder="Tell us what's going on…"      ← U+2026 horizontal ellipsis
      │                  placeholderTextColor={colors.textSecondary}
      │                  multiline={true}
      │                  numberOfLines={6}
      │                  textAlignVertical='top'
      │                  style={ ...inputStyle(colors), minHeight: 120 }
      ├─ [11] Pressable (submit)  android_ripple={{ color:'#FFFFFF50', foreground:true }}
      │        onPress={handleSubmit}
      │        disabled={ !isValid }
      │        style={ flexDirection:'row', alignItems:'center', justifyContent:'center',
      │                backgroundColor: isValid ? colors.primary : colors.border,
      │                borderRadius: BORDER_RADIUS.lg /*16*/,
      │                paddingVertical: SPACING.md /*16*/,
      │                marginTop: SPACING.lg /*24*/,
      │                overflow:'hidden' }
      │        └─ { submitting
      │             ? <ActivityIndicator color='#fff' />
      │             : <>
      │                 <MaterialCommunityIcons name='send' size={18} color='#fff'
      │                                        style={{ marginRight: SPACING.xs /*4*/ }} />
      │                 <Text style={{ color:'#fff', fontWeight:'800',
      │                                fontSize: FONT_SIZE.base /*16*/ }}>Submit</Text>
      │               </> }
      └─ [12] Text 'Fields marked * are required.'
                 style={ color: colors.textSecondary, fontSize: FONT_SIZE.xs /*10*/,
                         textAlign:'center', marginTop: SPACING.md /*16*/ }
```

## 3.4 Field list — order, labels, placeholders, keyboard, required

| # | Label (exact) | Required marker | Placeholder (exact) | keyboardType | Other input props | State key |
|---|---|---|---|---|---|---|
| 1 | `Your Name` | `' *'` appended | `enter your name` | default | — | `name` |
| 2 | `Email` | `' *'` appended | `enter your email` | `email-address` | `autoCapitalize: 'none'` | `email` |
| 3 | `Location` | `' *'` appended | `enter your location` | default | — | `location` |
| 4 | `Type` | `' *'` appended | `Select a type` (Dropdown placeholder) | — | dropdown, single-select | `type` (initial `null`) |
| 5 | `Comment` | `' *'` appended | `Tell us what's going on…` | default | `multiline: true`, `numberOfLines: 6`, `textAlignVertical: 'top'`, `minHeight: 120` | `comment` |

All five fields are marked required (all five `FieldLabel` calls pass `required={true}`).
`placeholderTextColor` is `colors.textSecondary` on all four `TextInput`s.

## 3.5 Validation rules and error messages

| Rule | Expression | Error message shown | Where |
|---|---|---|---|
| Name required | `name.trim().length > 0` | **none** (submit simply disabled) | — |
| Email required | `email.trim().length > 0` | **none** | — |
| Email format | `/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email.trim())` | `Enter a valid email address.` | inline `Text` under the email input, rendered **only when invalid** |
| Location required | `location.trim().length > 0` | **none** | — |
| Comment required | `comment.trim().length > 0` | **none** | — |
| Type required | `type != null` | **none** | — |
| Not submitting | `!submitting` | — | disables button while in flight |

Error text style: `{ color: '#C62828', fontSize: FONT_SIZE.sm /*12*/, marginTop: 4 }`.
There is no red border on invalid inputs, no per-field error text other than the email one,
and no `onSubmitEditing`/return-key chaining. The only other user-visible helper text is
`Fields marked * are required.`

## 3.6 Submit behaviour

1. Button is a `Pressable` with `disabled = !isValid` and background
   `colors.primary` when valid, `colors.border` when invalid.
2. On press with valid data and `submitting === false`: `submitting` becomes `true` and the
   button content is replaced by a single `<ActivityIndicator color='#fff' />` (the send icon
   and the `Submit` label disappear while in flight).
3. Firestore write — **collection name: `feedback`** (top-level, no parent path), document
   fields (declared order):

   | Field | Value | Notes |
   |---|---|---|
   | `name` | `name.trim()` | |
   | `email` | `email.trim()` | |
   | `location` | `location.trim()` | |
   | `type` | `type` | raw dropdown **value** (`'complaint'`, `'suggestion'`, `'feature_request'`, `'bug_report'`, `'data_correction'`, `'other'`) |
   | `comment` | `comment.trim()` | |
   | `platform` | `'android'` | hard-coded string |
   | `createdAt` | `serverTimestamp()` | Firestore server timestamp sentinel |

   The document id is Firestore-generated (`addDoc`). No analytics, no duplicate guard, no
   rate limit, no retry.
4. **Success**: `Alert.alert('Thank you!', 'Your feedback has been sent.', [{ text: 'OK', onPress: () => navigation.goBack() }])`
   — one button, `OK`; pressing it (or dismissing) leaves `submitting` `false` and pops the screen.
   The form is **not** cleared on success (the `OK` press navigates back instead).
5. **Failure**: `Alert.alert('Could not send feedback', e?.message ?? 'Please check your connection and try again.')`
   — no buttons (default dismiss only).
6. There is no success `Toast`, no snackbar, no inline success state.

## 3.7 Every literal string (FeedbackScreen)

| String | Where |
|---|---|
| `Send Feedback` | header title |
| `We read every message` | header subtitle |
| `Your Name` | field 1 label |
| `enter your name` | field 1 placeholder |
| `Email` | field 2 label |
| `enter your email` | field 2 placeholder |
| `Enter a valid email address.` | field 2 inline error |
| `Location` | field 3 label |
| `enter your location` | field 3 placeholder |
| `Type` | field 4 label |
| `Select a type` | field 4 dropdown placeholder |
| `Complaint` | dropdown option 1 label |
| `Suggestion` | dropdown option 2 label |
| `Feature Request` | dropdown option 3 label |
| `Bug Report` | dropdown option 4 label |
| `Route / Stop Data Correction` | dropdown option 5 label |
| `Other` | dropdown option 6 label |
| `complaint` / `suggestion` / `feature_request` / `bug_report` / `data_correction` / `other` | dropdown option values (also the persisted `type` field) |
| `Comment` | field 5 label |
| `Tell us what's going on…` | field 5 placeholder |
| `Submit` | submit button label |
| `Fields marked * are required.` | footer helper text |
| `Thank you!` | success alert title |
| `Your feedback has been sent.` | success alert message |
| `OK` | success alert button |
| `Could not send feedback` | failure alert title |
| `Please check your connection and try again.` | failure alert fallback message |

## 3.8 Navigation

* Back button (`arrow-left`) → `navigation.goBack()`.
* Alert `OK` → `navigation.goBack()`.
* No `navigate()` calls out of this screen.

---

# 4. `ForceUpdateModal` (module 1079)

## 4.1 `StyleSheet.create` (exact)

```
overlay : { flex:1, backgroundColor:'rgba(0,0,0,0.65)', alignItems:'center',
            justifyContent:'center', paddingHorizontal: SPACING.lg /*24*/ }
card    : { width:'100%', backgroundColor:'#fff', borderRadius: BORDER_RADIUS.xl /*24*/,
            padding: SPACING.xl /*32*/, alignItems:'center' }
iconWrap: { width:72, height:72, borderRadius:36, backgroundColor:'#E8F4FD',
            alignItems:'center', justifyContent:'center', marginBottom: SPACING.md /*16*/ }
icon    : { width:36, height:36, resizeMode:'contain', tintColor:'#1a73e8' }
title   : { fontSize: FONT_SIZE.xl /*22*/, fontWeight:'700', color:'#111',
            marginBottom: SPACING.sm /*8*/, textAlign:'center' }        ← DEFINED BUT UNUSED
body    : { fontSize: FONT_SIZE.base /*16*/, color:'#555', textAlign:'center',
            lineHeight:22, marginBottom: SPACING.sm /*8*/ }            ← DEFINED BUT UNUSED
version : { fontSize: FONT_SIZE.xs /*10*/, color:'#999', marginBottom: SPACING.lg /*24*/ }
btn     : { width:'100%', backgroundColor:'#1a73e8', borderRadius: BORDER_RADIUS.lg /*16*/,
            paddingVertical:14, alignItems:'center', overflow:'hidden' }
btnText : { color:'#fff', fontWeight:'700', fontSize: FONT_SIZE.md /*14*/ }
```

**Every style in this component is hard-coded / non-themed** (only the two inline `Text`
styles reference `COLORS` from module 576, and even then the light values, not the user's
active theme). There is no `colors` prop and no `useTheme()` call.

## 4.2 Props

| Prop | Type | Required | Default in code | Behaviour |
|---|---|---|---|---|
| `visible` | boolean | yes (no default) | — | passed straight to RN `Modal.visible`; also the dependency of the `useEffect` that arms/disarms the Android back handler |
| `storeVersion` | string \| null | no | — | when truthy, a `Version <storeVersion> available` line is rendered; when falsy that `Text` is not rendered at all |
| `onUpdate` | function | no | — | `onPress` of the `Update Now` button. **No default** — if omitted the button does nothing |

Props destructured in order: `visible`, `storeVersion`, `onUpdate`.
Note there is **no `onClose` / `onDismiss` / `forceClose` prop** — the modal cannot be
dismissed by design (see §4.4).

## 4.3 Component signature

`ForceUpdateModal({ visible, storeVersion, onUpdate })` — plain function component, no
`React.memo`, no prop-types.

## 4.4 `onRequestClose` and the Android back handler

```
useEffect(() => {
  if (!visible) return;                                   // returns undefined, no cleanup
  const sub = BackHandler.addEventListener('hardwareBackPress', () => true);
  return () => sub.remove();
}, [visible]);

<Modal … onRequestClose={() => {}} />                     // no-op
```

* `onRequestClose` is an **empty arrow function** — it neither closes nor calls any prop.
* While `visible`, the hardware back button is intercepted and returns `true`
  (event consumed) so the modal cannot be dismissed; the listener is removed as soon as
  `visible` flips to false or the component unmounts.
* The only exits are the `Update Now` button (→ `onUpdate`) or the OS-level app switch.

## 4.5 Exact UI tree

```
Modal   visible={visible}  transparent={true}  animationType='fade'
        statusBarTranslucent={true}  onRequestClose={ () => {} }
└─ View  style={styles.overlay}
   └─ View  style={styles.card}
      ├─ View  style={styles.iconWrap}
      │  └─ Image  source={ require('…/icons/alert') }   style={styles.icon}
      ├─ Text 'Update Required'
      │     style={ fontSize: FONT_SIZE.lg /*18*/, color: COLORS.text /*#212121*/ }
      │     (inline; styles.title is NOT used — no fontWeight/textAlign/marginBottom)
      ├─ Text 'A new version is available with important improvements and fixes. Please update to continue using the app.'
      │     style={ fontSize: FONT_SIZE.base /*16*/, color: COLORS.textSecondary /*#757575*/,
      │             textAlign:'center', marginTop: SPACING.sm /*8*/,
      │             marginBottom: SPACING.md /*16*/ }
      │     (inline; styles.body is NOT used — no lineHeight)
      ├─ { storeVersion ? <Text style={styles.version}>
      │      {'Version '}{storeVersion}{' available'}
      │    </Text> : null }        ← children is a 3-element array
      └─ Pressable  android_ripple={{ color:'#ffffff40' }}
                     onPress={onUpdate}
                     style={styles.btn}
         └─ Text 'Update Now'   style={styles.btnText}
```

## 4.6 Every literal string

| String | Where |
|---|---|
| `Update Required` | card title |
| `A new version is available with important improvements and fixes. Please update to continue using the app.` | card body |
| `Version ` | version line, part 1 (literal, trailing space) |
| `<storeVersion>` | version line, part 2 (prop value, e.g. `1.4.2`) |
| ` available` | version line, part 3 (literal, leading space) |
| `Update Now` | CTA button label |

Full rendered version line example: `Version 1.4.2 available`.

## 4.7 Image asset

The `Image` `source` is the module-1080 asset object, i.e. a registered packager asset:

```
{ __packager_asset: true,
  httpServerLocation: '/assets/src/assets/icons',
  width: 64, height: 64,
  scales: [1],
  hash: '6c76c9e2e052ff9acb6bca510e58c796',
  name: 'alert',
  type: 'jpg' }
```

→ app asset **`alert`** (a JPG in `src/assets/icons/`, 64×64 @1x). It is tinted
`#1a73e8` via `tintColor` and drawn `36×36` with `resizeMode:'contain'`.
This is the **only** image used by any of the four screens (the other screens use only
vector icons).

## 4.8 Host usage (module 495 `AppShell`)

```
const [forceUpdate, setForceUpdate] = useState(false);
const [storeVersion, setStoreVersion]   = useState(null);

checkForUpdate = async () => {
  try {
    const r = await new VersionCheck().checkNeedsUpdate();      // react-native-version-check
    if (r.shouldUpdate) { setStoreVersion(r.storeVersion); setForceUpdate(true); }
  } catch (e) { console.log('Update check error:', e); }
};
useEffect(() => { checkForUpdate(); requestNotificationPermission(); }, []);

handleUpdate = () => VersionCheck.startUpdate({ updateType: IAUUpdateKind.IMMEDIATE });

<ForceUpdateModal visible={forceUpdate} storeVersion={storeVersion} onUpdate={handleUpdate} />
```

The modal is rendered as the **last child** of the `AppShell` `Fragment`, after
`SystemBars` and the `NavigationContainer` (so it overlays everything). It is *not*
conditionally mounted — it is always mounted, `visible` controls it.

---

# 5. Module 1080 — image asset module

Tiny asset-registration module (15 lines): calls `registerAsset({...})` of module 710 and
exports it as `exports` (not `exports.default`). Owned by `ForceUpdateModal`.
See §4.7 for the exact object. Asset family available to the app also includes
`speedo, metro, orangeLine, electric, filter, bus2, search, arrow-right, location, route,
back, share, clock, clock-filled, loop, stop, location-map, location-direction, bus, alert`
— but the four analysed screens reference **only `alert`**.

---

# 6. Module 800 — NOT AsyncStorage (important correction)

Module 800 exports `compatibilityFlags` and `featureFlags` for
**`react-native-screens`**:

```
compatibilityFlags = {
  isNewBackTitleImplementation: true,
  usesHeaderFlexboxImplementation: true,
  usesNewAndroidHeaderHeightImplementation: true,
}
featureFlags = {
  experiment: {
    controlledBottomTabs: false,
    synchronousScreenUpdatesEnabled: false,
    synchronousHeaderConfigUpdatesEnabled: false,
    synchronousHeaderSubviewUpdatesEnabled: false,
    androidResetScreenShadowStateOnOrientationChangeEnabled: true,
    iosPreventReattachmentOfDismissedScreens: true,
    ios26AllowInteractionsDuringTransition: true,
  },
  stable: {},
}
default = featureFlags
```

It contains **no** `get`/`set` storage functions and no keys. The `get`/`set` functions in
the file are the getter/setter pairs backing each feature flag (they only mutate the
in-memory object and log `'[RNScreens] <flag> feature flag modified for a second time; this
might lead to unexpected effects'`). The real AsyncStorage instance is module 572.

## 6.1 AsyncStorage (module 572)

```
default = getLegacyStorage()      // createAsyncStorage(getLegacyStorage())
exports  = { AsyncStorageError, createAsyncStorage, default }
```

Only the default instance is consumed, via `ThemeProvider` (module 571). API used:
`AsyncStorage.getItem(key)` and `AsyncStorage.setItem(key, value)` (both promise-based,
`.catch()` swallows errors; `removeItem` exists but is never called by these modules).

---

# 7. Module 1315 — `@react-navigation/stack` barrel

Module 1315 re-exports (lazy getters) from `@react-navigation/stack` internals
(deps 1316, 1317, 1318, 1322, 1482, 1483, 1484, 1464, 1466, 1467):

| Export | Backing internal |
|---|---|
| `CardAnimationContext` | module 1316 `CardAnimationContext` |
| `GestureHandlerRefContext` | module 1317 `GestureHandlerRefContext` |
| `Header` | module 1318 `Header` |
| `StackView` | module 1322 `StackView` |
| `createStackNavigator` | module 1482 `createStackNavigator` |
| `useCardAnimation` | module 1483 `useCardAnimation` |
| `useGestureHandlerRef` | module 1484 `useGestureHandlerRef` |
| `CardStyleInterpolators` | module 1468 |
| `HeaderStyleInterpolators` | module 1464 |
| `TransitionPresets` | module 1466 |
| `TransitionSpecs` | module 1467 |

None of the four analysed screens import this module directly; it is used by the app
navigator (module 495). Screen-relevant facts: the root stack uses
`headerShown: false` and `animation: 'slide_from_right'`, stack `id: 'MainStack'`.

---

# 8. Complete icon inventory (all four screens)

Every icon is **`react-native-vector-icons/MaterialCommunityIcons`** (default export,
props `name` / `size` / `color` / optional `style`). Sizes are numeric dp-equivalents.

| Screen | Icon `name` | size | colour source | Notes |
|---|---|---|---|---|
| Settings | `white-balance-sunny` | 20 | `colors.primary` | Dark Mode row, shown when `!isDark` |
| Settings | `weather-night` | 20 | `colors.primary` | Dark Mode row, shown when `isDark` |
| Settings | `information` | 18 | `colors.primary` | disclaimer card, `marginRight: SPACING.xs` |
| Settings | `email-outline` | 18 | `colors.primary` | section header "Contact & Support", `marginRight: SPACING.xs` |
| Settings | `web` | 21 | `colors.primary` | row "Visit our Website" (leading) |
| Settings | `open-in-new` | 21 | `colors.textSecondary` | trailing icon of that row (`external`) |
| Settings | `help-circle-outline` | 21 | `colors.primary` | row "Help & Support" (leading) |
| Settings | `chevron-right` | 21 | `colors.textSecondary` | trailing icon (`external === false`) |
| Settings | `message-alert-outline` | 21 | `colors.primary` | row "Send Feedback" (leading) |
| Settings | `chevron-right` | 21 | `colors.textSecondary` | trailing icon |
| Settings | `shield-check-outline` | 18 | `colors.primary` | section header "Legal" |
| Settings | `shield-check-outline` | 21 | `colors.primary` | row "Privacy Policy" (leading) |
| Settings | `open-in-new` | 21 | `colors.textSecondary` | trailing icon |
| Settings | `web` | 18 | `colors.primary` | section header "Official Sources" |
| Settings | `bus` | 21 | `colors.primary` | official-source row (leading) |
| Settings | `open-in-new` | 21 | `colors.textSecondary` | trailing icon |
| Credits | `chevron-left` | 22 | `#fff` | header back button |
| Credits | `code-tags` | 22 | `#12B886` | card 1 avatar |
| Credits | `code-tags` | 22 | `#F59F00` | card 2 avatar |
| Credits | `chevron-right` | 18 | `#12B886` | card 1 link |
| Credits | `chevron-right` | 18 | `#F59F00` | card 2 link |
| Feedback | `arrow-left` | 22 | `#fff` | header back button |
| Feedback | `chevron-down` | 20 | `colors.textSecondary` | Dropdown `renderRightIcon` |
| Feedback | `send` | 18 | `#fff` | submit button, `marginRight: SPACING.xs` |
| (tab bar, module 557) | `cog-outline` / `cog` | 24 | tab colour | Settings tab icon, focused/unfocused |

Distinct names used: `white-balance-sunny`, `weather-night`, `information`, `email-outline`,
`web`, `open-in-new`, `help-circle-outline`, `chevron-right`, `message-alert-outline`,
`shield-check-outline`, `bus`, `chevron-left`, `code-tags`, `arrow-left`, `chevron-down`,
`send` (16 distinct names).

---

# 9. Image assets referenced

| Screen | Asset name | Type | Where |
|---|---|---|---|
| ForceUpdateModal | `alert` | jpg, 64×64, scale 1, hash `6c76c9e2e052ff9acb6bca510e58c796`, path `/assets/src/assets/icons` | `<Image source={…} style={styles.icon} />`, tinted `#1a73e8`, 36×36, `resizeMode:'contain'` |

SettingsScreen, CreditsScreen and FeedbackScreen reference **no** images.

---

# 10. Storage usage (AsyncStorage)

| Key | Read by | Written by | Values | Notes |
|---|---|---|---|---|
| `themePreference` | `ThemeProvider` mount effect (module 571) → `AsyncStorage.getItem('themePreference')` | `setThemePreference(v)` / `toggleTheme()` (invoked from the SettingsScreen Dark Mode row and Switch) | `'light'`, `'dark'`, `'system'` | Read result is ignored unless it is exactly one of the three strings. Write errors are swallowed (`.catch(() => {})`). |

No other AsyncStorage key is read or written by these four screens; there is no
favourites/recent-search/cache storage in them. `ForceUpdateModal` and `FeedbackScreen`
touch no storage (Feedback writes to Firestore, not AsyncStorage).

---

# 11. Navigation calls

| From | Call | Route / URL | Params |
|---|---|---|---|
| SettingsScreen | `navigation.navigate('Feedback')` | stack screen `Feedback` (module 1082) | none |
| SettingsScreen | `Linking.openURL('https://theislam313.vercel.app')` | external | — |
| SettingsScreen | `Linking.openURL('mailto:bilaliqbal883s@gmail.com')` | external | — |
| SettingsScreen | `Linking.openURL('https://codez-android.netlify.app')` | external | — |
| SettingsScreen | `Linking.openURL('https://etransit.punjab.gov.pk')` | external | — (per item, `OFFICIAL_SOURCES[i].url`) |
| CreditsScreen | `navigation.goBack()` | pops stack | — |
| CreditsScreen | `Linking.openURL('https://www.linkedin.com/in/awais882s')` / `…/muhammadbilaliqbal` | external | — |
| FeedbackScreen | `navigation.goBack()` × 2 (header back button, alert `OK`) | pops stack | — |
| ForceUpdateModal | none | — | — |

Route registry (module 495, root stack `id: 'MainStack'`, `headerShown: false`,
`animation: 'slide_from_right'`):
`MainTabs`, `Search`, `RouteDetail`, `StopDetail`, `Map`, `StopPicker`,
`JourneyResults`, `JourneyDetail`, `Credits`, `Feedback`.
Bottom tabs (`id: 'BottomTabs'`, module 557, `headerShown: false`, `animation: 'shift'`):
`Home`, `Nearby`, `Schedule`, `Settings`.
Note: `Credits` is a registered root-stack route with **no** in-app entry point.

---

# 12. Cross-cutting implementation notes for the Flutter port

1. **Alpha colours**: replace `colors.primary + '15'`-style concatenations with explicit
   8-digit `#AARRGGBB` values (e.g. `#fc3b3815`).
2. **`elevation: 1`** on the Credits card is Android-only; there are no `shadowColor` /
   `shadowOffset` / `shadowOpacity` / `shadowRadius` props, so on iOS the card casts no
   shadow. Decide whether to mirror that or add a shadow for parity of intent.
3. **`borderLeftColor` without `borderLeftWidth`** on the Settings disclaimer card produces
   no visible border in React Native.
4. The **Settings header has no back button and no title-bar button** (it is a tab root);
   Credits and Feedback headers both have circular translucent back buttons
   (`36×36` vs `35×35`, `BORDER_RADIUS.full` vs `BORDER_RADIUS.md`, ripple colours
   `#FFFFFF30`+`borderless` vs `#FFFFFF50`).
5. The Feedback `Dropdown` is `react-native-dropdown-picker`'s single-select `Dropdown`
   with the app's own `style`/`containerStyle`/`itemContainerStyle` overrides and a custom
   `renderRightIcon`; the trigger visually matches the text inputs because
   `style = { ...inputStyle, justifyContent: 'center' }`.
6. `KeyboardAvoidingView` uses `behavior={undefined}` (RN platform default). The `ScrollView`
   uses `keyboardShouldPersistTaps="handled"` so tapping the submit button while the
   keyboard is open fires the press.
7. All four screens call `useStatusBarColor(colors.primary)` — i.e. the status bar is the
   brand red `#fc3b38` with light content, applied on focus and animated.
8. `SettingsScreen` consumes only `{ colors, isDark, toggleTheme }`; `CreditsScreen`
   consumes only `{ colors }` (so it does **not** go dark); `FeedbackScreen` consumes only
   `{ colors }` (so it does **not** go dark either); `ForceUpdateModal` is fully
   light-themed regardless of the user's theme preference.
9. `SafeAreaView` from `react-native-safe-area-context` is used with `edges={['top']}` and
   `style={{ flex: 1, backgroundColor: colors.background }}` on all three themed screens.

---

## Appendix A — quick numeric reference

| Token | Value | Token | Value |
|---|---|---|---|
| `SPACING.xs` | 4 | `FONT_SIZE.xs` | 10 |
| `SPACING.sm` | 8 | `FONT_SIZE.sm` | 12 |
| `SPACING.md` | 16 | `FONT_SIZE.md` | 14 |
| `SPACING.lg` | 24 | `FONT_SIZE.base` | 16 |
| `SPACING.xl` | 32 | `FONT_SIZE.lg` | 18 |
| `SPACING.xxl` | 48 | `FONT_SIZE.xl` | 22 |
| `BORDER_RADIUS.sm` | 6 | `FONT_SIZE.xxl` | 28 |
| `BORDER_RADIUS.md` | 10 | `FONT_SIZE.xxxl` | 36 |
| `BORDER_RADIUS.lg` | 16 | `SPACING.sm + 4` (input paddingVertical) | 12 |
| `BORDER_RADIUS.xl` | 24 | `SPACING.sm + 2` (credits CTA paddingVertical) | 10 |
| `BORDER_RADIUS.full` | 999 | ForceUpdateModal `btn.paddingVertical` | 14 |

Hard-coded colours outside the theme: `#fff`, `rgba(255,255,255,0.9)`,
`rgba(255,255,255,0.85)`, `rgba(255,255,255,0.15)`, `#FFFFFF30`, `#FFFFFF50`,
`#ffffff40`, `#C62828`, `#12B886`, `#F59F00`, `#111`, `#555`, `#999`, `#1a73e8`,
`#E8F4FD`, `rgba(0,0,0,0.65)`, `#FFFFFF`.
