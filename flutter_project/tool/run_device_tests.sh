#!/usr/bin/env bash
# Run the on-device integration suite against a live emulator.
# Usage: tool/run_device_tests.sh [serial]
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export PATH="$HOME/flutter/bin:$HOME/Android/Sdk/platform-tools:$PATH"

SERIAL="${1:-$(adb devices | awk '/^emulator-/{print $1; exit}')}"
LOG="${LOG:-/tmp/opencode/device_tests.log}"
mkdir -p "$(dirname "$LOG")"

echo "device: $SERIAL"
cd "$ROOT"
flutter test integration_test/app_test.dart -d "$SERIAL" --timeout 180s > "$LOG" 2>&1
echo "exit=$?" >> "$LOG"
tail -25 "$LOG"
