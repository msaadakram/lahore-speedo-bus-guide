#!/usr/bin/env bash
# Capture every screen of the running app for a visual audit.
# Usage: tool/capture_screens.sh [serial] [outdir]
set -uo pipefail
export PATH="$HOME/Android/Sdk/platform-tools:$PATH"
SERIAL="${1:-emulator-5556}"
OUT="${2:-/tmp/opencode/audit}"
PKG=com.codez.lahore_speedo_bus_guide
S="adb -s $SERIAL"
mkdir -p "$OUT"

shot() { sleep "${2:-2}"; $S exec-out screencap -p > "$OUT/$1.png" 2>/dev/null; echo "  $1"; }
tap() { $S shell input tap "$1" "$2"; sleep "${3:-3}"; }
swipe() { $S shell input swipe "$1" "$2" "$3" "$4" "${5:-400}"; sleep 2; }
text() { $S shell input text "$1"; sleep 2; }

# Bottom bar sits at y=1670 on a 720x1280@320dpi device scaled to 1080 wide.
TAB_HOME=135; TAB_NEARBY=405; TAB_SCHEDULE=675; TAB_SETTINGS=945
Y=1710

$S shell am force-stop $PKG; sleep 2
$S shell am start -n $PKG/.MainActivity >/dev/null 2>&1; sleep 22

echo "capturing..."
shot 01_home

tap $TAB_SCHEDULE $Y 6;   shot 02_schedule
swipe 360 1500 360 600;   shot 03_schedule_scrolled

tap $TAB_NEARBY $Y 6;    shot 04_nearby
tap $TAB_SETTINGS $Y 6;   shot 05_settings
swipe 360 1500 360 600;   shot 06_settings_scrolled
swipe 360 1500 360 600;   shot 07_settings_bottom

tap $TAB_HOME $Y 5;       shot 08_home_again

# Route detail: Schedule -> first route row
tap $TAB_SCHEDULE $Y 5
tap 400 700 6;            shot 09_route_detail
swipe 360 1500 360 600;   shot 10_route_detail_scrolled

# Stop picker: Home -> FROM field
tap $TAB_HOME $Y 5
tap 300 730 6;            shot 11_stop_picker
text "Jinnah";            shot 12_stop_picker_search
$S shell input keyevent KEYCODE_BACK; sleep 3

# Search screen
tap $TAB_SCHEDULE $Y 4
tap 1000 200 6;           shot 13_search
text "Speedo";            shot 14_search_results

echo "done -> $OUT"
