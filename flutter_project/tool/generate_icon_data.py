#!/usr/bin/env python3
"""Regenerate lib/shared/widgets/app_icon_data.dart from the recovered
MaterialCommunityIcons glyph map.

The codepoints come straight from the glyph map that was extracted out of the
original APK's Hermes bundle, so the rebuilt app renders the *exact* glyphs the
original did. Never hand-edit the generated file.
"""
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
PROJECT = os.path.dirname(HERE)
MAP = os.path.join(
    os.path.dirname(HERE),
    '..',
    'reverse_engineering',
    'hermes',
    'iconmaps',
    'materialcommunityicons.json',
)

# Dart field name -> MaterialCommunityIcons icon name
WANT = {
    'arrowLeft': 'arrow-left',
    'arrowRight': 'arrow-right',
    'arrowUp': 'arrow-up',
    'chevronDown': 'chevron-down',
    'chevronLeft': 'chevron-left',
    'chevronRight': 'chevron-right',
    'close': 'close',
    'clock': 'clock',
    'clockFilled': 'clock-time-four',
    'clockAlt': 'clock-outline',
    'directionsWalk': 'walk',
    'walk': 'walk',
    'filter': 'filter',
    'information': 'information',
    'loop': 'sync',
    'magnify': 'magnify',
    'search': 'magnify',
    'mapMarkerAlt': 'map-marker-off-outline',
    'mapMarker': 'map-marker',
    'mapMarkerOutline': 'map-marker-outline',
    'pageFirst': 'page-first',
    'pageLast': 'page-last',
    'reload': 'reload',
    'stop': 'stop-circle-outline',
    'send': 'send',
    'share': 'share-variant',
    'swapHorizontal': 'swap-horizontal',
    'swapVertical': 'swap-vertical',
    'timeOutline': 'clock-outline',
    'textOutline': 'text-box-outline',
    'warning': 'alert',
    'alertTriangle': 'alert',
    'tick': 'check',
    'check': 'check',
    'qrCode': 'qrcode',
    'homeOutline': 'home-outline',
    'home': 'home',
    'busSide': 'bus-side',
    'bus': 'bus',
    'busMultiple': 'bus-multiple',
    'cogOutline': 'cog-outline',
    'cog': 'cog',
    'flag': 'flag-variant',
    'routes': 'routes',
    'wifiOff': 'wifi-off',
    'map': 'map',
    'directions': 'directions',
    'themeLightDark': 'theme-light-dark',
    'shield': 'shield-outline',
    'link': 'link',
    'mail': 'email',
    'web': 'web',
    'codeTags': 'code-tags',
    'fitScreen': 'fit-to-page-outline',
    'calendar': 'calendar',
}

# icon name -> extra Dart aliases that share the same glyph
ALIASES = {
    'search': 'magnify',
    'clockAlt': 'clock-outline',
    'directionsWalk': 'walk',
    'tick': 'check',
    'alertTriangle': 'alert',
    'loop': 'sync',
}

HEADER = """import 'package:flutter/material.dart';

// Icon codepoints recovered from the original APK.
//
// GENERATED FILE - do not edit by hand. Regenerate with:
//   python3 tool/generate_icon_data.py
//
// The values come from the `react-native-vector-icons` MaterialCommunityIcons
// glyph map that was extracted from the original Hermes bundle, so the
// rebuilt app renders the same glyphs as the original.

abstract final class AppIconData {
  const AppIconData._();

  static const String family = 'AppIcons';

"""


def main() -> int:
    if not os.path.exists(MAP):
        print('glyph map not found: %s' % MAP, file=sys.stderr)
        return 2
    with open(MAP, encoding='utf-8') as fh:
        mdi = json.load(fh)

    missing = sorted({n for n in WANT.values() if n not in mdi})
    if missing:
        print('icons missing from the recovered map: %s' % missing, file=sys.stderr)
        return 1

    lines = [HEADER]
    for field, name in WANT.items():
        cp = mdi[name]
        lines.append(
            '  static const IconData %s = IconData(0x%X, fontFamily: family);'
            ' // %s\n' % (field, cp, name)
        )

    lines.append('\n  /// Lookup by the original MaterialCommunityIcons name.\n')
    lines.append('  static const Map<String, IconData> _byName = <String, IconData>{\n')
    seen = set()
    for name in sorted(set(WANT.values())):
        if name in seen:
            continue
        seen.add(name)
        lines.append("    '%s': %s,\n" % (name, _field_for(name)))
    lines.append('  };\n\n')
    lines.append('  static IconData? byName(String name) => _byName[name];\n')
    lines.append('}\n')

    out = os.path.join(PROJECT, 'lib', 'shared', 'widgets', 'app_icon_data.dart')
    with open(out, 'w', encoding='utf-8') as fh:
        fh.write(''.join(lines))
    print('wrote %s (%d icons)' % (out, len(seen)))
    return 0


def _field_for(icon_name: str) -> str:
    for field, name in WANT.items():
        if name == icon_name:
            return field
    raise KeyError(icon_name)


if __name__ == '__main__':
    raise SystemExit(main())
