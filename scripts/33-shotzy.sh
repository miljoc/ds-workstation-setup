#!/usr/bin/env bash
set -euo pipefail

SHOTZY_UUID="shotzy@SamkitJain660.github.io"
SHOTZY_REF="${SHOTZY_REF:-main}"
EXT_DIR="$HOME/.local/share/gnome-shell/extensions/$SHOTZY_UUID"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

sudo dnf install -y \
  tesseract \
  tesseract-langpack-eng \
  tesseract-langpack-nld \
  zbar \
  wget \
  tar \
  glib2

rm -rf "$EXT_DIR"
mkdir -p "$EXT_DIR"

wget -qO- "https://github.com/SamkitJain660/Shotzy/archive/refs/heads/${SHOTZY_REF}.tar.gz" \
  | tar -xz --strip-components=1 -C "$EXT_DIR"

if [ -d "$EXT_DIR/schemas" ]; then
  glib-compile-schemas "$EXT_DIR/schemas"
fi

gnome-extensions enable "$SHOTZY_UUID" || true

echo "Shotzy installed: $SHOTZY_UUID"
echo "Log out and back in if it does not appear immediately."
