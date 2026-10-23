#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# ui_test.sh — drive the installed app with ADB and capture screenshots.
#
# Usage: tool/ui_test.sh <package> <outdir>
# ---------------------------------------------------------------------------
set -uo pipefail

PKG="${1:-com.codez.lahore_speedo_bus_guide}"
OUT="${2:-/tmp/opencode/shots}"
ADB="${ADB:-adb}"
S="$ADB -s emulator-5554"

mkdir -p "$OUT"

shot() { # shot <name>
  local n="$1"
  sleep "${2:-2}"
  $S exec-out screencap -p > "$OUT/$n.png" 2>/dev/null
  echo "  shot: $n.png ($(stat -c%s "$OUT/$n.png" 2>/dev/null || echo 0) bytes)"
}

tap() { # tap <x> <y> [name]
  $S shell input tap "$1" "$2"
  echo "  tap: ($1,$2) ${3:-}"
  sleep "${4:-2}"
}

back() { $S shell input keyevent KEYCODE_BACK; echo "  back"; sleep 2; }

text() { # text <string>
  $S shell input text "$1"
  sleep 1
}

swipe() { # swipe <x1> <y1> <x2> <y2> [ms]
  $S shell input swipe "$1" "$2" "$3" "$4" "${5:-400}"
  sleep 2
}

echo "== device =="
$S shell getprop ro.build.version.release
$S shell wm size
$S shell wm density

echo "== dismiss any ANR dialog =="
for _ in 1 2 3; do
  # "Wait" is at the bottom of the system ANR dialog
  $S shell input tap 250 714 2>/dev/null
  sleep 1
done

echo "== 1. launch =="
$S shell am force-stop "$PKG"
sleep 2
$S shell am start -n "$PKG/.MainActivity" >/dev/null 2>&1
sleep 25
shot 01_home 3

echo "== 2. tab: Nearby =="
tap 270 1110 "nearby tab" 12
shot 02_nearby 3

echo "== 3. tab: Schedule =="
tap 450 1110 "schedule tab" 12
shot 03_schedule 3

echo "== 4. schedule: scroll the route list =="
swipe 360 900 360 400 600
shot 04_schedule_scrolled 3

echo "== 5. tab: Settings =="
tap 630 1110 "settings tab" 12
shot 05_settings 3

echo "== 6. settings: scroll =="
swipe 360 900 360 350 600
shot 06_settings_scrolled 3

echo "== 7. back to Home =="
tap 90 1110 "home tab" 10
shot 07_home_again 3

echo "== logcat errors =="
$S logcat -d -v brief 2>/dev/null \
  | grep -iE "flutter|AndroidRuntime|FATAL|Exception|Error" \
  | grep -viE "egl|impeller|libEGL|GLES|OpenGL" | tail -60
