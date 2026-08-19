#!/bin/zsh
set -euo pipefail

if (( $# < 2 || $# > 3 )); then
  echo "usage: $0 <base-unsigned.ipa> <output.ipa> [MCMIdentifiers.plist]" >&2
  exit 64
fi

BASE_IPA="${1:A}"
OUTPUT_IPA="${2:A}"
CATALOG="${3:-}"

if [[ -n "$CATALOG" ]]; then
  CATALOG="${CATALOG:A}"
fi

REPO_ROOT="${0:A:h:h}"
THEOS="${THEOS:-$HOME/theos}"
export THEOS

echo "==> Repository: $REPO_ROOT"
echo "==> Base IPA: $BASE_IPA"
echo "==> Output IPA: $OUTPUT_IPA"

[[ -f "$BASE_IPA" ]] || {
  echo "ERROR: base IPA not found: $BASE_IPA" >&2
  exit 66
}

if [[ -n "$CATALOG" ]]; then
  [[ -f "$CATALOG" ]] || {
    echo "ERROR: catalog not found: $CATALOG" >&2
    exit 66
  }

  plutil -lint "$CATALOG" >/dev/null
  plutil -extract AppData xml1 -o /dev/null "$CATALOG"
fi

cd "$REPO_ROOT"

echo "==> Cleaning previous build..."
make clean

echo "==> Building package..."
make package FINALPACKAGE=1

DYLIB="$REPO_ROOT/.theos/obj/FilzaSlop.dylib"
EMBEDDED_DYLIB="FilzaApplySandboxExt.dylib"

echo "==> Looking for built dylib..."
echo "Expected: $DYLIB"

[[ -f "$DYLIB" ]] || {
  echo "ERROR: built dylib not found: $DYLIB" >&2
  echo "Available dylibs:"
  find "$REPO_ROOT/.theos/obj" -name "*.dylib" -print 2>/dev/null || true
  exit 70
}

echo "==> Built dylib found:"
ls -lh "$DYLIB"

STAGE_ROOT="$(mktemp -d /tmp/FilzaSlop-release.XXXXXX)"

cleanup() {
  rm -rf "$STAGE_ROOT"
}

trap cleanup EXIT

mkdir -p "$STAGE_ROOT/stage"

echo "==> Extracting base IPA..."
unzip -q "$BASE_IPA" -d "$STAGE_ROOT/stage"

APP="$(find "$STAGE_ROOT/stage/Payload" \
  -maxdepth 1 \
  -type d \
  -name '*.app' \
  -print \
  -quit)"

[[ -n "$APP" ]] || {
  echo "ERROR: Payload app not found" >&2
  exit 65
}

echo "==> App:"
echo "$APP"

[[ -f "$APP/Info.plist" ]] || {
  echo "ERROR: Info.plist not found" >&2
  exit 65
}

BUNDLE_ID="$(plutil -extract CFBundleIdentifier raw -o - "$APP/Info.plist")"

echo "==> Bundle Identifier:"
echo "$BUNDLE_ID"

if [[ "$BUNDLE_ID" != "com.apple.mobile.MobileHouseArrest" ]]; then
  echo "ERROR: unexpected bundle identifier: $BUNDLE_ID" >&2
  exit 65
fi

if codesign -d "$APP" >/dev/null 2>&1; then
  echo "ERROR: base app appears to be signed"
  echo "Please use an unsigned base IPA"
  exit 65
fi

echo "==> Base IPA is unsigned"

mkdir -p "$APP/Frameworks"

TARGET_DYLIB="$APP/Frameworks/$EMBEDDED_DYLIB"

echo "==> Installing dylib:"
echo "$TARGET_DYLIB"

cp "$DYLIB" "$TARGET_DYLIB"

[[ -f "$TARGET_DYLIB" ]] || {
  echo "ERROR: failed to copy dylib" >&2
  exit 70
}

echo "==> Removing existing dylib signature..."
codesign --remove-signature "$TARGET_DYLIB" 2>/dev/null || true

if [[ -n "$CATALOG" ]]; then
  echo "==> Installing MCMIdentifiers.plist..."
  cp "$CATALOG" "$APP/MCMIdentifiers.plist"
elif [[ -e "$APP/MCMIdentifiers.plist" ]]; then
  echo "==> Removing existing MCMIdentifiers.plist..."
  rm -f "$APP/MCMIdentifiers.plist"
fi

if [[ -e "$OUTPUT_IPA" ]]; then
  rm -f "$OUTPUT_IPA"
fi

mkdir -p "$(dirname "$OUTPUT_IPA")"

echo "==> Creating final unsigned IPA..."

(
  cd "$STAGE_ROOT/stage"
  zip -qry "$OUTPUT_IPA" Payload
)

[[ -f "$OUTPUT_IPA" ]] || {
  echo "ERROR: output IPA was not created" >&2
  exit 70
}

echo "==> Final IPA created:"
ls -lh "$OUTPUT_IPA"

echo "==> SHA256:"
shasum -a 256 "$OUTPUT_IPA"

echo "==> SUCCESS"