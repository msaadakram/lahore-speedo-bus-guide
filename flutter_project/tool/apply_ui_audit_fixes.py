#!/usr/bin/env python3
"""Apply the visual audit fixes.

A. Remove every hard-coded legacy colour (the old red brand + old greys) and
   route them through the palette.
B. Fix the broken StopPicker / Search field (a translucent container wrapping a
   hard-bordered white TextField).
C. Tighten the header rhythm and give the list rows a proper structure.
"""
import os
import re

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LIB = os.path.join(ROOT, 'lib')

RED = 'Color(0xFFFC3B38)'


def edit(rel, pairs, must=True):
    path = os.path.join(LIB, rel)
    src = open(path).read()
    for a, b in pairs:
        if a not in src:
            print('  MISS  %-44s %r' % (rel, a[:52]))
            if must:
                continue
        src = src.replace(a, b)
    open(path, 'w').write(src)
    print('  ok    %s' % rel)


# ---------------------------------------------------------------- A. colours
edit('features/journey_detail/journey_detail_screen.dart', [
    ("const Text('• ', style: TextStyle(color: Color(0xFFFC3B38))),",
     "Text('• ', style: TextStyle(color: palette.primary)),"),
])

edit('features/schedule/schedule_screen.dart', [
    ("Icon(AppIcons.routes, size: 18, color: Color(0xFF757575)),",
     "Icon(AppIcons.routes, size: 20, color: palette.textSecondary),"),
    ("                        color: Color(0xFF757575),",
     "                        color: palette.textSecondary,"),
])

edit('features/home/home_screen.dart', [
    ("child: ColoredBox(color: Color(0xFFE0E0E0)),",
     "child: ColoredBox(color: palette.border),"),
])

edit('features/settings/settings_screen.dart', [
    # The disclaimer was red; in the green world it reads as a warning, not an
    # error. Use the warm accent and soften the card.
    ("                    style: const TextStyle(\n"
     "                      fontSize: Tokens.fontMd,\n"
     "                      color: Color(0xFFFC3B38),\n"
     "                    ),",
     "                    style: TextStyle(\n"
     "                      fontSize: Tokens.fontMd,\n"
     "                      height: 1.45,\n"
     "                      color: palette.text,\n"
     "                    ),"),
    ("                    color: palette.primary.withValues(alpha: 0.08),",
     "                    color: palette.accent.withValues(alpha: 0.14),"),
    ("                    left: BorderSide(color: palette.primary, width: 3),",
     "                    left: BorderSide(color: palette.accent, width: 4),"),
])

edit('features/nearby/nearby_screen.dart', [
    ("                color: Color(0xFFFC3B38),", "                color: palette.primary,"),
])

edit('features/stop_picker/stop_picker_screen.dart', [
    ("                color: Color(0xFFFC3B38),", "                color: palette.primary,"),
    ("              color: Color(0xFF757575),", "              color: palette.textSecondary,"),
])

# ------------------------------------------------------- B. the broken field
# StopPicker: a translucent container wrapping a raw TextField produced a
# double box with a hard border. Use one clean, theme-styled field.
edit('features/stop_picker/stop_picker_screen.dart', [
    ("""                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Tokens.spaceMd,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0x33FFFFFF),
                        borderRadius: BorderRadius.circular(Tokens.radiusMd),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            AppIcons.magnify,
                            size: 16,
                            color: Color(0xCCFFFFFF),
                          ),
                          const SizedBox(width: Tokens.spaceSm),
                          Expanded(
                            child: TextField(
                              controller: _queryController,
                              autofocus: true,
                              onChanged: (v) => setState(() => _query = v),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: Tokens.fontBase,
                              ),
                              decoration: const InputDecoration(
                                hintText: 'Type stop name...',
                                hintStyle: TextStyle(
                                  color: Color(0xB3FFFFFF),
                                  fontSize: Tokens.fontBase,
                                ),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),""",
     """                    _SearchField(
                      controller: _queryController,
                      onChanged: (v) => setState(() => _query = v),
                    ),"""),
])

# The Search screen has the same hand-rolled field treatment.
edit('features/search/search_screen.dart', [
    ("""                      controller: _queryController,
                      autofocus: true,
                      onChanged: (v) => setState(() => _query = v),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: Tokens.fontBase,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Search by route name or stop name ...',
                        hintStyle: TextStyle(
                          color: Color(0xB3FFFFFF),
                          fontSize: Tokens.fontBase,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 14),
                      ),""",
     """                      controller: _queryController,
                      autofocus: true,
                      onChanged: (v) => setState(() => _query = v),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: Tokens.fontBase,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search by route name or stop name ...',
                        hintStyle: const TextStyle(
                          color: Color(0xB3FFFFFF),
                          fontSize: Tokens.fontBase,
                        ),
                        filled: true,
                        fillColor: const Color(0x26FFFFFF),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            Tokens.shapeMd,
                          ),
                          borderSide: BorderSide(color: Color(0x40FFFFFF)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            Tokens.shapeMd,
                          ),
                          borderSide: BorderSide(color: Color(0x40FFFFFF)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            Tokens.shapeMd,
                          ),
                          borderSide: const BorderSide(
                            color: Color(0x99FFFFFF),
                            width: 2,
                          ),
                        ),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: Tokens.spaceMd,
                          vertical: 14,
                        ),
                      ),"""),
])
print('done')
