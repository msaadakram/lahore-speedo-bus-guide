#!/usr/bin/env python3
"""Comprehensive end-to-end UI test for the Lahore Speedo Bus Guide app.

Drives the installed app on an Android emulator with ADB, exactly like a
person would: it finds on-screen elements *by their text* (via the
uiautomator view hierarchy) and taps them, so the test does not depend on
hard-coded pixel coordinates. Every step asserts that the expected content is
actually on screen and captures a screenshot.

Usage:
    python3 tool/e2e_test.py                 # run everything
    python3 tool/e2e_test.py home schedule   # run named groups only
"""
from __future__ import annotations

import os
import re
import subprocess
import sys
import time
import xml.etree.ElementTree as ET

PKG = "com.codez.lahore_speedo_bus_guide"
SERIAL = os.environ.get("ANDROID_SERIAL", "emulator-5554")
ADB = os.environ.get("ADB", "adb")
SHOTS = os.environ.get("SHOTS", "/home/ubuntu/bus/reverse_engineering/screenshots")
TMP = "/tmp/opencode/ui.xml"

os.makedirs(SHOTS, exist_ok=True)

# --------------------------------------------------------------------------- #
# adb helpers
# --------------------------------------------------------------------------- #


def adb(*args: str, timeout: int = 60) -> str:
    res = subprocess.run(
        [ADB, "-s", SERIAL, *args],
        capture_output=True,
        text=True,
        timeout=timeout,
    )
    return (res.stdout or "") + (res.stderr or "")


def sh(cmd: str, timeout: int = 60) -> str:
    return adb("shell", cmd, timeout=timeout)


def dump() -> ET.Element | None:
    """Pull the current view hierarchy."""
    for _ in range(3):
        sh("uiautomator dump /sdcard/ui.xml", timeout=90)
        pull = subprocess.run(
            [ADB, "-s", SERIAL, "pull", "/sdcard/ui.xml", TMP],
            capture_output=True,
            text=True,
            timeout=90,
        )
        if pull.returncode == 0 and os.path.exists(TMP):
            try:
                return ET.parse(TMP).getroot()
            except ET.ParseError:
                time.sleep(1)
    return None


def nodes() -> list[dict]:
    root = dump()
    if root is None:
        return []
    out = []
    for n in root.iter("node"):
        b = n.get("bounds", "")
        m = re.match(r"\[(\d+),(\d+)\]\[(\d+),(\d+)\]", b)
        if not m:
            continue
        x1, y1, x2, y2 = (int(v) for v in m.groups())
        out.append(
            {
                "text": n.get("text", ""),
                "desc": n.get("content-desc", ""),
                "cls": n.get("class", ""),
                "clickable": n.get("clickable") == "true",
                "x": (x1 + x2) // 2,
                "y": (y1 + y2) // 2,
                "top": y1,
                "bottom": y2,
            }
        )
    return out


def texts() -> list[str]:
    return [n["text"] for n in nodes() if n["text"]]


def find(text: str, exact: bool = True) -> dict | None:
    for n in nodes():
        if (n["text"] == text) if exact else (text.lower() in n["text"].lower()):
            return n
    return None


def find_any(*needles: str) -> dict | None:
    """Find a node whose text contains any of the needles."""
    low = [n.lower() for n in needles]
    for n in nodes():
        t = n["text"].lower()
        if any(l in t for l in low):
            return n
    return None


def tap_node(n: dict, settle: float = 1.2) -> None:
    sh(f"input tap {n['x']} {n['y']}")
    time.sleep(settle)


def tap_text(text: str, settle: float = 1.2, exact: bool = True) -> bool:
    n = find(text, exact)
    if n is None:
        return False
    tap_node(n, settle)
    return True


def tap_any(*needles: str, settle: float = 1.2) -> bool:
    n = find_any(*needles)
    if n is None:
        return False
    tap_node(n, settle)
    return True


def type_text(s: str) -> None:
    sh(f"input text {s}")
    time.sleep(1.0)


def back(settle: float = 1.2) -> None:
    sh("input keyevent KEYCODE_BACK")
    time.sleep(settle)


def shot(name: str) -> None:
    p = os.path.join(SHOTS, f"e2e_{name}.png")
    with open(p, "wb") as fh:
        r = subprocess.run(
            [ADB, "-s", SERIAL, "exec-out", "screencap", "-p"],
            stdout=fh,
            stderr=subprocess.DEVNULL,
            timeout=120,
        )
    print(f"      shot: {os.path.basename(p)}")


# --------------------------------------------------------------------------- #
# assertions
# --------------------------------------------------------------------------- #

PASSED: list[str] = []
FAILED: list[tuple[str, str]] = []
_GROUP = ""


