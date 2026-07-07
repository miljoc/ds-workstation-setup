#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC_DIR="$ROOT_DIR/gnome/media"
DEST_DIR="$HOME/.local/share/doorapi-dev-machien/media"

echo "== Installing GNOME media =="
mkdir -p "$DEST_DIR"

if [ -d "$SRC_DIR" ]; then
  cp -r "$SRC_DIR/"* "$DEST_DIR/" 2>/dev/null || true
  echo "Installed media to: $DEST_DIR"
else
  echo "No GNOME media folder found at: $SRC_DIR"
fi
