#!/usr/bin/env python3
"""Convert the hand-rolled coloured headers into the artwork's green gradient.

Every screen that paints its own header block (rather than using
`AppPageHeader`) gets the signature `heroGradient` instead of a flat colour.
"""
import os
import re

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FEATURES = os.path.join(ROOT, 'lib', 'features')

# (file, old colour expression, comment)
TARGETS = [
    ('home/home_screen.dart', 'palette.primary', 'home header'),
    ('schedule/schedule_screen.dart', 'headerColor', 'schedule header'),
    ('nearby/nearby_screen.dart', 'palette.primary', 'nearby header'),
    ('search/search_screen.dart', 'palette.primary', 'search header'),
    ('stop_picker/stop_picker_screen.dart', 'palette.primary', 'stop picker header'),
    ('stop_detail/stop_detail_screen.dart', 'palette.primary', 'stop detail header'),
    ('feedback/feedback_screen.dart', 'palette.primary', 'feedback header'),
    ('journey_results/journey_results_screen.dart', 'palette.primary', 'journey results header'),
    ('journey_detail/journey_detail_screen.dart', 'palette.primary', 'journey detail header'),
    ('map/map_screen.dart', 'palette.primary', 'map header'),
]

for rel, colour, label in TARGETS:
    path = os.path.join(FEATURES, rel)
    src = open(path).read()
    # Find the header Container: `Container(\n  color: <colour>,\n ...` and turn
    # it into a decorated container using the gradient.
    pattern = re.compile(
        r'(Container\(\s*\n)(\s*)color: ' + re.escape(colour) + r',(\s*\n)(.*?)(\n\s*\),)',
        re.S)
    m = pattern.search(src)
    if not m:
        print('  MISS  %-45s (%s)' % (label, rel))
        continue
    indent = m.group(2)
    body = m.group(4)
    replacement = (
        f"{m.group(1)}{indent}decoration: BoxDecoration(\n"
        f"{indent}  gradient: palette.heroGradient,\n"
        f"{indent}  boxShadow: palette.softShadow,\n"
        f"{indent}),\n"
        f"{body}{m.group(5)}"
    )
    src = src[:m.start()] + replacement + src[m.end():]
    open(path, 'w').write(src)
    print('  OK    %-45s (%s)' % (label, rel))
