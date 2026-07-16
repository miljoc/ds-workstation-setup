#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STATE_ROOT="$HOME/.local/share/doorsecure-workstation"
BIN_DIR="$HOME/.local/bin"
mkdir -p "$STATE_ROOT" "$BIN_DIR"

# Keep the path of the Git checkout/installer used for future update runs.
printf '%s\n' "$ROOT_DIR" > "$STATE_ROOT/source-path"
printf '%s\n' "2.0.0" > "$STATE_ROOT/version"

install -m 0755 "$ROOT_DIR/workstation" "$BIN_DIR/workstation"

echo "✓ Workstation CLI installed: $BIN_DIR/workstation"
