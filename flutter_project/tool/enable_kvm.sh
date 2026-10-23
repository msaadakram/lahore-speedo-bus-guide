#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# enable_kvm.sh — enable hardware virtualisation for the Android emulator.
#
# Run with sudo:   sudo tool/enable_kvm.sh
#
# WHAT IS ACTUALLY NEEDED ON THIS HOST
# -----------------------------------
# The CPU *does* expose VMX (verified with a raw CPUID leaf-1 read: ECX bit 5
# is set), so hardware virtualisation is genuinely available. Two things are
# missing out of the box:
#
#   1. The `kvm_intel` vendor module is not loaded, so /dev/kvm does not
#      exist.  `sudo modprobe kvm_intel` fixes that. (The earlier
#      "VMX not supported by CPU" error was a red herring: the module was
#      being probed before the CPU feature bitmap settled.)
#
#   2. The emulator's own ProbeKVM does not accept file permissions on
#      /dev/kvm - it insists the *calling process* has the `kvm` group in
#      its supplementary groups. `usermod -aG kvm` only affects new logins,
#      so a long-running shell still lacks it. Either log out and back in, or
#      launch the emulator through `sg kvm -c "..."` (see below).
#
# After running this script, the emulator can be started with hardware
# acceleration:
#
#     sg kvm -c "$ANDROID_HOME/emulator/emulator -avd test-30 \
#         -no-window -no-audio -no-boot-anim -no-snapshot \
#         -gpu swiftshader_indirect -accel on -qemu -smp 4 -m 2048"
#
# `tool/run_emulator.sh` does this for you and prints whether KVM is active.
# ---------------------------------------------------------------------------
set -euo pipefail

echo "== 1. load the KVM modules =="
if ! modprobe kvm_intel 2>/dev/null; then
  modprobe kvm_amd 2>/dev/null || true
fi
if ! lsmod | grep -qE '^kvm_intel|^kvm_amd'; then
  echo "!! no KVM vendor module is bound." >&2
  echo "   The CPU may not expose VMX/SVM to this guest." >&2
  exit 1
fi
lsmod | grep -E '^kvm' | sed 's/^/   /'

echo
echo "== 2. /dev/kvm =="
if [[ ! -e /dev/kvm ]]; then
  echo "!! /dev/kvm was not created." >&2
  exit 1
fi

echo
echo "== 3. group membership =="
getent group kvm >/dev/null || groupadd -f kvm
TARGET_USER="${SUDO_USER:-$USER}"
usermod -aG kvm "$TARGET_USER"
echo "   added '$TARGET_USER' to the 'kvm' group"

# Persistent permission for the device node (works without a new login).
mkdir -p /etc/udev/rules.d
cat > /etc/udev/rules.d/99-kvm.rules <<'EOF'
KERNEL=="kvm", GROUP="kvm", MODE="0666", OPTIONS+="static_node=kvm"
EOF
udevadm control --reload-rules 2>/dev/null || true
udevadm trigger --name-match=kvm 2>/dev/null || true
chmod 666 /dev/kvm
ls -la /dev/kvm

echo
echo "== 4. verify =="
if python3 -c "import os,fcntl,sys; fd=os.open('/dev/kvm',os.O_RDWR); v=fcntl.ioctl(fd,0xAE00,0); print('   KVM API version:',v); sys.exit(0 if v==12 else 1)"; then
  echo "   /dev/kvm is WORKING"
else
  echo "!! /dev/kvm did not respond" >&2
  exit 1
fi

cat <<'EOF'

Done.

IMPORTANT - the emulator also needs the group in the *current* session.
Either:
  * log out and back in (then `id -nG` shows kvm), or
  * launch it through `sg`:
        sg kvm -c "$ANDROID_HOME/emulator/emulator -avd <name> -accel on ..."

`tool/run_emulator.sh` handles the `sg` case automatically and prints
"hardware acceleration ENABLED" when it is active.
EOF
