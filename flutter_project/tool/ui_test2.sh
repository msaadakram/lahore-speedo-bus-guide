#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# ui_test2.sh — assertion-driven UI test.
#
# The emulator runs under QEMU TCG (no KVM), so the UI lags behind taps. This
# script therefore *asserts* on the view hierarchy (uiautomator dump) before
# moving on, rather than blindly sleeping.
# ---------------------------------------------------------------------------
set -uo pipefail

PKG="com.codez.lahore_speedo_bus_guide"
OUT="${1:-/tmp/opencode/shots}"
ADB="${ADB:-adb}"
S="$ADB -s emulator-5554"

mkdir -p "$OUT"
PASS=0; FAIL=0
DUMP=/tmp/opencode/ui.xml

dump() { $S shell uiautomator dump /sdcard/ui.xml >/dev/null 2>&1; $S pull /sdcard/ui.xml "$DUMP" >/dev/null 2>&1; }

# assert_text <label> <expected text>
assert_text() {
  local label="$1" want="$2"
  dump
  if grep -q "$want" "$DUMP" 2>/dev/null; then
    echo "  PASS  $label  (found '$want')"; PASS=$((PASS+1)); return 0
  fi
  echo "  FAIL  $label  (expected '$want' on screen)"; FAIL=$((FAIL+1)); return 1
}

# assert_absent <label> <text that must NOT be there>
assert_absent() {
  local label="$1" bad="$2"
  dump
  if grep -q "$bad" "$DUMP" 2>/dev/null; then
    echo "  FAIL  $label  ('$bad' should not be present)"; FAIL=$((FAIL+1)); return 1
  fi
  echo "  PASS  $label  ('$bad' correctly absent)"; PASS=$((PASS+1)); return 0
}

shot() { sleep "${2:-2}"; $S exec-out screencap -p > "$OUT/$1.png" 2>/dev/null; echo "  shot: $1.png"; }

# tap_until <label> <x> <y> <text that must appear>
tap_until() {
  local label="$1" x="$2" y="$3" want="$4"
  for _ in 1 2 3 4 5; do
    $S shell input tap "$x" "$y"
    sleep 3
    dump
    if grep -q "$want" "$DUMP" 2>/dev/null; then
      echo "  PASS  $label  (tapped $x,$y -> '$want')"; PASS=$((PASS+1)); return 0
    fi
  done
  echo "  FAIL  $label  (tapped $x,$y but '$want' never appeared)"; FAIL=$((FAIL+1)); return 1
}

echo "===== 1. launch ====="
$S shell am force-stop "$PKG"; sleep 2
$S logcat -c
$S shell am start -n "$PKG/.MainActivity" >/dev/null 2>&1
sleep 30
assert_text "home title"          "Lahore"
assert_text "home tagline"        "Every route, one tap away"
assert_text "from placeholder"    "From . pick a stop"
assert_text "to placeholder"      "To . pick a stop"
assert_text "find routes button"  "Find Routes"
assert_text "how it works"        "HOW IT WORKS"
assert_text "tab: home"           "Home"
assert_text "tab: nearby"         "Nearby"
assert_text "tab: schedule"       "Schedule"
assert_text "tab: settings"       "Settings"
shot 10_home 2

echo
echo "===== 2. Home -> stop picker (FROM) ====="
tap_until "open FROM picker" 90 559 "Type stop name"
assert_text "picker title"       "Select Departure Stop"
assert_text "use current loc"    "Use current location"
assert_text "all stops count"    "All Stops"
shot 11_stop_picker 2

echo
echo "===== 3. type in the stop search ====="
$S shell input text "Jinnah"; sleep 6
assert_text "search hit"         "Jinnah"
shot 12_stop_picker_search 2

echo
echo "===== 4. pick a stop -> back on Home ====="
tap_until "select first result" 200 620 "Every route, one tap away"
assert_text "from filled"        "Jinnah"
shot 13_home_from_filled 3

echo
echo "===== 5. Nearby tab ====="
tap_until "nearby tab" 270 1105 "Nearby Stops"
assert_text "nearby subtitle"    "Bus stops close to you"
# (with location granted the Nearby list - and its footer - is shown)
shot 14_nearby 3

echo
echo "===== 6. Schedule tab ====="
tap_until "schedule tab" 450 1105 "Bus Schedule"
assert_text "schedule title"     "Bus Schedule"
assert_text "route count"        "Routes"
assert_text "category speedo"    "Speedo"
assert_text "category metro"     "Metro"
assert_text "category electric"  "Electric"
assert_text "category orange"    "Orange Line"
shot 15_schedule 3

echo
echo "===== 7. Schedule -> route detail ====="
tap_until "open a route" 300 740 "NEXT DEPARTURES"
assert_text "route detail header"  "Stops"
assert_text "fare box"            "FARE"
assert_text "frequency box"       "FREQUENCY"
assert_text "hours box"           "HOURS"
assert_text "total stops box"     "TOTAL STOPS"
shot 16_route_detail 3

echo
echo "===== 8. back ====="
$S shell input keyevent KEYCODE_BACK; sleep 4
assert_text "back on schedule"   "Bus Schedule"

echo
echo "===== 9. Settings tab ====="
tap_until "settings tab" 630 1105 "Manage your preferences"
assert_text "dark mode row"      "Dark Mode"
assert_text "dark mode off"      "Currently off"
assert_text "disclaimer"         "unofficial companion app"
assert_text "section contact"    "CONTACT"
assert_text "website row"        "Visit our Website"
assert_text "feedback row"       "Send Feedback"
shot 17_settings 3

echo
echo "===== 10. toggle dark mode ====="
tap_until "toggle dark mode" 580 385 "Currently on"
assert_text "dark mode on"       "Currently on"
shot 18_dark_mode 3

echo
echo "===== 11. back to home (dark) ====="
tap_until "home tab" 90 1105 "Every route, one tap away"
shot 19_home_dark 3

echo
echo "===== 12. search screen ====="
tap_until "open search" 645 120 "Search Routes"
assert_text "search title"       "Search Routes"
$S shell input text "Speedo"; sleep 4
assert_text "search results"     "Speedo"
shot 20_search 3

echo
echo "===== 13. app errors in logcat ====="
ERRS=$($S logcat -d 2>/dev/null | grep -icE "FATAL EXCEPTION|NoSuchMethodError|UnsatisfiedLinkError|Falling back to in-memory")
if [[ "$ERRS" == "0" ]]; then
  echo "  PASS  no fatal errors in logcat"; PASS=$((PASS+1))
else
  echo "  FAIL  $ERRS error lines in logcat"; FAIL=$((FAIL+1))
  $S logcat -d 2>/dev/null | grep -iE "FATAL EXCEPTION|NoSuchMethodError|UnsatisfiedLinkError|Falling back" | head -5
fi

echo
echo "===== SUMMARY ====="
echo "  passed: $PASS"
echo "  failed: $FAIL"
[[ $FAIL -eq 0 ]] && exit 0 || exit 1
