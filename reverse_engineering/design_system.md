# Design System (recovered)

## Colours (module `576 theme.ts` — VERBATIM, both themes)

| Token | Light | Dark |
|---|---|---|
| `primary` | `#fc3b38` | `#fc3b38` |
| `background` | `#F5F7FA` | `#121212` |
| `card` | `#FFFFFF` | `#2C2C2C` |
| `border` | `#E0E0E0` | `#333333` |
| `text` | `#212121` | `#EEEEEE` |
| `textSecondary` | `#757575` | `#AAAAAA` |
| `white` | `#FFFFFF` | `#FFFFFF` |
| `black` | `#000000` | `#000000` |
| `overlay` | `rgba(0,0,0,0.5)` | `rgba(0,0,0,0.7)` |

Additional colours observed in the screens:

| Value | Meaning |
|---|---|
| `#1a73e8` | "Open in Maps" link blue |
| `#2E7D32`, `#C62828` | success / error text |
| `#F6F7F8` | muted chip background (light) |
| `#E8F4FD` | info box background (light) |
| `#D6B929`, `#AB29D6`, `#D629AB`, `#D629C8`, `#8E29D6`, `#7129D6`, `#5529D6`, `#3829D6`, `#2954D6`, `#2970D6`, `#2937D6`, `#9F1239`, `#EA580C`, `#1F92A3`, `#1FA3*`, `#24A31F`, `#3AA31F`, `#50A31F`, `#66A31F`, `#7CA31F`, `#92A31F` | the 28 route line colours (see `extracted_data/routes.json`) |

Category colours (module `715 categories.ts`):

| Category | Label | Chip colour |
|---|---|---|
| `speedo` | `Speedo` | `#e12221` |
| `metro` | `Metro` | `#358437` |
| `orangeLine` | `Orange Line` | `#e29109` |
| `electric` | `Electric` | `#358437` |
| `all` | `All` | `COLORS.primary` = `#fc3b38` |

## Theme mechanism (module `571`)

```
ThemeProvider
  state: preference   ('system' | 'light' | 'dark', default 'system')
         colorScheme  (Appearance.getColorScheme() ?? 'light'; subscribes to changes)
  isDark = preference === 'dark'
             ? true
             : preference === 'light' ? false : colorScheme === 'dark'
  colors = isDark ? DARK_COLORS : COLORS
  toggleTheme(v) -> setPreference(v) + AsyncStorage.setItem('themePreference', v)
  context value = { colors, isDark, toggleTheme, preference, setThemePreference }
```

## Typography

No custom font family is loaded — `assets/fonts` contains only the 19 `react-native-vector-icons`
icon fonts. Text therefore renders in the Android platform default (**Roboto**). Weights observed:
`400`, `500`, `600`, `700`, `800`. Sizes range from `10` to `34`. `textTransform` is used for
uppercase eyebrows and is `none` elsewhere.

| Role | Size | Weight | Colour |
|---|---|---|---|
| Screen title (in-page app bar) | 22–26 | 700/800 | `text` |
| Section header | 13–14 | 700 | `text`, letterSpacing ≈ 0.4–1.0 |
| Card title / route name | 15–17 | 700 | `text` |
| Subtitle / long name | 12–13 | 400 | `textSecondary` |
| Body | 13–14 | 400/500 | `text` |
| Caption | 11–12 | 400/500 | `textSecondary` |
| Fare chip | 11–13 | 700 | `card`/white |
| Stat number | 18–22 | 800 | `primary` / `text` |
| Button label | 13–15 | 700 | `white` / `primary` |

Exact per-screen values are in `specs/*.md`.

## Layout metrics

| Metric | Value |
|---|---|
| Screen horizontal padding | 16 (a few 20) |
| Card padding | 14–16 |
| Card corner radius | 12–16 (14 most common; chips 20 = pill) |
| Card border | `borderWidth: 1`, `borderColor: colors.border` |
| Divider | `height: 1`, `backgroundColor: colors.border` |
| Card separator (vertical) | 8–12 |
| List item vertical padding | 12–14 |
| Button height | 40–48, radius 10–12 |
| Input height | 46–50, radius 12, `borderWidth: 1` |
| Icon sizes | 16 (inline), 20, 24 (tab bar / default) |
| Bottom navigation | RN Paper `BottomNavigation.Bar`, `compact` |
| Bottom nav active indicator | `backgroundColor: primary + '20'` (alpha suffix), pill |
| Bottom nav active / inactive | `colors.primary` / `colors.textSecondary` |
| Bottom nav bar | `colors.card`, `borderTopWidth: 1`, `borderTopColor: colors.border` |
| App bar | React Navigation headers are **hidden** (`headerShown: false`); every screen renders its own in-page header (title, back arrow, optional action) |
| Elevation | none — the design is flat, using `borderWidth: 1` instead of shadows |

## Components inventory
Rounded primary buttons, outline buttons, bordered cards (radius 14), labelled text fields,
pill chips (category chips, fare chips, tag chips), in-page app bars with back arrows, section
headers, dividers, list rows (leading icon + label + value/chevron), the Paper MD3 bottom navigation
bar, a bottom sheet on the map screen, a modal (ForceUpdateModal), switches on Settings, an RN
`ActivityIndicator` in `colors.primary`, and inline "copied"/"shared" banners.
