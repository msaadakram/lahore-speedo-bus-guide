#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# run_emulator.sh — boot a headless Android emulator for on-device testing.
#
# KVM ON THIS HOST
# ----------------
# Hardware virtualisation IS available here:
#   * the CPU exposes VMX (verified with a raw CPUID leaf-1 check: bit 5 set)
#   * `sudo modprobe kvm_intel` binds successfully and creates /dev/kvm
#   * `ioctl(/dev/kvm, KVM_GET_API_VERSION)` returns 12
#
# The one catch: the emulator's own ProbeKVM insists that the *calling
# process* has the `kvm` group in its supplementary groups, not merely
# read/write permission on the node. `usermod -aG kvm` only affects new
# logins, so a long-running shell session still lacks it. The fix is to run
# the emulator through `sg kvm -c "..."`.
#
# Run `sudo tool/enable_kvm.sh` once to load the module and install a udev
# rule; after that this script boots the emulator with hardware acceleration
# (~10 s instead of ~6 min under TCG).
#
# Usage: tool/run_emulator.sh [api] [arch]
# ---------------------------------------------------------------------------
set -uo pipefail

SDK="${ANDROID_HOME:-$HOME/Android/Sdk}"
API="${1:-30}"
ARCH="${2:-x86_64}"
AVD="test-${API}-${ARCH}"

export PATH="$SDK/platform-tools:$SDK/emulator:$SDK/cmdline-tools/latest/bin:$PATH"

kvm_usable() {
  [[ -e /dev/kvm && -r /dev/kvm ]] || return 1
  python3 -c "import os,fcntl,sys; fd=os.open('/dev/kvm',os.O_RDWR); sys.exit(0 if fcntl.ioctl(fd,0xAE00,0)==12 else 1)" 2>/dev/null
}

ACCEL="off"
if kvm_usable; then
  ACCEL="on"
  echo "== KVM available: hardware acceleration ENABLED =="
else
  echo "== KVM unavailable: software emulation (slow) =="
  echo "   run: sudo tool/enable_kvm.sh"
fi

# The emulator requires the kvm *group*, not just file permissions.
NEED_SG=0
if [[ "$ACCEL" == "on" ]] && getent group kvm >/dev/null \
   && ! id -nG | tr ' ' '\n' | grep -qx kvm; then
  NEED_SG=1
  echo "   (this shell session has not picked up the 'kvm' group -> using 'sg kvm')"
fi

echo "== creating AVD $AVD (api $API, $ARCH) =="
if ! avdmanager list avd 2>/dev/null | grep -q "Name: $AVD"; then
  echo no | avdmanager create avd \
    -n "$AVD" -k "system-images;android-$API;default;$ARCH" \
    -d pixel_2 --force >/dev/null 2>&1
fi

CFG="$HOME/.android/avd/$AVD.avd/config.ini"
if [[ -f "$CFG" ]]; then
  # The file uses "key = value" (with spaces); a `key=value` sed is a no-op.
  sed -i -E 's/^disk\.dataPartition\.size\s*=.*/disk.dataPartition.size = 6G/' "$CFG"
  sed -i -E 's/^hw\.lcd\.width\s*=.*/hw.lcd.width = 720/' "$CFG"
  sed -i -E 's/^hw\.lcd\.height\s*=.*/hw.lcd.height = 1280/' "$CFG"
  sed -i -E 's/^hw\.lcd\.density\s*=.*/hw.lcd.density = 320/' "$CFG"
  sed -i -E 's/^hw\.ramSize\s*=.*/hw.ramSize = 2048M/' "$CFG"
  grep -q '^hw.keyboard' "$CFG" || echo "hw.keyboard = yes" >> "$CFG"
  grep -q '^hw.audioInput' "$CFG" || echo "hw.audioInput = no" >> "$CFG"
  grep -q '^hw.audioOutput' "$CFG" || echo "hw.audioOutput = no" >> "$CFG"
fi

# The emulator re-reads emu-launch-params.txt on every start; a stale
# "-port" in it makes the bundled QEMU abort.
cat > "$HOME/.android/avd/$AVD.avd/emu-launch-params.txt" <<EOF
$(pwd)
$SDK/emulator/emulator
16
emulator
-avd
$AVD
-no-window
-no-audio
-no-boot-anim
-no-snapshot
-gpu
swiftshader_indirect
-accel
$ACCEL
EOF

# NOTE: must be a single line - a newline inside the `sg -c "..."` string
# breaks the command and the emulator never starts.
EMU_ARGS="-avd $AVD -no-window -no-audio -no-boot-anim -no-snapshot -gpu swiftshader_indirect -accel $ACCEL -qemu -smp 4 -m 2048"

echo "== booting (accel=$ACCEL) =="
if [[ $NEED_SG -eq 1 ]]; then
  # Use a tiny wrapper script so no quoting is involved: nesting a long
  # command line inside `sg -c "..."` is what kept breaking the launch.
  LAUNCHER=/tmp/opencode/launch_emulator.sh
  cat > "$LAUNCHER" <<LAUNCH
#!/bin/bash
exec $SDK/emulator/emulator $EMU_ARGS
LAUNCH
  chmod +x "$LAUNCHER"
  nohup sg kvm -c "$LAUNCHER" > /tmp/opencode/emulator.log 2>&1 < /dev/null &
else
  LAUNCHER=/tmp/opencode/launch_emulator.sh
  cat > "$LAUNCHER" <<LAUNCH
#!/bin/bash
exec $SDK/emulator/emulator $EMU_ARGS
LAUNCH
  chmod +x "$LAUNCHER"
  nohup "$LAUNCHER" > /tmp/opencode/emulator.log 2>&1 < /dev/null &
fi
disown

echo "== waiting for boot =="
START=$(date +%s)
adb -s emulator-5554 wait-for-device
for i in $(seq 1 150); do
  BOOT=$(adb -s emulator-5554 shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')
  if [[ "$BOOT" == "1" ]]; then
    echo "== booted in $(( $(date +%s) - START ))s =="
    adb -s emulator-5554 shell settings put global window_animation_scale 0
    adb -s emulator-5554 shell settings put global transition_animation_scale 0
    adb -s emulator-5554 shell settings put global animator_duration_scale 0
    exit 0
  fi
  sleep 2
done

echo "!! emulator did not boot in time" >&2
tail -30 /tmp/opencode/emulator.log >&2
exit 1