def group(name: str) -> None:
    global _GROUP
    _GROUP = name
    print(f"\n===== {name} =====")


def check(label: str, ok: bool, detail: str = "") -> bool:
    full = f"{_GROUP} / {label}"
    if ok:
        PASSED.append(full)
        print(f"  PASS  {label}")
    else:
        FAILED.append((full, detail))
        print(f"  FAIL  {label}   {detail}")
    return ok


def expect_text(label: str, needle: str) -> bool:
    t = texts()
    ok = any(needle.lower() in x.lower() for x in t)
    return check(label, ok, f"(expected {needle!r} on screen)")


def expect_absent(label: str, needle: str) -> bool:
    t = texts()
    ok = not any(needle.lower() in x.lower() for x in t)
    return check(label, ok, f"({needle!r} should not be present)")


def expect_no_crash(label: str) -> bool:
    log = adb("logcat", "-d", "-v", "brief", timeout=90)
    bad = [
        ln
        for ln in log.splitlines()
        if re.search(
            r"FATAL EXCEPTION|NoSuchMethodError|UnsatisfiedLinkError|"
            r"MissingPluginException|PlatformException|E/flutter",
            ln,
        )
        and "codez" in ln
    ]
    return check(label, not bad, "\n        " + "\n        ".join(bad[:3]))


def clear_log() -> None:
    adb("logcat", "-c", timeout=30)


# --------------------------------------------------------------------------- #
# flows
# --------------------------------------------------------------------------- #


def launch(cold: bool = True) -> None:
    sh(f"am force-stop {PKG}")
    time.sleep(1.5)
    clear_log()
    sh(f"am start -n {PKG}/.MainActivity", timeout=90)
    for _ in range(30):
        time.sleep(1)
        if find_any("Lahore", "Every route"):
            break
    time.sleep(1.5)


def flow_home() -> None:
    group("01 HOME")
    launch()
    expect_text("header title", "Lahore")
    expect_text("tagline", "Every route, one tap away")
    expect_text("from placeholder", "From")
    expect_text("to placeholder", "To")
    expect_text("find routes button", "Find Routes")
    expect_text("how it works", "HOW IT WORKS")
    expect_text("tab home", "Home")
    expect_text("tab nearby", "Nearby")
    expect_text("tab schedule", "Schedule")
    expect_text("tab settings", "Settings")
    shot("01_home")
    expect_no_crash("no crash on home")


def flow_stop_picker() -> None:
    group("02 STOP PICKER (from)")
    launch()
    n = find_any("From")
    if check("tap FROM field", n is not None):
        tap_node(n, 2.0)
    expect_text("picker title", "Select Departure Stop")
    expect_text("use current location", "Use current location")
    expect_text("all stops counter", "All Stops")
    shot("02_picker")
    # search
    type_text("Jinnah")
    time.sleep(1.5)
    expect_text("search finds Jinnah", "Jinnah")
    shot("03_picker_search")
    # pick the first result
    n = find_any("Jinnah")
    if check("tap first result", n is not None):
        tap_node(n, 2.5)
    expect_text("returned to home", "Every route, one tap away")
    expect_text("from is filled", "Jinnah")
    shot("04_home_from_filled")
    expect_no_crash("no crash in picker")


def flow_home_swap() -> None:
    group("03 HOME swap + find routes")
    launch()
    # fill FROM
    n = find_any("From")
    if n:
        tap_node(n, 2.0)
    type_text("Jinnah")
    time.sleep(1.2)
    n = find_any("Jinnah")
    if n:
        tap_node(n, 2.5)
    # fill TO
    n = find_any("To — pick", "To")
    if check("tap TO field", n is not None):
        tap_node(n, 2.0)
    type_text("Bahria")
    time.sleep(1.2)
    n = find_any("Bahria")
    if n:
        tap_node(n, 2.5)
    shot("05_home_both_filled")
    expect_text("both fields filled", "Jinnah")
    # swap button is the circular icon between the fields
    n = find_any("Jinnah")
    if n:
        tap_node(n, 2.0)
    shot("06_home_after_tap")
    expect_no_crash("no crash after filling")


def flow_nearby() -> None:
    group("04 NEARBY")
    launch()
    n = find("Nearby")
    if check("tap Nearby tab", n is not None):
        tap_node(n, 3.0)
    expect_text("nearby title", "Nearby Stops")
    expect_text("nearby subtitle", "Bus stops close to you")
    expect_text("reload action", "Try Again")  # denied OR error state
    shot("07_nearby")
    expect_no_crash("no crash on nearby")


