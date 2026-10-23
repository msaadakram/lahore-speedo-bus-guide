#!/usr/bin/env bash
# Capture the screens that have not had a per-element UI pass yet, plus the
# dark theme.
# Usage: tool/capture_screens2.sh [serial] [outdir]
set -uo pipefail
export PATH="$HOME/Android/Sdk/platform-tools:$PATH"
SERIAL="${1:-emulator-5556}"
OUT="${2:-/tmp/opencode/audit5}"
PKG=com.codez.lahore_speedo_bus_guide
S="adb -s $SERIAL"
mkdir -p "$OUT"

shot() { sleep "${2:-2}"; $S exec-out screencap -p > "$OUT/$1.png" 2>/dev/null; echo "  $1"; }
tap() { $S shell input tap "$1" "$2"; sleep "${3:-3}"; }
swipe() { $S shell input swipe "$1" "$2" "$3" "$4" "${5:-400}"; sleep 2; }
text() { $S shell input text "$1"; sleep 2; }
back() { $S shell input keyevent KEYCODE_BACK; sleep 3; }

TAB_HOME=135; TAB_NEARBY=405; TAB_SCHEDULE=675; TAB_SETTINGS=945
Y=1710

$S shell pm disable-user -w com.toralabs.apk_extractor 2>/dev/null || true
$S shell pm disable-user -w com.toralabs.apkextractor 2>/dev/null || true
$S shell am force-stop $PKG; sleep 2
$S shell am start -n $PKG/.MainActivity; sleep 24

echo "capturing the remaining screens..."

# ---- Route detail (at the FIRST new screen) ---------------------------------
tap $TAB_SCHEDULE $Y 5
tap 400 900 6;              shot 20_route_detail
swipe 360 1500 360 600;    shot 21_route_detail_scrolled
swipe 360 1500 360 600;    shot 22_route_detail_stops
back

# ---- Map (from the route detail "View on Map") ------------------------------
tap $TAB_SCHEDULE $Y 4
tap 400 900 5
swipe 360 1500 360 700;    shot 23_route_detail_mapbtn
tap 400 1200 7;             shot 24_map
back; back

# ---- Stop detail (tap a stop in the route detail stop list) -----------------
tap $TAB_SCHEDULE $Y 4
tap 400 900 5
swipe 360 1500 360 500
swipe 360 1500 360 500
tap 400 1200 6;             shot 25_stop_detail
back; back

# ---- Journey results: Home -> FROM -> TO -> Find Routes --------------------
tap $TAB_HOME $Y 4
tap 300 730 5
text "Jinnah"; sleep 2
tap 400 900 5               # pick the first result
tap 300 850 5
text "Bahria"; sleep 2
tap 400 900 5
shot 26_home_both
tap 400 1020 8;             shot 27_journey_results
tap 400 900 7;              shot 28_journey_detail
back; back

# ---- Settings -> Credits / Feedback -----------------------------------------
tap $TAB_SETTINGS $Y 5
swipe 360 1500 360 600
swipe 360 1500 360 600;    shot 29_settings_bottom
tap 400 1200 6;             shot 30_credits
back
tap 400 900 6;              shot 31_feedback
back

# ---- Dark theme -------------------------------------------------------------
tap $TAB_HOME $Y 4
tap $TAB_SETTINGS $Y 5
tap 915 375 3;              shot 32_dark_settings
tap $TAB_HOME $Y 5;         shot 33_dark_home
tap $TAB_SCHEDULE $Y 5;     shot 34_dark_schedule
tap $TAB_NEARBY $Y 5;       shot 35_dark_nearby

echo "done -> $OUT"
