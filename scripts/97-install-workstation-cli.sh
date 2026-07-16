#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STATE_ROOT="$HOME/.local/share/doorstation"
LEGACY_STATE="$HOME/.local/share/doorsecure-workstation"
mkdir -p "$STATE_ROOT" "$HOME/.local/bin"
if [[ -d "$LEGACY_STATE" && ! -e "$STATE_ROOT/.legacy-migrated" ]]; then
  cp -an "$LEGACY_STATE/." "$STATE_ROOT/" 2>/dev/null || true
  touch "$STATE_ROOT/.legacy-migrated"
fi
printf '%s\n' "$ROOT_DIR" > "$STATE_ROOT/source-path"
printf '%s\n' "3.2.0" > "$STATE_ROOT/version"
sudo install -m 0755 "$ROOT_DIR/doorstation" /usr/local/bin/doorstation
install -m 0755 "$ROOT_DIR/doorstation" "$HOME/.local/bin/doorstation"
echo "✓ Doorstation CLI installed: /usr/local/bin/doorstation"