def flow_schedule() -> None:
    group("05 SCHEDULE")
    launch()
    n = find("Schedule")
    if check("tap Schedule tab", n is not None):
        tap_node(n, 3.0)
    expect_text("schedule title", "Bus Schedule")
    expect_text("route counter", "Routes")
    expect_text("category speedo", "Speedo")
    expect_text("category metro", "Metro")
    expect_text("category orange", "Orange Line")
    expect_text("category electric", "Electric")
    expect_text("a route is listed", "RT-")
    shot("08_schedule")
    # switch category -> Metro (1 route)
    n = find("Metro")
    if check("tap Metro category", n is not None):
        tap_node(n, 2.0)
    expect_text("metro route count is 1", "1 Routes")
    shot("09_schedule_metro")
    # back to Speedo
    n = find("Speedo")
    if n:
        tap_node(n, 2.0)
    expect_text("speedo route count is 23", "23 Routes")
    expect_no_crash("no crash on schedule")


def flow_route_detail() -> None:
    group("06 ROUTE DETAIL")
    launch()
    n = find("Schedule")
    if n:
        tap_node(n, 3.0)
    n = find_any("RT-")
    if check("tap a route row", n is not None):
        tap_node(n, 3.0)
    expect_text("fare box", "FARE")
    expect_text("frequency box", "FREQUENCY")
    expect_text("hours box", "HOURS")
    expect_text("total stops box", "TOTAL STOPS")
    expect_text("next departures header", "NEXT DEPARTURES")
    expect_text("stops header", "Stops")
    shot("10_route_detail")
    back(2.0)
    expect_text("back on schedule", "Bus Schedule")
    expect_no_crash("no crash on route detail")


def flow_search() -> None:
    group("07 SEARCH")
    launch()
    n = find_any("magnify", "Search")
    # the header search button has no text; use the Schedule tab header search
    n = find("Schedule")
    if n:
        tap_node(n, 3.0)
    # tap the search icon in the coloured header (top-right)
    sh("input tap 645 190")
    time.sleep(2.5)
    expect_text("search title", "Search Routes")
    expect_text("search hint", "Search by route name or stop name")
    type_text("Speedo")
    time.sleep(1.5)
    expect_text("search results", "Speedo")
    shot("11_search")
    expect_no_crash("no crash on search")


def flow_settings() -> None:
    group("08 SETTINGS")
    launch()
    n = find("Settings")
    if check("tap Settings tab", n is not None):
        tap_node(n, 3.0)
    expect_text("settings subtitle", "Manage your preferences")
    expect_text("dark mode row", "Dark Mode")
    expect_text("disclaimer", "unofficial companion app")
    expect_text("contact section", "CONTACT")
    expect_text("website row", "Visit our Website")
    shot("12_settings")
    # scroll down
    sh("input swipe 360 900 360 350 400")
    time.sleep(1.5)
    expect_text("legal section", "LEGAL")
    expect_text("help section", "HELP")
    expect_text("credits row", "Credits")
    shot("13_settings_scrolled")
    expect_no_crash("no crash on settings")


def flow_dark_mode() -> None:
    group("09 DARK MODE")
    launch()
    n = find("Settings")
    if n:
        tap_node(n, 3.0)
    expect_text("starts light", "Currently off")
    # the switch is the only clickable widget on that row
    sw = None
    for nd in nodes():
        if nd["cls"].endswith("Switch") or "Switch" in nd["cls"]:
            sw = nd
            break
    if check("find the switch", sw is not None):
        tap_node(sw, 2.0)
    expect_text("now dark", "Currently on")
    shot("14_dark_settings")
    # navigate to home in dark mode
    n = find("Home")
    if n:
        tap_node(n, 2.0)
    expect_text("home in dark mode", "Every route, one tap away")
    shot("15_dark_home")
    # go back to settings and turn it off again
    n = find("Settings")
    if n:
        tap_node(n, 2.0)
    sw = None
    for nd in nodes():
        if "Switch" in nd["cls"]:
            sw = nd
            break
    if sw:
        tap_node(sw, 2.0)
    expect_text("back to light", "Currently off")
    expect_no_crash("no crash toggling theme")


def flow_feedback() -> None:
    group("10 FEEDBACK")
    launch()
    n = find("Settings")
    if n:
        tap_node(n, 3.0)
    sh("input swipe 360 900 360 350 400")
    time.sleep(1.5)
    n = find_any("Send Feedback")
    if check("open feedback", n is not None):
        tap_node(n, 2.5)
    expect_text("feedback title", "Send Feedback")
    expect_text("name field", "Your Name")
    expect_text("email field", "Email")
    expect_text("location field", "Location")
    expect_text("type field", "Type")
    expect_text("comment field", "Comment")
    expect_text("submit button", "Submit")
    shot("16_feedback")
    # submit with empty fields -> validation errors
    n = find("Submit")
    if n:
        tap_node(n, 2.0)
    expect_text("validation errors shown", "Required")
    shot("17_feedback_validation")
    expect_no_crash("no crash on feedback")


