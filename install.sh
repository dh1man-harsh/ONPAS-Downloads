#!/usr/bin/env bash
set -euo pipefail

LATEST_URL="https://raw.githubusercontent.com/dh1man-harsh/ONPAS-Downloads/main/latest.json"
APP_PATH="/Applications/ONPAS.app"
CONFIG_PATH="$HOME/Library/Application Support/ONPAS"
TMP_DIR="$(mktemp -d)"
MOUNT_DIR="$TMP_DIR/mount"

cleanup() {
  if mount | grep -q "$MOUNT_DIR"; then
    hdiutil detach "$MOUNT_DIR" -quiet || true
  fi
  rm -rf "$TMP_DIR"
}

json_value() {
  /usr/bin/sed -nE 's/.*"'$1'"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/p' "$2" | head -n 1
}

trap cleanup EXIT

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "ONPAS macOS installer must be run on macOS." >&2
  exit 1
fi

mkdir -p "$CONFIG_PATH"
mkdir -p "$MOUNT_DIR"

LATEST_JSON="$TMP_DIR/latest.json"
curl -fsSL "$LATEST_URL" -o "$LATEST_JSON"

ARCH="$(uname -m)"
if [[ "$ARCH" == "arm64" ]]; then
  DMG_URL="$(json_value mac_arm "$LATEST_JSON")"
else
  DMG_URL="$(json_value mac_intel "$LATEST_JSON")"
fi

VERSION="$(json_value version "$LATEST_JSON")"
DMG_PATH="$TMP_DIR/ONPAS.dmg"

curl -fL "$DMG_URL" -o "$DMG_PATH"
hdiutil attach "$DMG_PATH" -nobrowse -quiet -mountpoint "$MOUNT_DIR"

SOURCE_APP="$(find "$MOUNT_DIR" -maxdepth 2 -name 'ONPAS.app' -type d | head -n 1)"

if [[ -z "$SOURCE_APP" ]]; then
  echo "ONPAS.app was not found in the downloaded DMG." >&2
  exit 1
fi

if [[ -w "/Applications" ]]; then
  rm -rf "$APP_PATH"
  /usr/bin/ditto "$SOURCE_APP" "$APP_PATH"
else
  sudo rm -rf "$APP_PATH"
  sudo /usr/bin/ditto "$SOURCE_APP" "$APP_PATH"
fi

xattr -dr com.apple.quarantine "$APP_PATH" 2>/dev/null || true
open "$APP_PATH"

echo "ONPAS $VERSION installed successfully."
