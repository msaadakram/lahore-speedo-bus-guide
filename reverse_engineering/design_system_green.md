# Design system — green (artwork-derived)

The app's visual language is derived from the reference artwork
`downloads/bz4sqCqW.jpg` (a soft 3D render: grass-green gradient backdrop,
chunky rounded forms, diffuse green-tinted shadows, warm khaki accents).

## Palette — sampled directly from the image

| Token | Light | Dark | Source |
|---|---|---|---|
| `primary` | `#3B7306` | `#8FBB2A` | mid-forest green in the backdrop gradient |
| `primaryBright` | `#83A034` | `#83A034` | **the dominant colour** (6.7 % of pixels) |
| `accent` | `#9BB224` | `#9BB224` | bright leaf highlight |
| `accentSoft` | `#BCD174` | `#3E4C1C` | pale lime at the foot of the gradient |
| `background` | `#F3F8E4` | `#101808` | barely-green off-white |
| `backgroundAlt` | `#FBFDF4` | `#1A2610` | warm near-white |
| `card` | `#FFFFFF` | `#1E2A14` | |
| `surfaceTint` | `#EDF3DC` | `#24311A` | inset blocks / chips |
| `border` | `#DFEBC8` | `#33421F` | hairline |
| `text` | `#1E2A10` | `#EAF2DC` | near-black with a green cast |
| `textSecondary` | `#5F7346` | `#A9BA8C` | muted olive |
| `shadow` | `#1F3B7306` | `#66000000` | green-tinted diffuse shadow |
| `overlay` | `#8A101808` | `#B3000000` | scrim |

Secondary hues kept from the artwork: `khaki #939747`, `clay #957253`, `sand #D9CBA8`.

### Category colours (still distinct, tuned to sit inside the green world)
| Category | Colour |
|---|---|
| Speedo | `#C2410C` |
| Metro | `#3F7FB5` |
| Orange Line | `#D98A0B` |
| Electric | `#4C8B1B` |

## Gradients

| Name | Definition | Where |
|---|---|---|
| `heroGradient` | vertical `primaryBright → primary → accent` (stops 0 / .68 / 1) | every screen header, the primary button |
| `canvasGradient` | vertical `background → backgroundAlt` | page background behind the tabs |
| `groundGradient` | `accentSoft → accent → primary` | reserved for dense/grounded content |

The hero gradient reproduces the artwork's *lit-from-above* falloff: bright grass
at the top, deepening into forest shadow at the foot.

## Shape & elevation

| Token | Value | Note |
|---|---|---|
| `shapeSm` | 12 | inputs, small badges |
| `shapeMd` | 18 | stat boxes, chips |
| `shapeLg` | 24 | cards |
| `shapeXl` | 32 | route rows, sheets, dialogs |
| `shapePill` | 999 | buttons, chips, badges |

Shadows are **soft, green-tinted and diffuse** — the signature of the reference
art — rather than the original's flat `borderWidth: 1`:

```dart
softShadow  = BoxShadow(color: shadow, blurRadius: 22, offset: (0, 8), spreadRadius: -4)
liftedShadow = BoxShadow(color: shadow, blurRadius: 30, offset: (0, 14), spreadRadius: -6)
              + BoxShadow(color: shadow@45%, blurRadius: 8, offset: (0, 3))
```

## Typography

No custom font (the original loads none either, so Roboto is the faithful
choice), but the weights and tracking follow the artwork's poster feel:

| Role | Size | Weight | Tracking |
|---|---|---|---|
| Display / hero title | 22–28 | 800 | −0.6 |
| Section heading | 16–18 | 800 | −0.2 … 0 |
| Body | 14–16 | 400–500 | 0 |
| Caption | 12 | 400–600 | 0 |
| Eyebrow / section label | 12 | 800 | +1.1 |
| Button label | 16 | 800 | +0.1 |

## Component changes vs. the original rebuild

| Component | Before | Now |
|---|---|---|
| Screen header | flat `primary` fill | `heroGradient` + soft shadow, 40 px translucent circular back button |
| Primary button | flat fill, 12 px radius | gradient fill, **pill** radius, soft shadow |
| Card | 1 px border, no shadow | 1 px border **+ soft shadow**, 24 px radius |
| Route row | 24 px radius | 32 px radius + soft shadow |
| Category tab | flat white / translucent | active pill gets a soft shadow |
| Stat box | flat fill | fill + soft shadow, optional icon |
| Empty state | bare icon | icon in a 72 px tinted circle |
| Icon badge (HOW IT WORKS) | flat tint | **gradient badge** with shadow (mirrors the artwork's lit 3D forms) |
| Bottom navigation | 62 px | 68 px, elevated with an upward soft shadow, 16 % green active pill |
| Page background | flat colour | `canvasGradient` |
| Text fields | 18 px radius, flat fill | 18 px radius, tinted fill, 2 px focus ring |

## What deliberately did **not** change

* The recovered content — every string, the 28-route dataset, the navigation
  graph and the interaction model are untouched.
* The original `react-native-vector-icons` glyphs are still used verbatim.
* `SPACING` / `FONT_SIZE` / `BORDER_RADIUS` keep their recovered values;
  the new `shape*` scale is additive.
* The four category hues remain distinct so a route's line colour is still
  recognisable at a glance.