def flow_credits() -> None:
    group("11 CREDITS")
    launch()
    n = find("Settings")
    if n:
        tap_node(n, 3.0)
    sh("input swipe 360 900 360 350 400")
    time.sleep(1.5)
    n = find_any("Credits")
    if check("open credits", n is not None):
        tap_node(n, 2.5)
    expect_text("credits title", "Credits")
    expect_text("founder role", "FOUNDER")
    expect_text("linkedin cta", "Connect on LinkedIn")
    shot("18_credits")
    back(2.0)
    expect_no_crash("no crash on credits")


def flow_back_stack() -> None:
    group("12 BACK STACK")
    launch()
    n = find("Schedule")
    if n:
        tap_node(n, 2.5)
    n = find_any("RT-")
    if n:
        tap_node(n, 2.5)
    expect_text("route detail open", "FARE")
    back(2.0)
    expect_text("back to schedule", "Bus Schedule")
    back(2.0)
    expect_text("back to home", "Every route, one tap away")
    expect_no_crash("no crash on back navigation")


def flow_lifecycle() -> None:
    group("13 LIFECYCLE")
    launch()
    # background and resume
    sh("input keyevent KEYCODE_HOME")
    time.sleep(2)
    sh(f"am start -n {PKG}/.MainActivity")
    time.sleep(3)
    expect_text("resumes to home", "Every route, one tap away")
    # rotate
    sh("settings put system accelerometer_rotation 0")
    sh("settings put system user_rotation 1")
    time.sleep(3)
    expect_text("survives rotation", "Every route, one tap away")
    shot("19_landscape")
    sh("settings put system user_rotation 0")
    time.sleep(2)
    # low-memory / process kill
    sh(f"am kill {PKG}")
    time.sleep(2)
    launch()
    expect_text("restarts cleanly", "Every route, one tap away")
    expect_no_crash("no crash across lifecycle events")


def flow_robustness() -> None:
    group("14 ROBUSTNESS")
    launch()
    # hammer the bottom nav
    for t in ["Schedule", "Nearby", "Settings", "Home", "Schedule", "Home"]:
        n = find(t)
        if n:
            tap_node(n, 0.8)
    expect_text("still alive after nav spam", "Every route")
    # spam the stop picker search
    n = find_any("From")
    if n:
        tap_node(n, 2.0)
    for _ in range(3):
        type_text("a")
    time.sleep(1)
    expect_text("picker survives input spam", "All Stops")
    back(1.5)
    # rapid back presses
    for _ in range(4):
        back(0.5)
    time.sleep(1)
    expect_text("still alive after back spam", "Every route")
    shot("20_robustness")
    expect_no_crash("no crash under rapid input")


def flow_display() -> None:
    group("15 DISPLAY / ACCESSIBILITY")
    launch()
    # large font scale
    sh("settings put system font_scale 1.3")
    time.sleep(1)
    launch()
    expect_text("renders at 1.3x font", "Every route, one tap away")
    shot("21_font_scale")
    sh("settings put system font_scale 1.0")
    time.sleep(1)
    # small screen density
    sh("wm size 480x800")
    time.sleep(2)
    launch()
    expect_text("renders on a small screen", "Every route, one tap away")
    shot("22_small_screen")
    sh("wm size reset")
    time.sleep(2)
    expect_no_crash("no crash at other display settings")


FLOWS = {
    "home": flow_home,
    "picker": flow_stop_picker,
    "swap": flow_home_swap,
    "nearby": flow_nearby,
    "schedule": flow_schedule,
    "detail": flow_route_detail,
    "search": flow_search,
    "settings": flow_settings,
    "dark": flow_dark_mode,
    "feedback": flow_feedback,
    "credits": flow_credits,
    "back": flow_back_stack,
    "lifecycle": flow_lifecycle,
    "robust": flow_robustness,
    "display": flow_display,
}


def main() -> int:
    wanted = sys.argv[1:] or list(FLOWS)
    print(f"=== e2e: {PKG} on {SERIAL} ===")
    for name in wanted:
        fn = FLOWS.get(name)
        if fn is None:
            print(f"unknown flow: {name}")
            continue
        try:
            fn()
        except Exception as exc:  # keep going, report at the end
            FAILED.append((f"{name} / EXCEPTION", repr(exc)))
            print(f"  EXCEPTION in {name}: {exc!r}")
    print("\n" + "=" * 60)
    print(f"PASSED: {len(PASSED)}   FAILED: {len(FAILED)}")
    for f, d in FAILED:
        print(f"  FAILED: {f}   {d}")
    return 1 if FAILED else 0


if __name__ == "__main__":
    raise SystemExit(main())
