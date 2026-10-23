#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# verify_release_dex.sh
#
# Guards against the class of release-only breakage that produced a blank
# screen: R8 removing classes that are resolved **by name** at runtime.
#
# Two categories are checked:
#   1. Every plugin's registration class listed in GeneratedPluginRegistrant.
#   2. The JNI bridge packages (com.github.dart_lang.jni*) that the Dart side
#      resolves over JNI. These are invisible to R8's reachability analysis
#      because no Java code calls them.
#
# Usage:  tool/verify_release_dex.sh [path/to/apk]
# Exit:   0 = all present, 1 = something is missing.
# ---------------------------------------------------------------------------
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APK="${1:-$ROOT/build/app/outputs/flutter-apk/app-release.apk}"

if [[ ! -f "$APK" ]]; then
  echo "APK not found: $APK" >&2
  echo "Build one first:  flutter build apk --release" >&2
  exit 2
fi

echo "Verifying: $APK"

# Dex type descriptors use the slash form (Lcom/example/Foo;), while Java
# source uses the dot form (com.example.Foo). Check both.
DEX_STRINGS="$(mktemp)"
trap 'rm -f "$DEX_STRINGS"' EXIT
while IFS= read -r entry; do
  unzip -p "$APK" "$entry" 2>/dev/null | strings >> "$DEX_STRINGS"
done < <(unzip -Z1 "$APK" | grep -E '^classes[0-9]*\.dex$')

# Slash-form copy of the strings so a class can be matched either way.
DEX_SLASH="$(mktemp)"
trap 'rm -f "$DEX_STRINGS" "$DEX_SLASH"' EXIT
sed 's|\.|/|g' "$DEX_STRINGS" > "$DEX_SLASH"

# has_class <dot.form.Name>
has_class() {
  local dot="$1" slash
  slash="L$(printf '%s' "$dot" | tr '.' '/');"
  grep -qF "$dot" "$DEX_STRINGS" && return 0
  grep -qF "$slash" "$DEX_SLASH" && return 0
  return 1
}

fail=0

# --- 1. plugin registration classes ---------------------------------------
REGISTRANT="$ROOT/android/app/src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java"
if [[ -f "$REGISTRANT" ]]; then
  echo
  echo "Plugin registration classes:"
  while IFS= read -r cls; do
    [[ -z "$cls" ]] && continue
    # Skip dev-only plugins: they are not part of the shipped app.
    case "$cls" in
      *integration_test*|*IntegrationTest*) continue ;;
    esac
    if has_class "$cls"; then
      printf '  OK    %s\n' "$cls"
    else
      printf '  MISS  %s   <-- stripped by R8\n' "$cls"
      fail=1
    fi
  done < <(grep -oE 'new [a-zA-Z0-9_.]+\(\)' "$REGISTRANT" \
            | sed -E 's/new //; s/\(\)//' | sort -u)
fi

# --- 2. JNI bridge packages -------------------------------------------------
echo
echo "JNI bridge packages (resolved by name from Dart):"
for pkg in com.github.dart_lang.jni com.github.dart_lang.jni_flutter; do
  if has_class "$pkg" || grep -qF "$pkg" "$DEX_STRINGS"; then
    printf '  OK    %s\n' "$pkg"
  else
    printf '  MISS  %s   <-- R8 deleted it; JNI lookups will fail at runtime\n' "$pkg"
    fail=1
  fi
done

# --- 2b. plugin v2 API registrars (resolved by name from Dart) -------------
# Only plugins that implement the v2 plugin API expose an `*ApiRegistrar`
# class; the Dart side resolves it by name. The expected list is derived from
# the plugin sources in the pub cache so it cannot drift.
echo
echo "Plugin API registrars (resolved by name from Dart):"
REGISTRARS=()
# The v2 API registrar classes are *code generated* (pigeon / jnigen) during
# the Gradle build, so they are not in the pub cache. Scan the build output.
while IFS= read -r f; do
  # .../kotlin-classes/release/io/flutter/plugins/shared_preferences/X.class
  rel="${f#*kotlin-classes/}"
  rel="${rel#*/}"                      # drop the build variant
  cls=$(basename "$rel" .class)
  cls="${cls%%\$*}"                   # drop any inner-class suffix
  pkg=$(dirname "$rel" | tr '/' '.')
  REGISTRARS+=("$pkg.$cls")
done < <(find "$ROOT/build" -path "*kotlin-classes/release/*" -name "*ApiRegistrar*.class" 2>/dev/null | sort -u)

if [[ ${#REGISTRARS[@]} -gt 0 ]]; then
  mapfile -t REGISTRARS < <(printf '%s\n' "${REGISTRARS[@]}" | sort -u)
fi

if [[ ${#REGISTRARS[@]} -eq 0 ]]; then
  echo "  (none generated - nothing to check)"
else
  for cls in "${REGISTRARS[@]}"; do
    if has_class "$cls"; then
      printf '  OK    %s\n' "$cls"
    else
      printf '  MISS  %s   <-- R8 deleted it; the plugin will throw NoSuchMethodError\n' "$cls"
      fail=1
    fi
  done
fi

# --- 2c. JNI classes looked up by their literal JVM name -------------------
# package:jni resolves these with JClass.forName(...). R8 renaming any of
# them changes the descriptor of the methods that take them and breaks the
# JNI lookup with a NoSuchMethodError.
echo
echo "JNI class-name lookups:"
for cls in \
  "kotlin.coroutines.Continuation" \
  "kotlin.Result" \
  "java.nio.Buffer" \
  "java.nio.ByteBuffer"; do
  if has_class "$cls"; then
    printf '  OK    %s\n' "$cls"
  else
    printf '  MISS  %s   <-- R8 renamed it; JNI lookups will fail at runtime\n' "$cls"
    fail=1
  fi
done

# --- 3. Flutter engine entry points ----------------------------------------
echo
echo "Flutter engine:"
for cls in io.flutter.embedding.android.FlutterActivity \
           io.flutter.embedding.engine.FlutterEngine \
           io.flutter.plugins.GeneratedPluginRegistrant; do
  if has_class "$cls"; then
    printf '  OK    %s\n' "$cls"
  else
    printf '  MISS  %s\n' "$cls"
    fail=1
  fi
done

# --- 4. the app's own entry point ------------------------------------------
echo
echo "Application entry point:"
if has_class "com.codez.lahore_speedo_bus_guide.MainActivity"; then
  echo "  OK    com.codez.lahore_speedo_bus_guide.MainActivity"
else
  echo "  MISS  com.codez.lahore_speedo_bus_guide.MainActivity"
  fail=1
fi

echo
if [[ $fail -eq 0 ]]; then
  echo "RESULT: PASS — every runtime-resolved class is present in the release dex."
else
  echo "RESULT: FAIL — a class resolved by name is missing from the release dex."
  echo "        This causes a blank screen. Add a -keep rule in"
  echo "        android/app/proguard-rules.pro and rebuild."
fi
exit $fail
